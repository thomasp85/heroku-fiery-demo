install.packages('fiery')
install.packages('routr')

set.seed(1492)
x <- rnorm(15)
y <- x + rnorm(15)
fit <- lm(y ~ x)
saveRDS(fit, "model.rds")
