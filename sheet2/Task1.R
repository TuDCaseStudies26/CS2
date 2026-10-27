library(rpart)
library(rpart.plot)
library(Metrics)
library(gt)

handball_wide <- read.csv("CS2/handball_wide.csv")
EuroTraining  <- read.csv("CS2/EuroTraining.csv")
tennis        <- read.csv("CS2/SlamsData.csv")

tennis$win <- factor(tennis$win)   
levels(tennis$win)                

str(handball_wide); str(EuroTraining); str(tennis)   

# fit a tree
tree_hb <- rpart(scorediff ~ bet.probs.diff + season,
                 data = handball_wide, method = "anova")
# method = "anova":regression tree

tree_eu <- rpart(Goals ~ GroupStage + GDP + MarketValue + FifaRank + UefaPoints + CLPlayers,
                 data = EuroTraining, method = "anova")

tree_tn <- rpart(win ~ rank + points + elo + age.30,
                 data = tennis, method = "class",
                 control = rpart.control(cp = 0.01))
# method = "class":classification tree


# visualize the tree
tu_green <- "#639A00"
light_green <- "#E5F0D5"
dark_green <- "#3F6500"
dark_gray <- "#333333"

# Common plotting style
plot_tree <- function(model, title, extra = 101) {
  rpart.plot(
    model,
    type = 2,               
    extra = extra,         
    fallen.leaves = TRUE,    
    box.palette = c(light_green, tu_green),
    branch.col = dark_green,
    branch.lwd = 1.5,
    shadow.col = "gray85",
    roundint = FALSE,
    nn = FALSE,            
    tweak = 1.15,          
    cex = 0.85,
    main = title,
    under = FALSE
  )
}

# Handball
plot_tree(tree_hb, "Handball | Score Difference")

# Euro
plot_tree(tree_eu, "Euro | Goals")

# Tennis
plot_tree(tree_tn, "Tennis | Win Prediction", extra = 104)



# predict 
pred_hb <- predict(tree_hb, newdata = handball_wide)   
pred_eu <- predict(tree_eu, newdata = EuroTraining)

prob_tn  <- predict(tree_tn, newdata = tennis, type = "prob")[, "1"]
class_tn <- predict(tree_tn, newdata = tennis, type = "class")  


# MAE RMSE and baseline
res <- data.frame(
  Data = c("Handball", "Euro"),
  MAE  = c(mae(handball_wide$scorediff, pred_hb), mae(EuroTraining$Goals, pred_eu)),
  RMSE = c(rmse(handball_wide$scorediff, pred_hb), rmse(EuroTraining$Goals, pred_eu)),
  MAE_base  = c(mae(handball_wide$scorediff, mean(handball_wide$scorediff)),
                mae(EuroTraining$Goals, mean(EuroTraining$Goals))),
  RMSE_base = c(rmse(handball_wide$scorediff, mean(handball_wide$scorediff)),
                rmse(EuroTraining$Goals, mean(EuroTraining$Goals)))
)
res 

# tennis ratio of correctly predicted
acc_tn <- mean(class_tn == tennis$win)
acc_base_tn <- max(prop.table(table(tennis$win)))  
c(accuracy = acc_tn, baseline = acc_base_tn)


# predict error with the largest overestimation and underestimation
extremes <- function(data, y, pred, n = 5) {
  resid <- pred - y                     
  d <- cbind(data, pred = pred, resid = resid)
  list(over  = d[order(resid, decreasing = TRUE)[1:n], ],
       under = d[order(resid)[1:n], ])
}

ex_hb <- extremes(handball_wide, handball_wide$scorediff, pred_hb)
ex_eu <- extremes(EuroTraining, EuroTraining$Goals, pred_eu)
ex_hb$over; ex_hb$under     
ex_eu$over; ex_eu$under


tn <- cbind(tennis, tree_prob = prob_tn)
# Highest predicted winning probabilities
head(tn[order(tn$tree_prob, decreasing = TRUE), ], 5)
# Lowest predicted winning probabilities
head(tn[order(tn$tree_prob), ], 5)


# predict VS. true
# Presentation style
par(
  mfrow = c(1, 3),
  mar = c(4.5, 4.5, 3, 1),
  oma = c(0, 0, 0, 0),
  bg = "white",
  col.axis = dark_gray,
  col.lab = dark_gray,
  col.main = dark_gray,
  cex.lab = 1.1,
  cex.main = 1.2,
  font.main = 2,
  bty = "l"
)

# 1. Handball
plot(
  handball_wide$scorediff, pred_hb,
  xlab = "Actual Score Difference",
  ylab = "Predicted Score Difference",
  main = "Handball",
  pch = 16,
  cex = 0.8,
  col = adjustcolor(tu_green, alpha.f = 0.35)
)

abline(0, 1, col = dark_gray, lty = 2, lwd = 2)

# 2. Euro
plot(
  jitter(EuroTraining$Goals), pred_eu,
  xlab = "Actual Goals",
  ylab = "Predicted Goals",
  main = "Euro",
  pch = 16,
  cex = 0.8,
  col = adjustcolor(tu_green, alpha.f = 0.35)
)

abline(0, 1, col = dark_gray, lty = 2, lwd = 2)



# 3. Tennis
boxplot(
  prob_tn ~ tennis$win,
  names = c("Lost", "Won"),
  xlab = "Actual Match Outcome",
  ylab = "Predicted Win Probability",
  main = "Tennis",
  col = c(light_green, tu_green),
  border = dark_green,
  medcol = dark_gray,
  medlwd = 2,
  outcol = dark_green,
  outpch = 16,
  outline = TRUE
)

# Reset layout
par(mfrow = c(1, 1))




# 1.7 tennis 
# (a) 
table(round(prob_tn, 4))
length(unique(round(prob_tn, 4)))    
sum(tree_tn$frame$var == "<leaf>")    

#(b)
cor(tennis[, c("rank", "points", "elo", "age.30")])
# Correlation with Elo
cor_tab <- data.frame(
  Pair = c("Points vs. Elo", "Rank vs. Elo"),
  Correlation = c(
    cor(tennis$points, tennis$elo, use = "complete.obs"),
    cor(tennis$rank, tennis$elo, use = "complete.obs")
  )
)

# Create formatted table
cor_table <- cor_tab |>
  gt() |>
  tab_header(
    title = "Correlation with Elo"
  ) |>
  fmt_number(
    columns = Correlation,
    decimals = 2
  ) |>
  cols_label(
    Pair = "Variable Pair",
    Correlation = "Correlation"
  ) |>
  cols_align(
    align = "center",
    columns = Correlation
  ) |>
  cols_width(
    Pair ~ px(230),
    Correlation ~ px(150)
  ) |>
  tab_style(
    style = cell_fill(color = "#EAF3EF"),
    locations = cells_column_labels()
  ) |>
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(columns = Correlation)
  ) |>
  tab_style(
    style = cell_text(
      color = "#006B4F",
      weight = "bold"
    ),
    locations = cells_title(groups = "title")
  ) |>
  tab_options(
    table.width = px(380),
    table.font.size = px(14),
    data_row.padding = px(12),
    column_labels.padding = px(10),
    heading.title.font.size = px(18),
    heading.title.font.weight = "bold",
    table.border.top.color = "#006B4F",
    table.border.bottom.color = "#006B4F",
    column_labels.border.bottom.color = "#D9E2DD",
    table_body.hlines.color = "#E8E8E8"
  )
cor_table


tree_noelo <- rpart(win ~ rank + points + age.30, data = tennis, method = "class")
mean(predict(tree_noelo, type = "class") == tennis$win)
tree_noelo$frame$var[1] 



# Tennis: Training Accuracy Comparison
acc <- c(
  "Without Elo" = 0.727,
  "With Elo\ncp = 0.01\n(2 leaves)" = 0.7505,
  "With Elo\ncp = 0.001\n(22 leaves)" = 0.7653
)

# Plot settings
par(
  mar = c(7, 7, 3, 2),
  family = "sans",
  las = 1,
  bty = "n"
)

# Bar chart
bp <- barplot(
  unname(acc),
  ylim = c(0, 0.9),
  width = 0.65,
  space = 0.7,
  col = c(light_green, tu_green, dark_green),
  border = NA,
  axes = FALSE,
  names.arg = rep("", 3),
  ylab = "",
  main = ""
)

# X-axis labels
mtext(
  c("Without Elo", "With Elo", "With Elo"),
  side = 1, at = bp, line = 1,
  cex = 0.9
)

# CP values
mtext(
  c("cp = 0.01", "cp = 0.001"),
  side = 1, at = bp[2:3], line = 2.2,
  cex = 0.85
)

# Number of leaves
mtext(
  c("(2 leaves)", "(22 leaves)"),
  side = 1, at = bp[2:3], line = 3.4,
  cex = 0.85
)

# Y-axis
axis(
  2,
  at = seq(0, 0.9, 0.1),
  labels = paste0(seq(0, 90, 10), "%"),
  las = 1,
  col.axis = dark_gray,
  col = NA,
  tick = FALSE
)

# Subtle horizontal grid lines
abline(
  h = seq(0, 0.9, 0.1),
  col = "#E8E8E8",
  lty = 1,
  lwd = 0.8
)

# Baseline
abline(
  h = 0.5,
  col = dark_gray,
  lty = 2,
  lwd = 1.5
)

# Accuracy labels
text(
  x = bp,
  y = acc + 0.035,
  labels = sprintf("%.2f%%", acc * 100),
  cex = 1,
  font = 2,
  col = dark_gray
)

# Baseline label
text(
  x = max(bp) + 0.45,
  y = 0.52,
  labels = "Baseline: 50%",
  cex = 0.75,
  col = dark_gray,
  adj = 1
)

# Title
title(
  main = "Tennis: Decision Tree Accuracy",
  cex.main = 1.15,
  font.main = 2,
  col.main = "#333333"
)

mtext(
  "Training Accuracy",
  side = 2,
  line = 4.5,
  cex = 0.9,
  col = dark_gray,
  las = 0
)

#The original decision tree stops after just one split, using Elo as the splitting variable.

#We found that Elo is correlated with both points and rank, 
#suggesting that these predictors contain overlapping information.

#When we remove Elo, the tree splits on points instead, achieving a training accuracy of 72.70%, 
#compared with 75.05% when Elo is included.

#This suggests that Elo captures useful information about player strength, 
#while the remaining predictors do not provide sufficient additional improvement to justify further splits 
#under the default complexity parameter.

# (c) 
printcp(tree_tn)                      




# (d) Refit the tree with cp = 0.001
tree_tn2 <- rpart(
  win ~ rank + points + elo + age.30,
  data = tennis,
  method = "class",
  control = rpart.control(cp = 0.001)
)

# Visualize the new decision tree
rpart.plot(
  tree_tn2,
  type = 2,
  extra = 104,
  fallen.leaves = TRUE,
  box.palette = c(light_green, tu_green),
  branch.col = dark_green,
  branch.lwd = 1.5,
  shadow.col = 0,
  tweak = 0.9,
  main = "Tennis | cp = 0.001"
)

# Predictions
prob_tn2 <- predict(
  tree_tn2, newdata = tennis, type = "prob"
)[, "1"]

class_tn2 <- predict(
  tree_tn2, newdata = tennis, type = "class"
)

# Compare model complexity
c(
  leaves_old = sum(tree_tn$frame$var == "<leaf>"),
  leaves_new = sum(tree_tn2$frame$var == "<leaf>")
)

# Compare accuracy
c(
  acc_old = mean(class_tn == tennis$win),
  acc_new = mean(class_tn2 == tennis$win)
)

# Compare number of unique predicted probabilities
c(
  n_probs_old = length(unique(round(prob_tn, 4))),
  n_probs_new = length(unique(round(prob_tn2, 4)))
)

# Compare predicted probabilities
par(
  mfrow = c(1, 2),
  mar = c(4.5, 4.5, 3, 1),
  bg = "white",
  col.axis = dark_gray,
  col.lab = dark_gray,
  col.main = dark_gray,
  cex.lab = 1.1,
  cex.main = 1.2,
  font.main = 2,
  bty = "l"
)

# Original tree
boxplot(
  prob_tn ~ tennis$win,
  names = c("Lost", "Won"),
  xlab = "Actual Match Outcome",
  ylab = "Predicted Win Probability",
  main = "Tennis | cp = 0.01",
  col = c(light_green, tu_green),
  border = dark_green,
  medcol = dark_gray,
  medlwd = 2,
  outcol = dark_green,
  outpch = 16,
  ylim = c(0, 1)
)

# New tree
boxplot(
  prob_tn2 ~ tennis$win,
  names = c("Lost", "Won"),
  xlab = "Actual Match Outcome",
  ylab = "Predicted Win Probability",
  main = "Tennis | cp = 0.001",
  col = c(light_green, tu_green),
  border = dark_green,
  medcol = dark_gray,
  medlwd = 2,
  outcol = dark_green,
  outpch = 16,
  ylim = c(0, 1)
)

par(mfrow = c(1, 1))




# Compare the two trees (calculated directly from the fitted models)
tree_summary <- function(model, probability, predicted_class, truth) {
  node_number <- as.integer(row.names(model$frame))

  c(
    total_nodes = nrow(model$frame),
    internal_nodes = sum(model$frame$var != "<leaf>"),
    terminal_nodes = sum(model$frame$var == "<leaf>"),
    maximum_depth = max(floor(log2(node_number))),
    distinct_probabilities = length(unique(round(probability, 4))),
    training_accuracy = mean(predicted_class == truth)
  )
}

summary_cp_001 <- tree_summary(
  tree_tn, prob_tn, class_tn, tennis$win
)

summary_cp_0001 <- tree_summary(
  tree_tn2, prob_tn2, class_tn2, tennis$win
)


# Select four key metrics
selected_metrics <- c(
  "Terminal nodes (leaves)",
  "Maximum depth",
  "Distinct predicted probabilities",
  "Training accuracy"
)

tree_comparison <- data.frame(
  Metric = selected_metrics,
  `cp = 0.01` = unname(summary_cp_001[3:6]),
  `cp = 0.001` = unname(summary_cp_0001[3:6]),
  check.names = FALSE
)

# Create formatted table
tree_table <- tree_comparison |>
  gt() |>
  fmt_number(
    columns = c(`cp = 0.01`, `cp = 0.001`),
    rows = Metric != "Training accuracy",
    decimals = 0
  ) |>
  fmt_percent(
    columns = c(`cp = 0.01`, `cp = 0.001`),
    rows = Metric == "Training accuracy",
    decimals = 2
  ) |>
  cols_label(
    Metric = "Model complexity / performance"
  ) |>
  cols_align(
    align = "center",
    columns = c(`cp = 0.01`, `cp = 0.001`)
  ) |>
  cols_width(
    Metric ~ px(280),
    everything() ~ px(130)
  ) |>
  tab_style(
    style = cell_fill(color = "#EAF3EF"),
    locations = cells_column_labels()
  ) |>
  tab_style(
    style = cell_text(weight = "bold", color = "#006B4F"),
    locations = cells_column_labels()
  ) |>
  tab_style(
    style = cell_text(weight = "bold", color = "#3F6500"),
    locations = cells_body(columns = Metric)
  ) |>
  tab_options(
    table.width = px(540),
    table.font.size = px(13),
    data_row.padding = px(8),
    column_labels.padding = px(10),
    table.border.top.color = "#006B4F",
    table.border.bottom.color = "#006B4F",
    column_labels.border.bottom.color = "#D9E2DD",
    table_body.hlines.color = "#E8E8E8"
  )

tree_table
