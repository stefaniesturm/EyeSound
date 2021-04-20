library(dplyr)

# Load the edited events file
events <- read.csv("/home/stefanie/GitHub/EyeSound/analysis/events_file.csv", sep=",") 

# Acquisition sounds are EventType 2

acquisition_sounds <- events %>% filter(Level == 1, EventType == 2)

acquisition_sounds$Block <- as.factor(acquisition_sounds$Block)

acquisition_sounds_count <- acquisition_sounds %>% group_by(Level, Block) %>% tally()
mean(acquisition_sounds_count$n) # Average number of acquisition sounds per block in level 1 (active)
sd(acquisition_sounds_count$n)

# Mean number of acquisition sounds per block was 35.5, SD = 5.9