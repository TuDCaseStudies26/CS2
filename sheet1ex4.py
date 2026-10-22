import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from scipy import stats
from sklearn.linear_model import LogisticRegression
import statsmodels.api as sm

#loading the data
euro_test_df: pd.DataFrame = pd.read_csv("./data/EuroTest.csv")
euro_training_df: pd.DataFrame = pd.read_csv("./data/EuroTraining.csv")
handball_long_df: pd.DataFrame = pd.read_csv("./data/handball_long.csv")
handball_wide_df: pd.DataFrame = pd.read_csv("./data/handball_wide.csv")
tennis_df: pd.DataFrame = pd.read_csv("./data/SlamsData.csv")
#test comment
#Check for missing values
print(tennis_df.isna().sum())
#no missing values

#Change to max 3 numbers after the comma
cols_to_round = ["elo", "prob", "age.30", "AvgProb.1", "AvgProb.2"]
tennis_df[cols_to_round] = tennis_df[cols_to_round].round(3)

# Training data: 2011 to 2017
tennis_train_df: pd.DataFrame = tennis_df[tennis_df["year"].between(2011, 2017)].copy()

# Test data: 2018 to 2024
tennis_test_df: pd.DataFrame = tennis_df[tennis_df["year"].between(2018, 2024)].copy()

#Quesion1
predictors = ["rank", "points", "elo", "age.30"]
X_train = sm.add_constant(tennis_train_df[predictors])
y_train = tennis_train_df["win"]

logit_model = sm.Logit(y_train, X_train).fit()
print(logit_model.summary())

#only elo is relevant because its the only variable with the p value smaller than 0.05 or 0.1 but need more test
#to see whether the others are corrolated or not
#Prepare the test predictors
X_test = sm.add_constant(tennis_test_df[predictors], has_constant="add")
y_test = tennis_test_df["win"]

#Predict probabilities on the test set
pred_probs = logit_model.predict(X_test)

#Convert probabilities to binary predictions (1 if prob >= 0.5, else 0)
pred_win = (pred_probs >= 0.5).astype(int)

#Compute the ratio of correctly predicted matches (Accuracy)
accuracy = (pred_win == y_test).mean()
print(f"Ratio of correctly predicted matches: {accuracy:.3f} ({accuracy * 100:.1f}%)")

#question 4: look ahead bias, time related and trend
#I will explain more in person.