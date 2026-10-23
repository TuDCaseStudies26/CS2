import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, root_mean_squared_error
from sklearn.model_selection import GridSearchCV
from sklearn.tree import DecisionTreeRegressor, plot_tree

SEED: int = 42069

# path from root of project
euro_train_path: str = "./data/EuroTraining.csv"
euro_test_path: str = "./data/EuroTest.csv"

training_df: pd.DataFrame = pd.read_csv(euro_train_path)
test_df: pd.DataFrame = pd.read_csv(euro_test_path)

features: list[str] = [
    "GroupStage",
    "GDP",
    "MarketValue",
    "FifaRank",
    "UefaPoints",
    "CLPlayers",
]
response_var: str = "Goals"

predictors_train: pd.DataFrame = training_df[features]
predictors_test: pd.DataFrame = test_df[features]
response_train: pd.Series = training_df[response_var]
response_test: pd.Series = test_df[response_var]

# fit model
dtree: DecisionTreeRegressor = DecisionTreeRegressor(random_state=SEED)
dtree = dtree.fit(predictors_train, response_train)

# TODO examine the importance of predictors in the regression tree.
## probably sklearn.inspection.permutation_importance
## or fitting models without feature and compare score
## cross validation can be done to make the tree "more rigorous"
## see at eda and only use correlating regressors


y_pred_training: np.ndarray = dtree.predict(predictors_train)
y_pred_test: np.ndarray = dtree.predict(predictors_test)
model_stats: dict[str, float] = {
    "mae_train": mean_absolute_error(response_train, y_pred_training),
    "rmse_train": root_mean_squared_error(response_train, y_pred_training),
    "mae_test": mean_absolute_error(response_test, y_pred_test),
    "rmse_test": root_mean_squared_error(response_test, y_pred_test),
}
# Observation: we see that the model predicts the training data perfectly
# {'mae_train': 0.0, 'rmse_train': 0.0, 'mae_test': 1.303921568627451, 'rmse_test': 1.6890651782777917}
# but the model is definitely overfitting
# TODO plot errors for presentation

# Grid search params
params: dict[str, list[float | int]] = {
    "ccp_alpha": [0.0, 0.001, 0.005, 0.02, 0.05],
    "min_samples_split": [2, 5, 10, 20, 40],
    "max_depth": [1, 2, 3, 5, 7, 10, 15],
}

grid: GridSearchCV[DecisionTreeRegressor] = GridSearchCV(
    estimator=DecisionTreeRegressor(random_state=SEED),
    param_grid=params,
    scoring="neg_mean_absolute_error",
    cv=5,
)
# TODO change features so only the important features are used and validate grid search again
grid = grid.fit(predictors_train, response_train)
best_model: DecisionTreeRegressor = grid.best_estimator_
best_params: dict[str, int | float] = grid.best_params_
