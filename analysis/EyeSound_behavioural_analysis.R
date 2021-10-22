# EyeSound behavioural analysis
# 21/10/21

library(dplyr)
library(ggplot2)

setwd("~/Documents/Logfiles/events/")

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

