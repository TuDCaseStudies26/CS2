import pandas as pd

# path to data from root of project directory
dur_path = "./data/hb_durations_in_minutes.csv"
dist_path = "./data/hb_distances_in_meters.csv"
hb_wide_path = "./data/handball_wide.csv"
handball_saving_path = "./data/hb_wide_w_dist_dur.csv"

# create the dataframes
duration_df = pd.read_csv(dur_path, index_col=0)
distance_df = pd.read_csv(dist_path, index_col=0)
hb_wide_df = pd.read_csv(hb_wide_path)

# change seconds to minutes
duration_df = duration_df // 60
# change meter to km
distance_df = distance_df // 1000

# iterate through team names (home, away) and get the duration for the route
hb_wide_df["duration_in_min"] = pd.Series(
    duration_df.loc[a, h]
    for h, a in zip(hb_wide_df["hometeam"], hb_wide_df["awayteam"])
)
# iterate through team names (home, away) and get the distance from the distance df
hb_wide_df["distance_in_meter"] = pd.Series(
    distance_df.loc[a, h]
    for h, a in zip(hb_wide_df["hometeam"], hb_wide_df["awayteam"])
)

# save this shit to a new csv file
hb_wide_df.to_csv(handball_saving_path)
