# Analysis of behavioural pilot data for EyeSound

library(dplyr)
library(ggplot2)
library(ggpubr)

# Memory performance

setwd("/home/stefanie/GitHub/EyeSound/pilot/test/")

file_list <-
  list.files() # Get all files from the results folder (make sure only test files are in there)

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

dataset[, "Correctness"] <-
  NA # Add a column for evaluation of responses

# Check if response was correct by comparing two columns
for (i in 1:nrow(dataset)) {
  dataset[i, "Correctness"] <-c
    dataset[i, "Congruency"] == dataset[i, "Response"]
}

#+++++++++++++++++++++++++
# Function to calculate the mean and the standard deviation
# for each group
#+++++++++++++++++++++++++
# data : a data frame
# varname : the name of a column containing the variable
#to be summariezed
# groupnames : vector of column names to be used as
# grouping variables

data_summary <- function(data, varname, groupnames) {
  require(plyr)
  summary_func <- function(x, col) {
    c(mean = mean(x[[col]], na.rm = TRUE),
      sd = sd(x[[col]], na.rm = TRUE))
  }
  data_sum <- ddply(data, groupnames, .fun = summary_func,
                    varname)
  data_sum <- rename(data_sum, c("mean" = varname))
  return(data_sum)
}

df2 <- data_summary(dataset,
                    varname = "Correctness",
                    groupnames = c("Subject", "Block"))
df2$Subject <- as.factor(df2$Subject)
df2$Block <- as.factor(df2$Block)

df3 <-
  data_summary(df2, varname = "Correctness", groupnames = "Block")
df3$Block <- as.factor(df3$Block)

# Plot that
p1 <-
  ggplot(df2, aes(y = Correctness, x = Block, group = Subject)) +
  geom_line(aes(color = Subject)) +
  geom_point(aes(color = Subject))

print(p1 + labs(y = "Hit rate"))

p2 <- ggplot(df3, aes(x = Block, y = Correctness)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(
    aes(ymin = Correctness - sd, ymax = Correctness + sd),
    width = .2,
    position = position_dodge(.9)
  )

print(p2 + labs(y = "Hit rate"))

# Group learning stages
df4 <- dataset
df4$Block[df4$Block == 1] <- "LS1"
df4$Block[df4$Block == 2] <- "LS1"
df4$Block[df4$Block == 3] <- "LS2"
df4$Block[df4$Block == 4] <- "LS2"
df4$Block[df4$Block == 5] <- "LS3"
df4$Block[df4$Block == 6] <- "LS3"
df4$Block <- as.factor(df4$Block)
df4 <- df4 %>%
  dplyr::rename(LearningStage = Block)
df5 <-
  data_summary(df4, varname = "Correctness", groupnames = "LearningStage")
df5$LearningStage <- as.factor(df5$LearningStage)

p3 <- ggplot(df5, aes(x = LearningStage, y = Correctness)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(
    aes(ymin = Correctness - sd, ymax = Correctness + sd),
    width = .2,
    position = position_dodge(.9)
  )

print(p3 + labs(y = "Hit rate", x = "Learning stage"))

df6 <-
  data_summary(df4, varname = "Correctness", groupnames = c("Subject", "LearningStage"))
df6$LearningStage <- as.factor(df6$LearningStage)
df6$Subject <- as.factor(df6$Subject)

p4 <-
  ggplot(df6, aes(y = Correctness, x = LearningStage, group = Subject)) +
  geom_line(aes(color = Subject)) +
  geom_point(aes(color = Subject))

print(p4 + labs(y = "Hit rate", x = "Learning stage"))

write.csv(dataset,
          "/home/stefanie/GitHub/EyeSound/results/dataset.csv",
          row.names = FALSE)
write.csv(df2,
          "/home/stefanie/GitHub/EyeSound/results/summary_subjects.csv",
          row.names = FALSE)
write.csv(df3,
          "/home/stefanie/GitHub/EyeSound/results/summary_blocks.csv",
          row.names = FALSE)


# Exploration behaviour

setwd("/home/stefanie/GitHub/EyeSound/pilot/explore/")

file_list <-
  list.files() # Get all files from the results folder (make sure only test files are in there)

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

dataset$Sound <- as.logical(dataset$Sound)
sounds <- dataset %>% dplyr::filter(Sound == TRUE)
sounds <- sounds %>% dplyr::count(Subject, Block, Sound)
mean_sounds <- data_summary(sounds, varname = "n", groupnames = "Subject")

p5 <- ggplot(mean_sounds, aes(x = Subject, y = n)) +
  geom_bar(stat = "identity", position = position_dodge()) +
  geom_errorbar(
    aes(ymin = n - sd, ymax = n + sd),
    width = .2,
    position = position_dodge(.9)
  ) + 
  geom_hline(yintercept = mean(mean_sounds$n), linetype='dotted', col = 'red') 

print(p5 + labs(y = "Average number of sounds/exploration", x = "Subject"))

