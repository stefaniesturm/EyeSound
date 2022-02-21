# EyeSound behavioural analysis
# 21/10/21

library(dplyr)
library(ggplot2)
library(ggpubr)

setwd("D:/EyeSound/logfiles/")

# Get all files from the results folder (make sure only test files are in there)
file_list <- list.files() 

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

is.nan.data.frame <- function(x)
  do.call(cbind, lapply(x, is.nan))

dataset[is.nan(dataset)] <- NA

# Check if response was correct by comparing two columns
for (i in 1:nrow(dataset)) {
  dataset[i, "Correctness"] <-
    dataset[i, "Congruency"] == dataset[i, "Response"]
}

responses <- subset(dataset, dataset$EventType == 4) 

# %Correct by block

block <- group_by(responses, Block)
block_summary <- summarise(block, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
block_summary$Block <- as.factor(block_summary$Block)

# Plot that shit
p <- ggplot(block_summary, aes(y=mean, x=Block)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9))
  
print(p + labs(y="Hit rate", x = "Learning stage")) 

# %Correct by block and subject

subject_block <- group_by(responses, Subject, Block)
subject_block_summary <- summarise(subject_block, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
subject_block_summary$Block <- as.factor(subject_block_summary$Block)
subject_block_summary$Subject <- as.factor(subject_block_summary$Subject)

p2 <- ggplot(data=subject_block_summary, mapping = aes(x = Block, y = mean)) + 
  geom_point(aes(color = Subject)) +
  theme_bw()

print(p2 + labs(y="Hit rate", x = "Learning stage"))

# %Correct by condition

condition <- group_by(responses, Condition)
condition_summary <- summarise(condition, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
condition_summary$Condition <- as.factor(condition_summary$Condition)

p3 <- ggplot(condition_summary, aes(y=mean, x=Condition)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9))

print(p3 + labs(y="Hit rate")) + scale_x_discrete(name = "Acquisition type", labels=c("active", "passive")) + theme_bw()

# %Correct by condition and learning stage

block_condition <- group_by(responses, Block, Condition)
block_condition_summary <- summarise(block_condition, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
block_condition_summary$Condition <- as.factor(block_condition_summary$Condition)
block_condition_summary$Block <- as.factor(block_condition_summary$Block)

p <- ggplot(block_condition_summary, aes(x = Block, y = mean, color = Condition)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0.5, linetype="dashed", color = "black") +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9))

p4 <- ggplot(block_condition_summary, aes(x=Block, y=mean, group=Condition)) +
  geom_line(aes(color=Condition))+
  geom_point(aes(color=Condition)) +
  geom_hline(yintercept=0.5, linetype="dashed", color = "red") +
  geom_errorbar(aes(color = Condition, ymin=mean-sd, ymax=mean+sd), width=.2)

print(p4 + labs(y="Hit rate")) + 
  scale_x_discrete(name = "Learning stage") + 
  scale_color_discrete(name = "Acquisition type", labels=c("active", "passive")) + 
  theme_bw()

# Or the same without error bars

p5 <- ggplot(block_condition_summary, aes(x=Block, y=mean, group=Condition)) +
  geom_line(aes(color=Condition))+
  geom_point(aes(color=Condition)) +
  geom_hline(yintercept=0.5, linetype="dashed", color = "red")

print(p5 + labs(y="Hit rate")) + 
  scale_x_discrete(name = "Learning stage") + 
  scale_color_discrete(name = "Acquisition type", labels=c("active", "passive")) + 
  theme_bw()

# Learner progress per subject

# Substract the mean of the first block from the subsequent blocks' means subject-wise

sub_block_norm <- data.frame() # Initialise empty data frame

for(i in 2:26) { 
  varname <- paste("sub", i, sep = "")
  temp <- subset(subject_block_summary, subject_block_summary$Subject == i)
  temp$mean <- temp$mean - temp$mean[1]
  sub_block_norm <- rbind(sub_block_norm, temp)
}

normalize <- function(x, na.rm = TRUE) {
  return((x- min(x)) /(max(x)-min(x)))
}

sub_block_normalized <- data.frame() # Initialise empty data frame

for(i in 2:26) { 
  temp <- subset(subject_block_summary, subject_block_summary$Subject == i)
  temp$mean <- normalize(temp$mean)
  sub_block_normalized <- rbind(sub_block_normalized, temp)
}

# Plot subjects learning progress

sub_block_norm <- group_by(Subject, Block)
sub_block_norm$Subject <- as.factor(sub_block_norm$Subject)
sub_block_norm$Block <- as.factor(sub_block_norm$Block)

altogether <- ggplot(sub_block_norm, aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(altogether + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub02 <- ggplot(sub_block_norm[sub_block_norm$Subject == 2,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub02 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub2_6 <- ggplot(sub_block_norm[sub_block_norm$Subject == 2 | sub_block_norm$Subject == 3 | sub_block_norm$Subject == 4 | sub_block_norm$Subject == 5 | sub_block_norm$Subject == 6,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub2_6 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub7_11 <- ggplot(sub_block_norm[sub_block_norm$Subject == 7 | sub_block_norm$Subject == 8 | sub_block_norm$Subject == 9 | sub_block_norm$Subject == 10 | sub_block_norm$Subject == 11,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub7_11 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub12_16 <- ggplot(sub_block_norm[sub_block_norm$Subject == 12 | sub_block_norm$Subject == 13 | sub_block_norm$Subject == 14 | sub_block_norm$Subject == 15 | sub_block_norm$Subject == 16,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub12_16 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub17_21 <- ggplot(sub_block_norm[sub_block_norm$Subject == 17 | sub_block_norm$Subject == 18 | sub_block_norm$Subject == 19 | sub_block_norm$Subject == 20 | sub_block_norm$Subject == 21,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub17_21 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

sub22_26 <- ggplot(sub_block_norm[sub_block_norm$Subject == 22 | sub_block_norm$Subject == 23 | sub_block_norm$Subject == 24 | sub_block_norm$Subject == 25 | sub_block_norm$Subject == 26,], aes(x = Block, y = mean, color = Subject, group = Subject)) + 
  geom_line() +
  geom_point() + 
  geom_hline(yintercept=0, linetype="dashed", color = "red")

print(sub22_26 + labs(y="Hit rate relative to starting value")) + 
  scale_x_discrete(name = "Learning stage (block)") + 
  theme_bw()

# Plot normalized data (x- min(x)) / (max(x)-min(x)) (subject-wise)

setwd("~/Documents/EyeSound/analysis/plots/individual_subs/")

sub_block_normalized$Subject <- as.factor(sub_block_normalized$Subject)
sub_block_normalized$Block <- as.factor(sub_block_normalized$Block)

for(i in 2:26) { 
  
  filename <- paste("sub", i, ".jpeg", sep = "")
  jpeg(file=filename)
  data = subset(sub_block_normalized, sub_block_normalized$Subject == i) 
  
  plot_normalized <- ggplot(data, aes(x = Block, y = mean, color = Subject, group = Subject)) + 
    geom_line() +
    geom_point() + 
    geom_hline(yintercept=0.5, linetype="dashed", color = "red")
  
  print(plot_normalized + labs(y="Hit rate (normalized with min and max)")) + 
    scale_x_discrete(name = "Learning stage (block)") + 
    theme_bw()
  dev.off()
}

# Check how often the subjects listened to the different sounds

acquisition_sounds <- subset(dataset, dataset$EventType == 2)

sound_freqs <- data.frame() # Initialise empty data frame

for(i in 2:26) { 
  temp <- subset(acquisition_sounds, acquisition_sounds$Subject == i)
  temp2 <- temp %>% group_by(Subject, SoundID) %>% summarize(count=n())
  sound_freqs <-  rbind(sound_freqs, temp2)
}

# Correctness by SoundID

responses_by_soundID <- group_by(responses, Subject, SoundID)
responses_by_soundID_summary <- summarise(responses_by_soundID, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
responses_by_soundID_summary$Subject <- as.factor(responses_by_soundID_summary$Subject)
responses_by_soundID_summary$SoundID <- as.factor(responses_by_soundID_summary$SoundID)

soundIDs_freqs <- merge(responses_by_soundID_summary, sound_freqs)

soundIDs_freqs_sub3 <- subset(soundIDs_freqs, soundIDs_freqs$Subject == 3)

soundIDs_freqs_sub3_plot <- ggplot(data=soundIDs_freqs_sub3, mapping = aes(x = count, y = mean)) + 
  geom_point(aes(color = SoundID)) 

print(total_plot + labs(y="Hit rate")) + 
  scale_x_continuous(name = "Sound frequency") + 
  theme_bw()

for(i in 2:26) { 
  
  filename <- paste("sub", i, "sound_freqs.jpeg", sep = "")
  jpeg(file=filename)
  data = subset(soundIDs_freqs, soundIDs_freqs$Subject == i) 
  
  plot <- ggplot(data=data, mapping = aes(x = count, y = mean)) + 
    geom_point(aes(color = SoundID)) 

  print(plot + labs(y="Hit rate")) + 
    scale_x_discrete(name = "Sound frequency") + 
    theme_bw()
  dev.off()
}


# Correlation between sound frequency and memory performance per subject

correlations <- data.frame(matrix(ncol = 9, nrow = 26))
names <- c("statistic", "parameter", "p.value", "estimate", "null.value", "alternative", "method", "data.name", "conf.int")
colnames(correlations) <- names

for(i in 2:26) { 
  data <- subset(soundIDs_freqs, soundIDs_freqs$Subject == i) 
  mean <- data$mean
  count <- data$count
  pearson_cor <- cor.test(mean, count, method= "pearson")
  correlations$statistic[i] <- pearson_cor[["statistic"]][["t"]]
  correlations$parameter[i] <- pearson_cor[["parameter"]][["df"]]
  correlations$p.value[i] <- pearson_cor[["p.value"]]
  correlations$estimate[i] <- pearson_cor[["estimate"]][["cor"]]
  correlations$null.value[i] <- pearson_cor[["null.value"]][["correlation"]]
  correlations$alternative[i] <- pearson_cor[["alternative"]]
  correlations$method[i] <- pearson_cor[["method"]]
  correlations$data.name[i] <- pearson_cor[["data.name"]]
  correlations$conf.int[i] <- pearson_cor[["conf.int"]]
}

# Check for %Correct only in LS3 (blocks 5, 6 and 7)
advanced_responses <- subset(responses, responses$Block == 5 | responses$Block == 6 | responses$Block == 7)

advanced_responses_by_soundID <- group_by(advanced_responses, Subject, SoundID)
advanced_responses_by_soundID_summary <- summarise(advanced_responses_by_soundID, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
advanced_responses_by_soundID_summary$Subject <- as.factor(advanced_responses_by_soundID_summary$Subject)
advanced_responses_by_soundID_summary$SoundID <- as.factor(advanced_responses_by_soundID_summary$SoundID)

advanced_soundIDs_freqs <- merge(advanced_responses_by_soundID_summary, sound_freqs)

advanced_correlations <- data.frame(matrix(ncol = 9, nrow = 26))
names <- c("statistic", "parameter", "p.value", "estimate", "null.value", "alternative", "method", "data.name", "conf.int")
colnames(advanced_correlations) <- names

for(i in 2:26) { 
  advanced_sub <- subset(advanced_soundIDs_freqs, advanced_soundIDs_freqs$Subject == i) 
  mean <- advanced_sub$mean
  count <- advanced_sub$count
  pearson_cor <- cor.test(mean, count, method= "pearson")
  advanced_correlations$statistic[i] <- pearson_cor[["statistic"]][["t"]]
  advanced_correlations$parameter[i] <- pearson_cor[["parameter"]][["df"]]
  advanced_correlations$p.value[i] <- pearson_cor[["p.value"]]
  advanced_correlations$estimate[i] <- pearson_cor[["estimate"]][["cor"]]
  advanced_correlations$null.value[i] <- pearson_cor[["null.value"]][["correlation"]]
  advanced_correlations$alternative[i] <- pearson_cor[["alternative"]]
  advanced_correlations$method[i] <- pearson_cor[["method"]]
  advanced_correlations$data.name[i] <- pearson_cor[["data.name"]]
  advanced_correlations$conf.int[i] <- pearson_cor[["conf.int"]]
}


advanced_sub <- subset(advanced_soundIDs_freqs, advanced_soundIDs_freqs$Subject == i) 
mean <- advanced_sub$mean
count <- advanced_sub$count
ggscatter(advanced_sub, x = "count", y = "mean", 
          add = "reg.line", conf.int = TRUE, 
          cor.coef = TRUE, cor.method = "pearson",
          xlab = "Mean %Correct", ylab = "Sound frequencies")
