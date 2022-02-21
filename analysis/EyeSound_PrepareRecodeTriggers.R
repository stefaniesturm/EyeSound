### EyeSound - Prepare logfiles for RecodeTriggers ###
### by Stefanie Sturm, January 2022 ###

# Set working directory
setwd("D:/EyeSound/logfiles/")

# Load the data from logfiles
file_list <- list.files(path ="D:/EyeSound/logfiles/")  

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

reponses <- subset(dataset, EventType == 4)
sub2 <- subset(reponses$Correctness, reponses$Subject == 2)
write.csv(sub2, 'sub2.csv')
