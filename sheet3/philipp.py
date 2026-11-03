import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import PoissonRegressor
from sklearn.metrics import mean_absolute_error, root_mean_squared_error
from sklearn.model_selection import TimeSeriesSplit, GridSearchCV
from sklearn.neural_network import MLPRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeRegressor
from xgboost import XGBRegressor

# define paths and constants
SEED = 42069

euro_train_path = "data/EuroTraining.csv"
euro_test_path = "data/EuroTest.csv"

euro_feature_list = [
    "GroupStage",
    "GDP",
    "MarketValue",
    "FifaRank",
    "UefaPoints",
    "CLPlayers",
    "Year",
]

euro_response = "Goals"
# Load euro datasets with path from root of project
euro_raw_df = pd.read_csv(euro_train_path)
euro_train_df = euro_raw_df[euro_feature_list]
euro_train_pred = euro_raw_df[euro_response]

euro_test_raw_df = pd.read_csv(euro_test_path)
euro_test_df = euro_test_raw_df[euro_feature_list]
euro_test_pred = euro_test_raw_df[euro_response]

# TODO split into training and test sets


# TODO K-fold cross-validation where fold
# corresponds to tournament and rolling window

# TODO train regression model poisson regression
plm = make_pipeline(StandardScaler(), PoissonRegressor(alpha=1, max_iter=1000))
plm.fit(euro_train_df, euro_train_pred)

euro_test_predictions = plm.predict(euro_test_df)

# calculate error with test set
# TODO change the train test splitting
mae_euro_poisson = mean_absolute_error(euro_test_pred, euro_test_predictions)
rmse_euro_poisson = root_mean_squared_error(euro_test_pred, euro_test_predictions)
print("Poisson regressor\nMAE\tRMSE")
print(*map(lambda x: round(x, 2), (mae_euro_poisson, rmse_euro_poisson)), sep="\t")

# single decision tree regressor
params_dtree: dict[str, list[float | int]] = {
    "ccp_alpha": [0.0, 0.001, 0.005, 0.02, 0.05],
    "min_samples_split": [2, 5, 10, 20, 40],
    "min_samples_leaf": [1, 3, 5, 7],
    "max_depth": [2, 3, 5, 7, 10, 15],
}

years = np.sort(euro_train_df["Year"].unique())
tscv = TimeSeriesSplit(n_splits=3)
cv = [
    (
        np.flatnonzero(euro_train_df["Year"].isin(years[k])),
        np.flatnonzero(euro_train_df["Year"].isin(years[v])),
    )
    for k, v in tscv.split(years)
]

grid_dtree = GridSearchCV(
    estimator=DecisionTreeRegressor(random_state=SEED),
    param_grid=params_dtree,
    scoring="neg_mean_absolute_error",
    cv=cv,
    refit=True,
)
grid_dtree.fit(euro_train_df, euro_train_pred)
dtree = grid_dtree.best_estimator_
dtree_preds = dtree.predict(euro_test_df)

mae_euro_dtree = mean_absolute_error(euro_test_pred, dtree_preds)
rmse_euro_dtree = root_mean_squared_error(euro_test_pred, dtree_preds)
print("Decision Tree Regressor\nMAE\tRMSE")
print(*map(lambda x: round(x, 2), (mae_euro_dtree, rmse_euro_dtree)), sep="\t")
## predict and get score of decision tree
# TODO test different arguments for randomforest

params_rf: dict[str, list[float | int | None]] = {
    "n_estimators": [100, 200, 500],
    "max_depth": [2, 3, 5, 7, 10, None],
    "min_samples_split": [2, 5, 10, 20],
    "min_samples_leaf": [1, 3, 5, 7],
}

grid_rf = GridSearchCV(
    estimator=RandomForestRegressor(n_jobs=-1, random_state=SEED),
    param_grid=params_rf,
    scoring="neg_mean_absolute_error",
    cv=cv,
    refit=True,
)

rf = grid_rf.fit(euro_train_df, euro_train_pred)
rf_pred = rf.predict(euro_test_df)

mae_euro_rf = mean_absolute_error(euro_test_pred, rf_pred)
rmse_euro_rf = root_mean_squared_error(euro_test_pred, rf_pred)
print("Random Forest Regressor\nMAE\tRMSE")
print(*map(lambda x: round(x, 2), (mae_euro_rf, rmse_euro_rf)), sep="\t")

# TODO train XGBoost tuning?
params_xgb = {
    "n_estimators": [100, 300],
    "max_depth": [3, 6, 9],
    "learning_rate": [0.01, 0.1, 0.2],
    "subsample": [0.8, 1.0],
    "colsample_bytree": [0.8, 1.0],
}

grid_xgb = GridSearchCV(
    estimator=XGBRegressor(objective="count:poisson", random_state=SEED, n_jobs=1),
    param_grid=params_xgb,
    scoring="neg_mean_absolute_error",
    cv=cv,
    refit=True,
)

xgb = grid_xgb.fit(euro_train_df, euro_train_pred)
xgb_pred = xgb.predict(euro_test_df)
mae_euro_xgb = mean_absolute_error(euro_test_pred, xgb_pred)
rmse_euro_xgb = root_mean_squared_error(euro_test_pred, xgb_pred)
print("XGBoost Regressor\nMAE\tRMSE")
print(*map(lambda x: round(x, 2), (mae_euro_xgb, rmse_euro_xgb)), sep="\t")
# TODO train neural_network tuning?
