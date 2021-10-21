# EyeSound behavioural analysis
# 21/10/21

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
