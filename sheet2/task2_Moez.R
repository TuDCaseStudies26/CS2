library(rpart)
library(rpart.plot)

######## 1 ############

EuroTraining <- read.csv("E:/uni/CS2/data/EuroTraining.csv")
EuroTesting <- read.csv("E:/uni/CS2/data/EuroTest.csv")
# Fit the regression tree with Goals as the response variable
euro_tree <- rpart(
  Goals ~ GroupStage + GDP + MarketValue + FifaRank + UefaPoints + CLPlayers,
  data = EuroTraining,
  method = "anova"
)

# Inspect the fitted tree and complexity parameter table
print(euro_tree)
printcp(euro_tree)


rpart.plot(
  euro_tree,
  main = "Euro | Goals",
  extra = 101,
  box.palette = "Greens",
  branch.col = "darkolivegreen",
  branch.lwd = 2,
  cex = 0.7,          # Fixed readable text size 
  yspace = 1.5,        # Adds vertical space between levels so vertical lines are visible!
  space = 0.3,         # Keeps horizontal spacing tight
  compress = FALSE     # Stops RStudio's wide screen from squishing the tree vertically
)
#The predictions use decimals but irl we cannot have like 3.4 goals so i think its better
#to round it.

#Although we used all 6 predictors in the tree, only 3 were retained (marketvalue, gdp 
#and fifarank) the others (groupstage, uefapoints and clplayers) were excluded because
#they never yielded a greater reduction in the RSS than the already chosen splits
#this can be changed by the cp parameter that is responsible for the complexity. by deault 0.01

#the most important variable is the marketvalue because it is the root nodes and still used 
#in lower nodes

#signs of overfitting due to the very few nodes (for the n=21) on nthe last level.
#signs of overfitting logic doesnt make sense , if you have a lower market value then you get more points
#signs of overfitting the same variable has been split 3 times.


########### 2 #################
# The features importance measures: 
#1: (gini impurity but for regression) Primary Split Impurity Reduction (Mean Decrease in Impurity)
#   winner takes all, test for all possible splits for all variables the one who has the biggest decrese
#   takes the split. (flaw: if 2 variables have similar reduction then it doesnt matter, only one matters)
#2: Permutation Importance (Mean Decrease in Accuracy)
#3: Split Count / Frequency (how many times a variable has been chosen to be used as a split crit.)
#4: Surrogate-Adjusted Impurity Importance (default rpart() var.)

#If I were to chose only one I would chose the surrogate adjusted impurity not only because it is the 
#default option in rpart() but also it has the good features of the primary split impurity reduction
#without the winner takes all mentality.


# 1. Calculate percentage importance
var_imp_pct <- round(100 * euro_tree$variable.importance / sum(euro_tree$variable.importance), 1)
vals <- rev(var_imp_pct)

# 2. Increase the left margin (second number = 7) so labels are never cut off
old_par <- par(mar = c(5, 7, 4, 3))

# 3. Draw barplot without default y-axis labels (names.arg = "") and extend x-axis to 45
bp <- barplot(
  vals,
  horiz = TRUE,
  names.arg = "",                         # Hide default labels so we can draw inclined ones
  xlim = c(0, 45),                        # Extends x-axis past the max value (~39%)
  xaxt = "n",                             # Custom x-axis ticks below
  col = "darkolivegreen3",
  main = "Variable Importance in euro_tree (%)",
  xlab = "Relative Importance (%)"
)

# 4. Add a clean x-axis going all the way from 0 to 45 by 5s
axis(1, at = seq(0, 45, by = 5), cex.axis = 0.9)

# 5. Add smaller (cex = 0.85), inclined (srt = 45) y-axis labels
text(
  x = -0.8,                               # Places text just to the left of the bars
  y = bp, 
  labels = names(vals), 
  srt = 45,                               # Inclines text at a 45-degree angle
  adj = 1,                                # Right-aligns text to the bar edge
  xpd = TRUE,                             # Allows drawing in the left margin without clipping
  cex = 0.85                              # Makes y-axis text slightly smaller
)

# 6. Print exact percentage values at the end of each bar
text(x = vals + 0.5, y = bp, labels = paste0(vals, "%"), pos = 4, cex = 0.85, xpd = TRUE)

# Reset margins back to default
par(old_par)


########## 3 #############
# Predict Goals on the Training and Testing data
pred_train <- predict(euro_tree, newdata = EuroTraining)
pred_test  <- predict(euro_tree, newdata = EuroTesting)

# Compute MAE and RMSE for Training Data
mae_train  <- mean(abs(EuroTraining$Goals - pred_train))
rmse_train <- sqrt(mean((EuroTraining$Goals - pred_train)^2))

# Compute MAE and RMSE for Testing Data
mae_test   <- mean(abs(EuroTesting$Goals - pred_test))
rmse_test  <- sqrt(mean((EuroTesting$Goals - pred_test)^2))

# Display the results in a clean summary table
results_table <- data.frame(
  Dataset = c("Training Data", "Test Data"),
  MAE     = c(mae_train, mae_test),
  RMSE    = c(rmse_train, rmse_test)
)

print(results_table, digits = 4)
#      Dataset    MAE   RMSE
#1 Training Data 0.7789 0.9711
#2     Test Data 0.7836 1.0549

######### 4 ##############
#comparing using the MAE and RMSE
#The training and test errors are relatively similar, with slightly higher errors 
#on the test set. This suggests that the regression tree generalizes reasonably well
#and does not show strong signs of overfitting. However, the cross-validation error 
#increases slightly from 0.9315 to 0.9647 when moving from 6 to 7 splits, suggesting 
#possible mild overfitting. Furthermore, the relatively high cross-validation error 
#indicates limited predictive performance. Overall, the tree appears reasonable in 
#terms of generalization, with possible mild overfitting and relatively limited predictive power.

# ---> The regression tree appears to be reasonable and generalizes fairly well to unseen data

########## 5 ################
# Define the hyperparameter grid
grid <- expand.grid(
  cp = c(0, 0.001, 0.005, 0.01, 0.02, 0.05),
  minsplit = c(2, 5, 10, 20, 40),
  maxdepth = c(1, 2, 3, 5, 7, 10, 15)
)

# Create columns to store the MAE results
grid$MAE_train <- NA_real_
grid$MAE_test  <- NA_real_

# Fit and evaluate each regression tree
for (i in 1:nrow(grid)) {
  
  tree <- rpart(
    Goals ~ GroupStage + GDP + MarketValue +
      FifaRank + UefaPoints + CLPlayers,
    data = EuroTraining,
    method = "anova",
    control = rpart.control(
      cp = grid$cp[i],
      minsplit = grid$minsplit[i],
      maxdepth = grid$maxdepth[i]
    )
  )
  
  # Predictions
  pred_train <- predict(tree, newdata = EuroTraining)
  pred_test  <- predict(tree, newdata = EuroTesting)
  
  # Calculate MAE
  grid$MAE_train[i] <- mean(abs(EuroTraining$Goals - pred_train))
  grid$MAE_test[i]  <- mean(abs(EuroTesting$Goals - pred_test))
}


######### 6 #############
# Sort by lowest test MAE
results <- grid[order(grid$MAE_test), ]

# Display all 210 combinations
print(results, row.names = FALSE)

# Display the 10 combinations with lowest test MAE
head(results, 8)

# there is not a single combination that gives the best metrics for error:
# cp up to 0.01 + min split 5 or 10 + max depth 3
# most overfitted tree is with cp = 0 (no pruning complexity), min split = 2 (small nodes) 
# and maxt depth of 15  (the max of our grid.)

######### 7 ###########
# Fit the best tree
best_tree <- rpart(
  Goals ~ GroupStage + GDP + MarketValue +
    FifaRank + UefaPoints + CLPlayers,
  data = EuroTraining,
  method = "anova",
  control = rpart.control(
    cp = 0.01,
    minsplit = 3,
    maxdepth = 3
  )
)

# Visualize the best tree
rpart.plot(
  best_tree,
  main = "Euro | Best Regression Tree",
  extra = 101,
  box.palette = "Greens",
  branch.col = "darkolivegreen",
  branch.lwd = 2,
  cex = 0.7,
  yspace = 1.5,
  space = 0.3,
  compress = FALSE
)
# Fit the most overfitted tree
overfit_tree <- rpart(
  Goals ~ GroupStage + GDP + MarketValue +
    FifaRank + UefaPoints + CLPlayers,
  data = EuroTraining,
  method = "anova",
  control = rpart.control(
    cp = 0,
    minsplit = 2,
    maxdepth = 15
  )
)

# Visualize the most overfitted tree
rpart.plot(
  overfit_tree,
  main = "Euro | Most Overfitted Regression Tree",
  extra = 101,
  box.palette = "Reds",
  branch.col = "firebrick4",
  branch.lwd = 2,
  cex = 0.5,
  yspace = 1.5,
  space = 0.3,
  compress = FALSE
)

#It is impossible to compare visually as the most overfitted tree is way too complex to be 
#able to fit it in a graph and still be readable


# Function to evaluate each tree
evaluate_tree <- function(tree, name) {
  pred_train <- predict(tree, newdata = EuroTraining)
  pred_test <- predict(tree, newdata = EuroTesting)
  
  data.frame(
    Tree = name,
    Terminal_Nodes = sum(tree$frame$var == "<leaf>"),
    MAE_train = mean(abs(EuroTraining$Goals - pred_train)),
    MAE_test = mean(abs(EuroTesting$Goals - pred_test))
  )
}

comparison <- rbind(
  evaluate_tree(best_tree, "Best Tree"),
  evaluate_tree(overfit_tree, "Most Overfitted Tree")
)

print(comparison, row.names = FALSE)


######## 8 ###############

# Select results with cp = 0 and minsplit = 2
depth_results <- subset(grid, cp == 0 & minsplit == 2)

# Sort by maxdepth
depth_results <- depth_results[order(depth_results$maxdepth), ]

# Plot training MAE
plot(
  depth_results$maxdepth,
  depth_results$MAE_train,
  type = "b",
  col = "darkolivegreen4",
  pch = 16,
  lwd = 2,
  ylim = range(c(depth_results$MAE_train,
                 depth_results$MAE_test)),
  xlab = "Maximum Tree Depth",
  ylab = "Mean Absolute Error (MAE)",
  main = "Euro | Training vs Test MAE",
  xaxt = "n"
)

# Add test MAE
lines(
  depth_results$maxdepth,
  depth_results$MAE_test,
  type = "b",
  col = "firebrick3",
  pch = 17,
  lwd = 2
)

# Add x-axis values
axis(1, at = depth_results$maxdepth)

# Add legend
legend(
  "topleft",
  legend = c("Training MAE", "Test MAE"),
  col = c("darkolivegreen4", "firebrick3"),
  lty = 1,
  pch = c(16, 17),
  lwd = 2,
  bty = "n"
)

# Add grid
grid()

#As the maximum tree depth increases, the training MAE continuously decreases, while 
#the test MAE increases. This indicates that deeper trees fit the training data more 
#closely but generalize increasingly poorly to unseen data. The gap between training and 
#test errors becomes particularly noticeable after depth 2, showing increasing overfitting.
#The lowest test MAE is achieved at depth 1, suggesting that a simpler tree performs better
#for this specific hyperparameter configuration (cp = 0, minsplit = 2). Overall, the plot 
#clearly demonstrates the bias-variance trade-off: increasing model complexity reduces t
#raining error but leads to worse generalization due to overfitting.

######### 8 ##########

#----------------------------for tennis--------------------------------------

TennisData <- read.csv("E:/uni/CS2/data/SlamsData.csv")

# Prepare the target variable for classification
TennisData$win <- factor(TennisData$win, levels = c(0, 1))

# Split data by year
TennisTraining <- subset(
  TennisData,
  year >= 2011 & year <= 2017
)

TennisTesting <- subset(
  TennisData,
  year >= 2018 & year <= 2024
)

# Check dataset sizes
cat("Training observations:", nrow(TennisTraining), "\n")
cat("Testing observations:", nrow(TennisTesting), "\n")


# Define the hyperparameter grid
grid_tennis <- expand.grid(
  cp = c(0, 0.001, 0.005, 0.01, 0.02, 0.05),
  minsplit = c(2, 5, 10, 20, 40),
  maxdepth = c(1, 2, 3, 5, 7, 10, 15)
)

# Create columns to store MAE results
grid_tennis$MAE_train <- NA_real_
grid_tennis$MAE_test  <- NA_real_


# Fit and evaluate each classification tree
for (i in 1:nrow(grid_tennis)) {
  
  tree <- rpart(
    win ~ rank + points + elo + age.30,
    data = TennisTraining,
    method = "class",
    control = rpart.control(
      cp = grid_tennis$cp[i],
      minsplit = grid_tennis$minsplit[i],
      maxdepth = grid_tennis$maxdepth[i]
    )
  )
  
  # Predictions (0 or 1)
  pred_train <- predict(
    tree,
    newdata = TennisTraining,
    type = "class"
  )
  
  pred_test <- predict(
    tree,
    newdata = TennisTesting,
    type = "class"
  )
  
  # Calculate MAE (equivalent to error rate for 0/1 labels)
  grid_tennis$MAE_train[i] <- mean(
    pred_train != TennisTraining$win
  )
  
  grid_tennis$MAE_test[i] <- mean(
    pred_test != TennisTesting$win
  )
}


# Sort by lowest test MAE
results_tennis <- grid_tennis[
  order(grid_tennis$MAE_test),
]

# Display all 210 combinations
print(results_tennis, row.names = FALSE)

# Display the 8 best combinations
head(results_tennis, 30)

# Display the best combination
best_tennis <- results_tennis[1, ]
print(best_tennis)

#best model as long as: Every combination with maxdepth = 1, 2, 3. Every combination 
#with cp >= 0.005 and maxdepth = 5, 7, 10, 15. This represents 170 out of 210 combinations.

#---------------------------for handball---------------------------------

# 2. Split the data by season
HandballTraining <- subset(handball_wide, season != 2022)
HandballTesting  <- subset(handball_wide, season == 2022)

# Check dataset sizes
cat("Training observations:", nrow(HandballTraining), "\n")
cat("Testing observations:", nrow(HandballTesting), "\n")


# 3. Define the hyperparameter grid
grid_handball <- expand.grid(
  cp = c(0, 0.001, 0.005, 0.01, 0.02, 0.05),
  minsplit = c(2, 5, 10, 20, 40),
  maxdepth = c(1, 2, 3, 5, 7, 10, 15)
)

# 4. Create columns to store MAE results
grid_handball$MAE_train <- NA_real_
grid_handball$MAE_test  <- NA_real_


# 5. Fit and evaluate each regression tree
for (i in 1:nrow(grid_handball)) {
  
  tree <- rpart(
    scorediff ~ bet.probs.diff + season,
    data = HandballTraining,
    method = "anova",
    control = rpart.control(
      cp = grid_handball$cp[i],
      minsplit = grid_handball$minsplit[i],
      maxdepth = grid_handball$maxdepth[i]
    )
  )
  
  # Predictions
  pred_train <- predict(tree, newdata = HandballTraining)
  pred_test  <- predict(tree, newdata = HandballTesting)
  
  # Calculate MAE
  grid_handball$MAE_train[i] <- mean(
    abs(HandballTraining$scorediff - pred_train)
  )
  
  grid_handball$MAE_test[i] <- mean(
    abs(HandballTesting$scorediff - pred_test)
  )
}


# 6. Sort by lowest test MAE
results_handball <- grid_handball[
  order(grid_handball$MAE_test),
]

# Display all 210 combinations
print(results_handball, row.names = FALSE)

# Display the 8 best combinations
head(results_handball, 8)

# Display the best combination
best_handball <- results_handball[1, ]
print(best_handball)

#best result with cp = 0, minsplit = 40 and maxdepth = 5
