data <- PercentCorrect

stress.aov <- with(data.mean,
                   aov(stress ~ music * image +
                         Error(PID / (music * image)))
)