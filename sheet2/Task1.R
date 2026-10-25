library(rpart)
library(rpart.plot)

handball_wide <- read.csv("handball_wide.csv")
EuroTraining  <- read.csv("EuroTraining.csv")
tennis        <- read.csv("SlamsData.csv")

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
                 data = tennis, method = "class")
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
    type = 2,                # Labels below branches
    extra = extra,           # Additional node information
    fallen.leaves = TRUE,    # Align terminal nodes
    box.palette = c(light_green, tu_green),
    branch.col = dark_green,
    branch.lwd = 1.5,
    shadow.col = "gray85",
    roundint = FALSE,
    nn = FALSE,              # Hide node numbers
    tweak = 1.15,            # Increase text size
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
mae  <- function(y, p) mean(abs(y - p))
rmse <- function(y, p) sqrt(mean((y - p)^2))

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

# tennis
acc_tn <- mean(class_tn == tennis$win)
acc_base_tn <- max(prop.table(table(tennis$win)))  
c(accuracy = acc_tn, baseline = acc_base_tn)


# predict error
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


tn <- cbind(tennis, prob = prob_tn)
head(tn[order(tn$prob, decreasing = TRUE), ], 5)  
head(tn[order(tn$prob), ], 5)                      


wrong <- tn[(tn$prob > 0.5) != (tn$win == "1"), ]
head(wrong[order(abs(wrong$prob - 0.5), decreasing = TRUE), ], 5)


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

# (c) 
printcp(tree_tn)                      
tree_tn$control$cp                   
?rpart.control



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
  main = "Tennis | cp = 0.1",
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




# Create comparison data
tree_comparison <- data.frame(
  Metric = c(
    "Number of leaves",
    "Distinct predicted probabilities",
    "Training accuracy"
  ),
  `cp = 0.01` = c("2", "2", "0.7505"),
  `cp = 0.001` = c("22", "19", "0.7653"),
  check.names = FALSE
)

tree_table <- tree_comparison |>
  gt() |>
  fmt(
    columns = c(`cp = 0.01`, `cp = 0.001`),
    rows = Metric == "Training accuracy",
    fns = function(x) sprintf("%.2f%%", as.numeric(x) * 100)
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