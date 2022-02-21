library(tidyverse)
library(magrittr)
library(scanpath)
library(eyelinker)
library(ggplot2)

data(eyemovements)
head(eyemovements)

plot_scanpaths(eyemovements, duration ~ word | trial, subject)

# passive block
dat <- read.asc("D:/EyeSound/ASC files/0501p.asc")
fix_b1 <- subset(dat$fix, block == 1)
sacc_b1 <- subset(dat$sacc, block == 1)

# active block
dat2 <- read.asc("D:/EyeSound/ASC files/0502a.asc")
fix_b1_2 <- subset(dat2$fix, block == 1)

ggplot() +
  geom_point(data = fix_b1,
             aes(x = axp, y = ayp, size = dur, color = eye),
             alpha = 0.5, color = "blue") +
  geom_point(data = fix_b1_2,
             aes(x = axp, y = ayp, size = dur, color = eye),
             alpha = 0.5, color = "red") +
  scale_x_continuous(expand = c(0, 0), limits = c(0, dat$info$screen.x)) +
  scale_y_reverse(expand = c(0, 0), limits = c(dat$info$screen.y, 0)) +
  labs(x = "x-axis (pixels)", y = "y-axis (pixels)") +
  coord_fixed() # Keeps aspect ratio from getting distorted
