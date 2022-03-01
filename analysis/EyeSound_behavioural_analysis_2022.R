### EyeSound - Behavioural analysis ###
### by Stefanie Sturm, January 2022 ###

## Prepare the data for analysis ##

# Load relevant packages
library(rstatix)
library(ggplot2)

setwd("~/Uni/EyeSound/logfiles/")

# Load the data from logfiles
file_list <- list.files(path ="~/Uni/EyeSound/logfiles/")  

# Merge the test files into one dataframe
for (file in file_list) {
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")) {
    dataset <- read.csv2(file, header = TRUE, sep = "")
  }
  
  # if the merged dataset does exist, append to it
  else if (exists("dataset")) {
    temp_dataset <- read.csv2(file, header = TRUE, sep = "")
    dataset <- rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
}

# Remove training trials (Contingency == 0)
dataset <- subset(dataset, dataset$Contingency != 0)

# Check if response was correct by comparing answer and congruency columns
dataset[, "Correctness"] <-
  NA # Add a column for evaluation of responses
is.nan.data.frame <- function(x)
  do.call(cbind, lapply(x, is.nan))
dataset[is.nan(dataset)] <- NA
for (i in 1:nrow(dataset)) {
  dataset[i, "Correctness"] <-
    dataset[i, "Congruency"] == dataset[i, "Response"]
}

# Exclude test trials that test sounds that are at this stage unknown
# Make another column that contains a boolean value which is positive when the 
# sound presented in a test trial has been played in the preceeding acquisition 
# trials.

# The following code checks if any given test sound was presented in any of the 
# preceeding acquisition trials

acquisition_trials <- subset(dataset, EventType == 2)
test_trials <- subset(dataset, EventType == 4)
test_trials[, "SoundKnown"] <- NA # Add a column to be filled later

# Drop unnecessary information from data frames
columns_acquisition <- c("Subject", "Contingency", "Block", "SoundID")
acquisition_trials <- acquisition_trials[columns_acquisition]

columns_test <- c("Subject", "Contingency", "Block", "Condition", "SoundID", "Correctness", "SoundKnown")
test_trials <- test_trials[columns_test]

# Make an empty data frame that will later contain the information we want
enriched_test_trials <- data.frame()

for(iSub in 2:26) {
  for(iCon in 1:14) {
    for(iBlock in 1:7) {
      # Get the sounds that were played in preceeding acquisition trials
      sounds_played <- subset(acquisition_trials, Subject == iSub & Contingency == iCon & Block <= iBlock)
      # Get the sounds that were tested
      tests <- subset(test_trials, Subject == iSub & Contingency == iCon & Block == iBlock)
      # Add a "true" or "false" depending on whether the sound was played before
      for(i in 1:nrow(tests)) {
        tests[i, "SoundKnown"] <- tests[i,"SoundID"] %in% sounds_played$SoundID
      }
      # Append all temporary data sets
      enriched_test_trials <- rbind(enriched_test_trials, tests)
    }
  }
}

# Clean up a little 
rm(tests, acquisition_trials, test_trials, dataset, sounds_played)

# Now that this is done, we want to drop the test trials that presented an unknown sound and plot the pruned data for each subject.
test_trials_valid <- subset(enriched_test_trials, SoundKnown == TRUE)

# Keep only columns of interest
remaining <- c("Subject", "Contingency", "Block", "Condition", "SoundID", "Correctness")
test_trials_valid <- test_trials_valid[remaining]

# Write the new data set as a .csv file
write.csv2(test_trials_valid, "results_clean.csv")

## Summarise the data ##

# NADIA

# Uncomment if you want to start here 
# test_trials_valid <- read.csv("D:/EyeSound/EyeSound_results_clean.csv", sep=";")
remaining <- c("Subject", "Contingency", "Block", "Condition", "SoundID", "Correctness")
test_trials_valid <- test_trials_valid[remaining]

# First, check the performance of individual subjects

# Initialize an empty data frame
subjects <- data.frame(matrix(ncol = 2, nrow = 0))
names <- c("Subject", "PercentCorrect")
colnames(subjects) <- names

# Calculate the %Correct for each subject overall
for(iSub in 2:26) { 
  # Subset responses for subject
  data = subset(test_trials_valid, test_trials_valid$Subject == iSub) 
  data <- group_by(data, Subject)
  data <- summarise(data, PercentCorrect = length(which(data$Correctness==TRUE)) / length(data$Correctness))
  subjects <- rbind(subjects, data)
}
rm(data)

# Plot the subjects' performance
ggplot(subjects, aes(x=Subject, y=PercentCorrect)) +
  geom_text(label=as.character(subjects$Subject))+ 
  geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
  theme_bw() +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())

# Plot performance of individual subjects across blocks and save as image files 
# This step is not necessary but it's for knowing which subjects fucked up
# You can skip this!

# Initialize an empty data frame
subjects_by_blocks <- data.frame(matrix(ncol = 3, nrow = 0))
names <- c("Subject", "Block", "PercentCorrect")
colnames(subjects_by_blocks) <- names

# Calculate %Correct per subject and block
for(iSub in 2:26) {
  data = subset(test_trials_valid, test_trials_valid$Subject == iSub)
  for(iBlock in 1:7) { 
    temp <- subset(data, data$Block == iBlock) 
    temp <- group_by(temp, Subject, Block)
    temp <- summarise(temp, PercentCorrect = length(which(temp$Correctness==TRUE)) / length(temp$Correctness))
    subjects_by_blocks <- rbind(subjects_by_blocks, temp)
  }
}

# Now plot this for each subject and save to file
for(iSub in 2:26) { 
  filename <- paste("D:/EyeSound/plots/subjects/", iSub, "_blocks.jpeg", sep = "")
  jpeg(file=filename)
  data = subset(subjects_by_blocks, Subject == iSub) 
  data$Subject <- as.factor(data$Subject)
  data$Block <- as.factor(data$Block)
  data$PercentCorrect <- as.numeric(data$PercentCorrect)
  
  p <- ggplot(data, aes(x = Block, y = PercentCorrect, color = Subject, group = Subject)) + 
    geom_line() +
    geom_point() +
    geom_hline(yintercept=0.5, linetype="dashed", color = "black")
  
  print(p + labs(y="%Correct of pruned test trials")) + 
    scale_x_discrete(name = "Block") + 
    theme_bw()
  dev.off()
}

# Clean up after yourself
rm(p, data, subjects, subjects_by_blocks, temp)

# Plot %Correct per block, divided by acquisition type
# This step is important, this graph should be in the analysis

# Initialize an empty data frame
subject_block_condition <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("Subject", "Block", "Condition", "PercentCorrect")
colnames(subject_block_condition) <- names

# Calculate %Correct per subject and block
for(iSub in 2:26) {
  data = subset(test_trials_valid, test_trials_valid$Subject == iSub)
  for (iCond in 1:2) {
    for(iBlock in 1:7) { 
      temp <- subset(data, (data$Block == iBlock) & (data$Condition == iCond)) 
      temp <- group_by(temp, Subject, Block, Condition)
      temp <- summarise(temp, PercentCorrect = length(which(temp$Correctness==TRUE)) / length(temp$Correctness))
      subject_block_condition <- rbind(subject_block_condition, temp)
    }
  }
}
rm(data, temp)

# Summarise subject means and keep only block and condition; get mean and SD
summary_block_condition <- summarise(group_by(subject_block_condition, Block, Condition),
                                  mean=mean(PercentCorrect), sd=sd(PercentCorrect))

# Convert to factors for plotting
summary_block_condition$Block <- as.factor(summary_block_condition$Block)
summary_block_condition$Condition <- as.factor(summary_block_condition$Condition)

# Plot the summary
ggplot(summary_block_condition, aes(y=mean, x=Block, fill = Condition)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9)) + 
  scale_x_discrete(name = "Block") + 
  scale_y_continuous((name = "%Correct")) +
  scale_fill_discrete(name = "Acquisition mode", labels=c("active", "passive")) + 
  theme_bw()

ggplot(summary_block_condition, aes(x = Block, y = mean, colour = Condition)) + 
  geom_line(aes(group = Condition), size = 0.8) + 
  geom_point() + 
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.05)) +
  scale_x_discrete(name = "Bloque") + 
  scale_y_continuous((name = "Porcentaje de acierto")) +
  scale_colour_discrete(name = "Condici?n", labels=c("activa", "pasiva")) + 
  theme_bw()

## Run the ANOVA ##

# Convert to factors
subject_block_condition$Subject <- as.factor(subject_block_condition$Subject)
subject_block_condition$Block <- as.factor(subject_block_condition$Block)
subject_block_condition$Condition <- as.factor(subject_block_condition$Condition)

# Run repeated-measures ANOVA with dependent variable PercentCorrect, Subject as 
# subject identifier, and two predictor variables within subjects

df <- ungroup(subject_block_condition) # Ungroup so that aov can work

# Run AOV
aov <- anova_test(data = df, dv = PercentCorrect, wid = Subject, within = c(Block, Condition))

# Get results in table
get_anova_table(aov, correction = "none") # without corrections
get_anova_table(aov) # with GG correction

# Use a different ANOVA package just to be sure
library(ez)

rt_anova = ezANOVA(
  data = df
  , dv = .(PercentCorrect)
  , wid = .(Subject)
  , within = .(Block,Condition)
)

rt_anova = ezANOVA(
  data = df
  , dv = .(PercentCorrect)
  , wid = .(Subject)
  , within = .(Block,Condition),
  type = 2,
  detailed = T,
  return_aov = T
)
# Run pairwise post-hoc comparisons: Comparing active and passive trials block 
# by block using Bonferroni-corrected t-tests

pwc <- df %>%
  group_by(Block) %>%
  pairwise_t_test(
    PercentCorrect ~ Condition, paired = TRUE,
    p.adjust.method = "bonferroni"
  )

# Show comparisons
pwc

## Bonus analysis ##

# Analyse the difference between active and passive trials, see if it is inversely 
# correlated with block 

# Initialize an empty data frame
difference <- data.frame(matrix(ncol = 4, nrow = 0))
names <- c("Subject", "Block", "Condition", "PercentCorrect")
colnames(difference) <- names

for(iSub in 2:26) {
  data <- subset(subject_block_condition, subject_block_condition$Subject == iSub)
  temp <- subset(data, data$Condition == 1) # make this as a temporary results data frame
  temp$PercentCorrect <- NA
  temp$Condition <- "1-2"
  active <- subset(data, data$Condition == 1)
  passive <- subset(data, data$Condition == 2)
  temp$PercentCorrect <- (active$PercentCorrect - passive$PercentCorrect)
  difference <- rbind(difference, temp)
}

difference_summary <- summarise(group_by(difference, Block),
                                mean=mean(PercentCorrect), sd=sd(PercentCorrect))

p <- ggplot(difference_summary,aes(x = Block, y = mean, group = 1)) +
  geom_point() +
  geom_smooth(method='lm') +
  scale_y_continuous((name = "%Correct active - passive")) +
  theme_bw() + 
  theme(aspect.ratio = 1)

setwd("D:/EyeSound/plots/")
ggsave(plot = p, width = 3, height = 3, dpi = 300, filename = "difference_regression_plot.jpg")

