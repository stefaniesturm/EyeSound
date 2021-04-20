# Analysis of behavioural pilot data for EyeSound

library(dplyr)
library(ggplot2)
library(ggpubr)

setwd("/home/stefanie/GitHub/EyeSound/results/")

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
  dataset[i, "Correctness"] <-
    dataset[i, "Congruency"] == dataset[i, "Response"]
}

# Summarise and plot progession of correct answers by block (learning curve)
blocks <- dataset %>%
  filter(Correctness %in% c("TRUE", "FALSE")) %>%
  group_by(Block, Correctness) %>%
  summarise(counts = n())
blocks$Block <- as.factor(blocks$Block)

# Plot that
p <- ggplot(blocks, aes(fill = Correctness, y = counts, x = Block)) +
  geom_bar(position = "dodge", stat = "identity")
print(p + labs(y = "Number of responses"))

# Summarise and plot progession of correct answers by subject
subjects <- dataset %>%
  filter(Correctness %in% c("TRUE", "FALSE")) %>%
  group_by(Subject, Correctness) %>%
  summarise(counts = n())

# Plot that
p <- ggplot(subjects, aes(fill = Correctness, y = counts, x = Subject)) +
  geom_bar(position = "dodge", stat = "identity")
print(p + labs(y = "Number of responses"))
