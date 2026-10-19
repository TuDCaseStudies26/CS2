import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.axes import Axes
from matplotlib.figure import Figure
from scipy import stats
from sklearn.linear_model import LinearRegression

## relative paths from project root
euro_test_path: str = "./data/EuroTest.csv"
euro_training_path: str = "./data/EuroTraining.csv"
handball_long_path: str = "./data/handball_long.csv"
handball_wide_path: str = "./data/handball_wide.csv"
tennis_path: str = "./data/SlamsData.csv"

euro_test_df: pd.DataFrame = pd.read_csv(euro_test_path)
euro_training_df: pd.DataFrame = pd.read_csv(euro_training_path)
handball_long_df: pd.DataFrame = pd.read_csv(handball_long_path)
handball_wide_df: pd.DataFrame = pd.read_csv(handball_wide_path)
tennis_df: pd.DataFrame = pd.read_csv(tennis_path)


## Task 2
### Linear Regression
# TODO inspect data and clean it
# QUESTIONS: should we mutate the season column like season - 2017(first date)? or create dummy variables for this
predictors: pd.DataFrame = handball_wide_df[["bet.probs.diff", "season"]]
betting_odds: pd.Series = handball_wide_df["bet.probs.diff"]
season_vals: pd.Series = handball_wide_df["season"]
response: pd.Series = handball_wide_df["scorediff"]
model: LinearRegression = LinearRegression()
model = model.fit(predictors, response)

# TODO what is meant by "checking the assumptions of the linear regression model"

y_pred: np.ndarray = model.predict(predictors)

residuals: pd.Series = response - y_pred
absolute_res: pd.Series = residuals.map(abs)

residual_comparison: dict[str, float] = {
    "mean_diff": absolute_res.agg("mean"),
    "median_diff": absolute_res.agg("median"),
}

fig: Figure
axes: np.ndarray
# plot qq, residuals against the single regressors, residuals against fitted values
fig, axes = plt.subplots(2, 2, figsize=(11, 8))

# qq plot
stats.probplot(residuals, dist="norm", plot=axes[0, 0])
axes[0, 0].set_title("Normal Q-Q Plot")

# residuals vs fitted for homoskedasticity
axes[0, 1].scatter(y_pred, residuals)
axes[0, 1].axhline(0, color="red")
axes[0, 1].set_xlabel("Fitted values")
axes[0, 1].set_ylabel("Residiuals")
axes[0, 1].set_title("Residuals against Fitted")

# residuals against season
axes[1, 0].scatter(season_vals, residuals)
axes[1, 0].axhline(0, color="red")
axes[1, 0].set_xlabel("Season")
axes[1, 0].set_ylabel("Residuals")

# residuals against betting odds
axes[1, 1].scatter(betting_odds, residuals)
axes[1, 1].axhline(0, color="red")
axes[1, 1].set_xlabel("Betting odds")
axes[1, 1].set_ylabel("Residuals")

plt.tight_layout()
plt.savefig("./graphs/Handball_Resid_plots.png")
plt.clf()

# TODO boxplot for absolute difference between true and predicted vals
plt.boxplot(absolute_res)
plt.ylabel("absolute difference predicted to true values")
plt.xlabel("score difference")
plt.savefig("./graphs/Handball_Abs_Resid.png")
plt.clf()
# we can see that we have a lot of high outliers
