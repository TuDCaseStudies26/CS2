import pandas as pd
import dataframe_image as dfi

path = "./data/hb_wide_w_dist_dur.csv"

hb = pd.read_csv(path)

to_show = (hb[["hometeam", "awayteam", "duration_in_min", "distance_in_meter"]]
           .head(6)
           .rename(columns={
    "hometeam": "Home Team",
    "awayteam": "Away Team",
    "distance_in_meter": "Distance (km)",
    "duration_in_min": "Duration (min)"
    })
)

dfi.export(to_show, "presi_hb_df.svg", table_conversion="matplotlib", dpi=300, fontsize=14)
