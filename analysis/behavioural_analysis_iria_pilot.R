# Analysis of Iria's behavioural "pilot"

library(dplyr)
library(ggplot2)
library(ggpubr)
library(plyr)

# Load the data from Iria's pilot
events_file <- read.csv("/media/stefanie/DISCOVERY/Iria/16events.txt", sep="") 

events_file[, "Correctness"] <- NA # Add a column for evaluation of responses

# Check if response was correct by comparing two columns
for (i in 1:nrow(events_file)) {
  events_file[i, "Correctness"] <-
    events_file[i, "Congruency"] == events_file[i, "Response"]
}

# Save dataframe as csv
write.csv(events_file, "/home/stefanie/GitHub/EyeSound/analysis/events_file.csv")

# Load the edited events file
events_file <- read.csv("/home/stefanie/GitHub/EyeSound/analysis/events_file.csv", sep=",") 

# Make condition a factor
events_file$Condition <- as.factor(events_file$Condition)

# Subset for event type 4, which is participant response
responses <- events_file[which(events_file$EventType == 4),]

mean(responses$Correctness, na.rm = TRUE) # Mean responses overall

# Group by condition and summarise responses
ddply(responses, .(Condition), summarize,  mean=mean(Correctness, na.rm = TRUE))
