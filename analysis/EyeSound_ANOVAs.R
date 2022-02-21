#### EyeSound: EEG data statisics #####
### by Stefanie Sturm, January 2022 ###

library(data.table)
library(dplyr)
library(rstatix)
library(ez)
library(reshape)
library(tidyverse)
library(ggpubr)
library(plyr)
library(datarium)
library(ggplot2)

## EEG rejection statistics ##
# Check how many trials are left for each subject and for each condition. 

rejstats <- read.delim("~/Library/Mobile Documents/com~apple~CloudDocs/Brainlab_2021/EyeSound/RejstatsDECEMBER21.txt")
rejstats_summary <- rejstats %>%
  group_by(StimType) %>%
  get_summary_stats(nTrialsLeft, type = "mean_sd")
rejstats_summary <- data.frame(rejstats_summary)

critical_instances <- subset(rejstats, nTrialsLeft < 50)

rejstats_summary2 <- rejstats %>%
  group_by(Subject) %>%
  get_summary_stats(RejRate, type = "mean_sd")
rejstats_summary2 <- data.frame(rejstats_summary2)


high_rejections <- subset(rejstats_summary2, mean > 10)

# Let's for the moment exclude subject 24 because it has a mean rejection rate of 30. 

data <- subset(rejstats, Subject != 24)

rejstats_summary3 <- data %>%
group_by(StimType) %>%
get_summary_stats(nTrialsLeft, type = "mean_sd")

critical_instances2 <- subset(data, nTrialsLeft < 50)

## ANOVAs for amplitudes in windows of interest ##

setwd("D:/EyeSound/means")

# Get all files from the results folder (make sure only test files are in there)
file_list <- list.files() 

# Merge the test files into one dataframe
for (file in file_list) {
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")) {
    dataset <- read.csv2(file, row.names = NULL, sep = "")
  }
  
  # if the merged dataset does exist, append to it
  else if (exists("dataset")) {
    temp_dataset <- read.csv2(file, row.names = NULL, sep = "")
    dataset <- rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
}

# Rename the columns
names <- c("experiment", "condition", "channel", "window", "mean", "subject")
colnames(dataset) <- names


# Clean the content of the last column
dataset$subject = substr(dataset$subject,1,2)

# Rename time windows to component names
dataset$window[dataset$window == "+080..+120"] <- "N1"
dataset$window[dataset$window == "+180..+240"] <- "P2"
dataset$window[dataset$window == "+310..+390"] <- "P3"
dataset$window[dataset$window == "+104..+144"] <- "N1"
dataset$window[dataset$window == "+210..+270"] <- "P2"
dataset$window[dataset$window == "+330..+410"] <- "P3"

# Acquisition trials ANOVA
acquisition <- subset(dataset, dataset$condition == "AcqActLS1" | dataset$condition == "AcqActLS2"| dataset$condition == "AcqActLS3" | dataset$condition == "AcqPasLS1" | dataset$condition == "AcqPasLS2" | dataset$condition == "AcqPasLS3") 

# Reshape the data
acquisition[, "agency"] <-
  NA # Add a column for evaluation of responses
acquisition[, "LS"] <-
  NA # Add a column for evaluation of responses

for (iRow in 1:length(acquisition$condition)) {
  if (acquisition[iRow, "condition"] == "AcqActLS1") {
    acquisition[iRow, "agency"] <- 1
    acquisition[iRow, "LS"] <- 1
  } else if (acquisition[iRow, "condition"] == "AcqActLS2") {
    acquisition[iRow, "agency"] <- 1
    acquisition[iRow, "LS"] <- 2
  } else if (acquisition[iRow, "condition"] == "AcqActLS3") {
    acquisition[iRow, "agency"] <- 1
    acquisition[iRow, "LS"] <- 3 
  } else if (acquisition[iRow, "condition"] == "AcqPasLS1") {
    acquisition[iRow, "agency"] <- 0
    acquisition[iRow, "LS"] <- 1
  } else if (acquisition[iRow, "condition"] == "AcqPasLS2") {
    acquisition[iRow, "agency"] <- 0
    acquisition[iRow, "LS"] <- 2
  } else if (acquisition[iRow, "condition"] == "AcqPasLS3") {
    acquisition[iRow, "agency"] <- 0
    acquisition[iRow, "LS"] <- 3
  }
}     

# Drop unnecessary columns
keepers <- c("channel", "window", "mean", "subject", "agency", "LS")
acquisition <- acquisition[keepers]

# Convert to appropriate data types
acquisition$channel <- as.factor(acquisition$channel)
acquisition$window <- as.factor(acquisition$window)
acquisition$subject <- as.factor(acquisition$subject)
acquisition$agency <- as.factor(acquisition$agency)
acquisition$LS <- as.factor(acquisition$LS)
acquisition$mean <- as.numeric(acquisition$mean)

# P2 at Cz 

# Subset the data
data <- subset(acquisition, (channel == "Cz" & window == "P2"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

# P3 at Cz 

# Subset the data
data <- subset(acquisition, (channel == "Cz" & window == "P3"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

# P2 at Pz 

# Subset the data
data <- subset(acquisition, (channel == "Pz" & window == "P2"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

# P3 at Pz 

# Subset the data
data <- subset(acquisition, (channel == "Pz" & window == "P3"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

# P2 at Fz 

# Subset the data
data <- subset(acquisition, (channel == "Fz" & window == "P2"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

# P3 at Fz 

# Subset the data
data <- subset(acquisition, (channel == "Fz" & window == "P3"))

# Summary statistics
summary <- data %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
  data = data, dv = mean, wid = subject,
  within = c(agency, LS)
)

get_anova_table(res.aov)

## Test trials ##

# For ANOVAs
test <- subset(dataset, dataset$condition == "TesActConLS1" | dataset$condition == "TesActConLS2"| dataset$condition == "TesActConLS3" | dataset$condition == "TesPasConLS1" | dataset$condition == "TesPasConLS2" | dataset$condition == "TesPasConLS3" | dataset$condition == "TesActIncLS1" | dataset$condition == "TesActIncLS2"| dataset$condition == "TesActIncLS3" | dataset$condition == "TesPasIncLS1" | dataset$condition == "TesPasIncLS2" | dataset$condition == "TesPasIncLS3") 

# Reshape the data
test[, "agency"] <-
  NA
test[, "LS"] <-
  NA
test[, "congruency"] <-
  NA

for (iRow in 1:length(test$condition)) {
  if (test[iRow, "condition"] == "TesActConLS1") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActConLS2") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActConLS3") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 3 
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS1") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS2") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS3") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 3
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActIncLS1") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesActIncLS2") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesActIncLS3") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 3 
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS1") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS2") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS3") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 3
    test[iRow, "congruency"] <- 0
  }
}     

# Drop unnecessary columns
keepers <- c("condition", "channel", "window", "mean", "subject", "agency", "LS", "congruency")
test <- test[keepers]

# Convert to appropriate data types
test$condition <- as.factor(test$condition)
test$channel <- as.factor(test$channel)
test$window <- as.factor(test$window)
test$subject <- as.factor(test$subject)
test$agency <- as.factor(test$agency)
test$LS <- as.factor(test$LS)
test$congruency <- as.factor(test$congruency)
test$mean <- as.numeric(test$mean)

# For interaction plot
interaction <- subset(dataset, dataset$condition == "TesActCon" | dataset$condition == "TesActInc"| dataset$condition == "TesPasCon" | dataset$condition == "TesPasInc")

# Amplitudes P2 for active and passive congruency effects (plot)
P2 <- subset(interaction, window == "P2" & channel == "Fz")
P2$condition <- as.factor(P2$condition)
P2$subject <- as.factor(P2$subject)
P2$mean <- as.numeric(P2$mean)

P2_summary <- summarise(group_by(P2, condition),
                                     group_mean=mean(mean), sd=sd(mean))

P2_summary[, "group"] <- 
  NA

for (iRow in 1:length(P2_summary$condition)) {
  if (P2_summary[iRow, "condition"] == "TesActCon") {
    P2_summary[iRow, "group"] <- 1
  } else if (P2_summary[iRow, "condition"] == "TesActInc") {
    P2_summary[iRow, "group"] <- 1
  } else if (P2_summary[iRow, "condition"] == "TesPasCon") {
    P2_summary[iRow, "group"] <- 2
  } else if (P2_summary[iRow, "condition"] == "TesPasInc") {
    P2_summary[iRow, "group"] <- 2
  }
}

P2_summary$group <- as.factor(P2_summary$group)

P2_summary %>% 
  ggplot(aes(x = condition, y = group_mean, fill = group)) + 
  geom_bar(position = "dodge", stat="identity") +
  theme(legend.position = "bottom")

agency <- c("active", "active", "passive", "passive")
congruency <- c("congruent", "incongruent", "congruent", "incongruent")
mean <- P2_summary$group_mean
sd <- P2_summary$sd

df <- data.frame(agency,congruency,mean,sd)

# Grouped
ggplot(df, aes(fill=congruency, y=mean, x=agency)) + 
  geom_bar(position="dodge", stat="identity") +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9)) + 
  scale_x_discrete(name = "Mode of acquisition") + 
  scale_y_continuous((name = "Mean amplitude in P2 window (in mV)")) +
  scale_fill_discrete(name = "Sound type", labels=c("congruent", "incongruent")) + 
  theme_bw()

#### STUFF FROM OTHER SCRIPT
#

### Statistics for ERPs

# I will run the following statistical analyses: 
# * ANOVA for acquisition sounds testing agency and learning stage, as well as interaction
# * ...

### Data preparation 

# Read the data
means <- read.csv("~/Library/Mobile Documents/com~apple~CloudDocs/Brainlab_2021/EyeSound/means/02.txt", row.names=NULL, sep="")

# Rename the columns
names <- c("experiment", "condition", "channel", "window", "mean", "subject")
colnames(means) <- names

# Clean the content of the last column
means$subject = substr(means$subject,1,nchar(means$subject)-14)

# Rename time windows to component names
means$window[means$window == "+020..+050"] <- "P1"
means$window[means$window == "+090..+110"] <- "N1"
means$window[means$window == "+190..+230"] <- "P2"
means$window[means$window == "+320..+400"] <- "P3"

# Reshape the data
means[, "agency"] <-
  NA # Add a column for evaluation of responses
means[, "LS"] <-
  NA # Add a column for evaluation of responses

for (iRow in 1:length(means$condition)) {
  if (means[iRow, "condition"] == "AcqActLS1") {
    means[iRow, "agency"] <- 1
    means[iRow, "LS"] <- 1
  } else if (means[iRow, "condition"] == "AcqActLS2") {
    means[iRow, "agency"] <- 1
    means[iRow, "LS"] <- 2
  } else if (means[iRow, "condition"] == "AcqActLS3") {
    means[iRow, "agency"] <- 1
    means[iRow, "LS"] <- 3 
  } else if (means[iRow, "condition"] == "AcqPasLS1") {
    means[iRow, "agency"] <- 0
    means[iRow, "LS"] <- 1
  } else if (means[iRow, "condition"] == "AcqPasLS2") {
    means[iRow, "agency"] <- 0
    means[iRow, "LS"] <- 2
  } else if (means[iRow, "condition"] == "AcqPasLS3") {
    means[iRow, "agency"] <- 0
    means[iRow, "LS"] <- 3
  }
}

# Drop unnecessary columns
keepers <- c("channel", "window", "mean", "subject", "agency", "LS")
means <- means[keepers]

# Convert to appropriate data types
means$channel <- as.factor(means$channel)
means$window <- as.factor(means$window)
means$subject <- as.factor(means$subject)
means$agency <- as.factor(means$agency)
means$LS <- as.factor(means$LS)
means$mean <- as.numeric(means$mean)

### ANOVA for agency and LS, P2 at Cz
# data <- means
# x <- subset(data, condition == "AcqAct" & channel == "Cz" & window == "P2")
# y <- subset(data, condition == "AcqPas" & channel == "Cz" & window == "P2")
# 
# t.test(x$mean, y$mean, paired = TRUE, alternative = "two.sided")

# Subset the data
data <- subset(means, (channel == "Cz" & window == "P2"))

# Summary statistics
summary <- data %>%
group_by(subject, agency, LS) %>%
get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
data = data, dv = mean, wid = subject,
within = c(agency, LS)
)

get_anova_table(res.aov)

### ANOVA for agency and LS, P3b at Pz

# Subset the data
data <- subset(means, (channel == "Pz" & window == "P3"))

# Summary statistics
summary <- data %>%
group_by(subject, agency, LS) %>%
get_summary_stats(mean, type = "mean")
data.frame(summary)

# Run ANOVA
res.aov <- anova_test(
data = data, dv = mean, wid = subject,
within = c(agency, LS)
)

get_anova_table(res.aov)

res.aov2 <- aov(mean ~ supp + dose, data = my_data)
summary(res.aov2)





