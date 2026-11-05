import pandas as pd
import requests

# handball wide path from root of project
city_codes_path = "./data/city_codes.csv"
hb_wide_path = "./data/handball_wide.csv"
distances_path = "./data/hb_distances_in_meters.csv"
duration_path = "./data/hb_durations_in_minutes.csv"

# load team coordinates into dataframe
cts = pd.read_csv(city_codes_path, index_col="team")

# create coordinates string with long,lat;long,lat
coordinates_str = ";".join(
    f"{row.longitude},{row.latitude}" for row in cts.itertuples()
)

url = "http://router.project-osrm.org/table/v1/driving/" + coordinates_str

# get the fucking data
res = requests.get(url, params={"annotations": "distance,duration"}, timeout=30)

# if we get 4xx or 5xx status code raise Error
res.raise_for_status()

# unmarshal data into dictionary
data = res.json()

# check if data exists
assert data["code"] == "Ok", f"you stupid, don't make mistakes\n{data}"

# create dataframe for distances in meter
dist = pd.DataFrame(data["distances"], index=cts.index, columns=cts.index)

# create dataframe for travel duration in seconds
time_travel = pd.DataFrame(data["durations"], index=cts.index, columns=cts.index)

# save the dataframes to csv files
dist.to_csv(distances_path)
time_travel.to_csv(duration_path)
