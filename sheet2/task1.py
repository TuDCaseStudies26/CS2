# %% Imports and data preparation
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.tree import DecisionTreeRegressor, DecisionTreeClassifier, plot_tree, export_text

handball = pd.read_csv("../handball_wide.csv")
euro_train = pd.read_csv("../EuroTraining.csv")
euro_test = pd.read_csv("../EuroTest.csv")
tennis = pd.read_csv("../SlamsData.csv")

# Remove exact duplicate rows
handball_clean = handball.drop_duplicates()

# Remove match 1260 due to inconsistent scores
handball_clean = handball_clean[
    handball_clean["matchid"] != 1260
].copy()


# the responses and predictors for the three datasets
hb_X, hb_y = handball_clean[["bet.probs.diff", "season"]], handball_clean["scorediff"]
eu_vars = ["GroupStage", "GDP", "MarketValue", "FifaRank", "UefaPoints", "CLPlayers"]
eu_X, eu_y = euro_train[eu_vars], euro_train["Goals"]
tn_vars = ["rank", "points", "elo", "age.30"]
tn_X, tn_y = tennis[tn_vars], tennis["win"]   # binary response


# %% Handball - Fit tree
# Decision tree regression for handball data
hb_tree = DecisionTreeRegressor(
    max_depth=30,
    min_samples_split=20,
    min_samples_leaf=7,
    random_state=42
)
hb_tree.fit(hb_X, hb_y)

#%% Handball - Visualize the tree
plt.figure(figsize=(12, 8))
plot_tree(
    hb_tree, feature_names=hb_X.columns, filled=True, rounded=True)
plt.show()

# %% Handball - Predictions
from sklearn.metrics import mean_absolute_error, mean_squared_error
hb_pred = hb_tree.predict(hb_X)

# MAE and RMSE
hb_mae = mean_absolute_error(hb_y, hb_pred)
hb_rmse = np.sqrt(mean_squared_error(hb_y, hb_pred))

print("MAE:", hb_mae)
print("RMSE:", hb_rmse)

# %% Handball - Prediction errors
hb_results = handball_clean.copy()

hb_results["predicted"] = hb_pred
hb_results["error"] = hb_pred - hb_y


#%% Handball - Largest overestimations and underestimations
cols = [
    "matchid", "hometeam", "awayteam",
    "season", "bet.probs.diff",
    "scorediff", "predicted", "error"
]

print("Largest overestimations:")
print(hb_results.nlargest(5, "error")[cols].to_string(index=False))

print("\nLargest underestimations:")
print(hb_results.nsmallest(5, "error")[cols].to_string(index=False))

# %% Handball - Predicted vs. Actual

plt.figure(figsize=(8, 6))

plt.scatter(hb_y, hb_pred, alpha=0.5)

# Reference line: perfect predictions
lower = min(hb_y.min(), hb_pred.min())
upper = max(hb_y.max(), hb_pred.max())

plt.plot(
    [lower, upper],
    [lower, upper],
    "r--",
    label="Perfect prediction"
)

plt.xlabel("Actual goal difference")
plt.ylabel("Predicted goal difference")
plt.title("Handball: Predicted vs. Actual")
plt.legend()
plt.grid(alpha=0.3)
plt.show()# %%

# %% Euro - Fit regression tree
eu_tree = DecisionTreeRegressor(
    max_depth=30,
    min_samples_split=20,
    min_samples_leaf=7,
    random_state=42
)
eu_tree.fit(eu_X, eu_y)

print("Tree depth:", eu_tree.get_depth())
print("Number of leaves:", eu_tree.get_n_leaves())


# %% Euro - Visualize tree
plt.figure(figsize=(16, 9))

plot_tree(
    eu_tree,
    feature_names=eu_X.columns,
    filled=True,
    rounded=True,
    fontsize=8
)

plt.show()


# %% Euro - Predictions

eu_pred = eu_tree.predict(eu_X)

eu_results = euro_train.copy()
eu_results["predicted"] = eu_pred

print(eu_results[["Goals", "predicted"]].head(10))

# %% Euro - Model evaluation
eu_mae = mean_absolute_error(eu_y, eu_pred)
eu_rmse = np.sqrt(mean_squared_error(eu_y, eu_pred))

print("MAE:", eu_mae)
print("RMSE:", eu_rmse)

# %%Euro - Prediction errors

eu_results["error"] = eu_pred - eu_y.to_numpy()
eu_results["absolute_error"] = abs(eu_results["error"])

# Largest overestimations
print(eu_results.nlargest(5, "error"))

# Largest underestimations
print(eu_results.nsmallest(5, "error"))

# %%Euro - Predicted vs. Actual

plt.figure(figsize=(8, 6))

plt.scatter(eu_y, eu_pred, alpha=0.5)

lower = min(eu_y.min(), eu_pred.min())
upper = max(eu_y.max(), eu_pred.max())

plt.plot(
    [lower, upper],
    [lower, upper],
    "r--",
    label="Perfect prediction"
)

plt.xlabel("Actual goals")
plt.ylabel("Predicted goals")
plt.title("Euro: Predicted vs. Actual Goals")
plt.legend()
plt.grid(alpha=0.3)
plt.show()




# %% Tennis - Fit classification tree
tn_tree = DecisionTreeClassifier(
    random_state=42,
    max_depth=30,
    min_samples_split=20,
    min_samples_leaf=7,
    ccp_alpha=0.01
)

tn_tree.fit(tn_X, tn_y)

print("Tree depth:", tn_tree.get_depth())
print("Number of leaves:", tn_tree.get_n_leaves())

# %% Tennis - Visualize the tree
plt.figure(figsize=(16, 9))

plot_tree(
    tn_tree,
    feature_names=tn_X.columns,
    class_names=["Lost", "Won"],
    filled=True,
    rounded=True,
    fontsize=8
)

plt.show()
# %% Tennis - Predictions

tn_pred = tn_tree.predict(tn_X)

tn_prob = tn_tree.predict_proba(tn_X)[:, 1]

tn_results = tennis.copy()

tn_results["predicted"] = tn_pred
tn_results["win_probability"] = tn_prob

print(tn_results[["win", "predicted", "win_probability"]].head(10))

# %% Tennis - Model evaluation

from sklearn.metrics import accuracy_score

tn_accuracy = accuracy_score(tn_y, tn_pred)

print("Accuracy:", tn_accuracy)
print("Correct predictions:", (tn_y.to_numpy() == tn_pred).sum())
print("Total observations:", len(tn_y))


# %% Tennis - Extreme predicted probabilities

print("Highest winning probabilities:")
print(
    tn_results.nlargest(5, "win_probability")
)

print("Lowest winning probabilities:")
print(
    tn_results.nsmallest(5, "win_probability")
)
