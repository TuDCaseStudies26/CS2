import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, root_mean_squared_error
from sklearn.tree import DecisionTreeRegressor

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
predictors_train: pd.DataFrame = training_df[features]
predictors_test: pd.DataFrame = test_df[features]
response: pd.Series = training_df["Goals"]
response_test: pd.Series = test_df["Goals"]

# fit model
dtree: DecisionTreeRegressor = DecisionTreeRegressor(random_state=SEED)
dtree = dtree.fit(predictors_train, response)

# TODO examine the importance of predictors in the regression tree.


y_pred_training: np.ndarray = dtree.predict(predictors_train)
y_pred_test: np.ndarray = dtree.predict(predictors_test)
model_stats: dict[str, float] = {
    "mae_train": mean_absolute_error(response, y_pred_training),
    "rmse_train": root_mean_squared_error(response_test, y_pred_test),
    "mae_test": mean_absolute_error(response_test, y_pred_test),
    "rmse_test": root_mean_squared_error(response_test, y_pred_test),
}
# TODO plot errors for presentation
