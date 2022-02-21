# EyeSound ANOVAs acquisition trials

library(dplyr)
library(rstatix)

# Load data
acquisition <- read.csv("D:/EyeSound/means/06.txt", row.names=NULL, sep="")

# Rename the columns
names <- c("experiment", "condition", "channel", "window", "mean", "subject")
colnames(acquisition) <- names


# Clean the content of the last column
acquisition$subject = substr(acquisition$subject,1,2)

# Rename time windows to component names
acquisition$window[acquisition$window == "+080..+120"] <- "N1"
acquisition$window[acquisition$window == "+180..+240"] <- "P2"
acquisition$window[acquisition$window == "+310..+390"] <- "P3"

# Reshape the data
acquisition[, "agency"] <-
  NA
acquisition[, "LS"] <-
  NA

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
keepers <- c("condition", "channel", "window", "mean", "subject", "agency", "LS")
acquisition <- acquisition[keepers]

# Convert to appropriate data types
acquisition$condition <- as.factor(acquisition$condition)
acquisition$channel <- as.factor(acquisition$channel)
acquisition$window <- as.factor(acquisition$window)
acquisition$subject <- as.factor(acquisition$subject)
acquisition$agency <- as.factor(acquisition$agency)
acquisition$LS <- as.factor(acquisition$LS)
acquisition$congruency <- as.factor(acquisition$congruency)
acquisition$mean <- as.numeric(acquisition$mean)

# Run four ANOVAs for the different components of interest
N1 <- subset(acquisition, channel == "Fz" & window == "N1") 
P2_frontal <- subset(acquisition, channel == "Fz" & window == "P2")
P2_parietal <- subset(acquisition, channel == "Pz" & window == "P2")
P3a <- subset(acquisition, channel == "Fz" & window == "P3")
P3b <- subset(acquisition, channel == "Pz" & window == "P3")

# N1 
df <- N1

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, LS))

# Get results
N1_aov <- get_anova_table(aov, correction = "none")
N1_summary <- summary

# P2 frontal
df <- P2_frontal

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, LS))

# Get results
P2f_aov <- get_anova_table(aov, correction = "none")
P2f_summary <- summary

# P2 parietal
df <- P2_parietal

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, LS))

# Get results
P2p_aov <- get_anova_table(aov, correction = "none")
P2p_summary <- summary

# P3a
df <- P3a

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, LS))

# Get results
P3a_aov <- get_anova_table(aov, correction = "none")
P3a_summary <- summary

# P3b
df <- P3b

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, LS))

# Get results
P3b_aov <- get_anova_table(aov, correction = "none")
P3b_summary <- summary

# Run pairwise post-hoc comparisons: Comparing active and passive trials block 
# by block using Bonferroni-corrected t-acquisitions
pwc <- df %>%
  group_by(agency) %>%
  pairwise_t_acquisition(
    mean ~ congruency, paired = TRUE,
    p.adjust.method = "bonferroni"
  )

