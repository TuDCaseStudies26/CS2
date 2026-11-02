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

#define paths and constants
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
        "Year"
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
plm = make_pipeline(
        StandardScaler(),
        PoissonRegressor(alpha=1, max_iter=1000)
                    )
plm.fit(euro_train_df, euro_train_pred)

euro_test_predictions = plm.predict(euro_test_df)

# calculate error with test set
# TODO change the train test splitting
mae_euro = mean_absolute_error(euro_test_pred, euro_test_predictions)
rmse_euro = root_mean_squared_error(euro_test_pred, euro_test_predictions)

# single decision tree regressor
params: dict[str, list[float | int]] = {
    "ccp_alpha": [0.0, 0.001, 0.005, 0.02, 0.05],
    "min_samples_split": [2, 5, 10, 20, 40],
    "max_depth": [1, 2, 3, 5, 7, 10, 15],
    "random_state": [SEED]
}

years = np.sort(euro_train_df["Year"].unique())
tscv = TimeSeriesSplit(n_splits=3)
cv = [
        (
            np.flatnonzero(euro_train_df["Year"].isin(years[k])),
            np.flatnonzero(euro_train_df["Year"].isin(years[v]))
            )
        for k, v in tscv.split(years)
        ]

grid = GridSearchCV(
    estimator=DecisionTreeRegressor(random_state=SEED),
    param_grid=params,
    scoring="neg_mean_absolute_error",
    cv=cv,
)
dtree = grid.estimator()
# TODO test different arguments for randomforest
rf = RandomForestRegressor(n_jobs=-1)
rf = rf.fit(euro_train_df, euro_train_pred)

# TODO train XGBoost tuning?

# TODO train neural_network tuning?

