# EyeSound behavioural analysis
# 21/10/21

library(dplyr)

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

subject_block <- group_by(responses, Subject, Block)
subject_block_summary <- summarise(subject_block, mean=mean(Correctness, na.rm=TRUE), sd=sd(Correctness, na.rm=TRUE))
