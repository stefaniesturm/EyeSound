# EyeSound ANOVAs test trials

library(dplyr)
library(rstatix)

# Load data
test <- read.csv("~/Uni/EyeSound/analysis/means/test_recoded.txt", row.names=NULL, sep="")

# Rename the columns
names <- c("experiment", "condition", "channel", "window", "mean", "subject")
colnames(test) <- names


# Clean the content of the last column
test$subject = substr(test$subject,1,2)

# Rename time windows to component names
test$window[test$window == "+110..+140"] <- "N1"
test$window[test$window == "+210..+270"] <- "P2"
test$window[test$window == "+340..+400"] <- "P3"
test$window[test$window == "+230..+400"] <- "P2/3"

# Reshape the data
test[, "agency"] <-
  NA
test[, "LS"] <-
  NA
test[, "congruency"] <-
  NA

for (iRow in 1:length(test$condition)) {
  if (test[iRow, "condition"] == "TesActConLS1x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActConLS2x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActConLS3x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 3 
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS1x") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS2x") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesPasConLS3x") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 3
    test[iRow, "congruency"] <- 1
  } else if (test[iRow, "condition"] == "TesActIncLS1x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesActIncLS2x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesActIncLS3x") {
    test[iRow, "agency"] <- 1
    test[iRow, "LS"] <- 3 
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS1x") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 1
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS2x") {
    test[iRow, "agency"] <- 0
    test[iRow, "LS"] <- 2
    test[iRow, "congruency"] <- 0
  } else if (test[iRow, "condition"] == "TesPasIncLS3x") {
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

# Run four ANOVAs for the different components of interest
N1 <- subset(test, channel == "Pz" & window == "N1") # N1 in parietal region!
P2 <- subset(test, channel == "Fz" & window == "P2")
P3a <- subset(test, channel == "Fz" & window == "P3")
late_pos <- subset(test, channel == "Pz" & window == "P2/3")

# N1 
df <- N1

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, congruency, LS))

# Get results
N1_aov <- get_anova_table(aov, correction = "none")
N1_summary <- summary

# P2 
df <- P2

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, congruency, LS))

# Get results
P2_aov <- get_anova_table(aov, correction = "none")
P2_summary <- summary

# Extra t-test because it looks like there is something
PasCon <- subset(P2, agency == 0 & congruency == 1)
PasInc <- subset(P2, agency == 0 & congruency == 0)

PasCon <- PasCon %>%
  group_by(subject) %>%
  get_summary_stats(mean, type = "mean")

PasInc <- PasInc %>%
  group_by(subject) %>%
  get_summary_stats(mean, type = "mean")

t.test(PasCon$mean, PasInc$mean, paired = TRUE)

# There is officially nothing in the P2!

# P3a
df <- P3a

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, congruency, LS))

# Get results
P3a_aov <- get_anova_table(aov, correction = "none")
P3a_summary <- summary

# Late positive component, parietal
df <- late_pos

# Summary statistics
summary <- df %>%
  group_by(subject, agency, LS) %>%
  get_summary_stats(mean, type = "mean")

# Run ANOVA
df <- ungroup(df) # Ungroup so that aov can work# Run AOV
aov <- anova_test(data = df, dv = mean, wid = subject, within = c(agency, congruency, LS))

# Get results
late_pos_aov <- get_anova_table(aov, correction = "none")
late_pos_summary <- summary

# Run pairwise post-hoc comparisons: Comparing active and passive trials block 
# by block using Bonferroni-corrected t-tests
pwc <- df %>%
  group_by(agency) %>%
  pairwise_t_test(
    mean ~ congruency, paired = TRUE,
    p.adjust.method = "bonferroni"
  )

