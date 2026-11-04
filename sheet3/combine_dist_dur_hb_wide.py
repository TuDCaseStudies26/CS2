import pandas as pd

dur_path = "./data/hb_durations_in_minutes.csv"
dist_path = "./data/hb_distances_in_meters.csv"
hb_wide_path = "./data/handball_wide.csv"
handball_saving_path = "./data/hb_wide_w_dist_dur.csv"

notdurft = pd.read_csv(dur_path, index_col=0)
distel = pd.read_csv(dist_path, index_col=0)
hb_wide_df = pd.read_csv(hb_wide_path)

hb_wide_df["duration_in_mins"] = pd.Series(
    notdurft.loc[h, a] for h, a in zip(hb_wide_df["hometeam"], hb_wide_df["awayteam"])
)
hb_wide_df["distance_in_meter"] = pd.Series(
    distel.loc[h, a] for h, a in zip(hb_wide_df["hometeam"], hb_wide_df["awayteam"])
)

hb_wide_df.to_csv(handball_saving_path)
