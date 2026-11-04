import pandas as pd
import requests

# handball wide path from root of project
city_codes_path = "./data/city_codes.csv"
hb_wide_path = "./data/handball_wide.csv"
distances_path = "./data/hb_distances_in_meters.csv"
duration_path = "./data/hb_durations_in_minutes.csv"

cts = pd.read_csv(city_codes_path, index_col="team")

hans = ";".join(f"{row.longitude},{row.latitude}" for row in cts.itertuples())

url = "http://router.project-osrm.org/table/v1/driving/" + hans

res = requests.get(url, params={"annotations": "distance,duration"}, timeout=30)

res.raise_for_status()

data = res.json()

if data["code"] != "Ok":
    raise RuntimeError(data)

dist = pd.DataFrame(data["distances"], index=cts.index, columns=cts.index)

time_travel = pd.DataFrame(data["durations"], index=cts.index, columns=cts.index)

dist.to_csv(distances_path)
time_travel.to_csv(duration_path)
