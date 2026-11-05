import pandas as pd

from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter
from geopy.distance import geodesic

team_city_dict = {
    "Eulen Ludwigshafen": "Ludwigshafen, Germany",
    "TV 05/07 Hüttenberg": "Hüttenberg, Germany",
    "FRISCH AUF! Göppingen": "Göppingen, Germany",
    "Füchse Berlin": "Berlin, Germany",
    "GWD Minden": "Minden, Germany",
    "Hannover-Burgdorf": "Hannover, Germany",
    "HC Erlangen": "Erlangen, Germany",
    "HSG Wetzlar": "Wetzlar, Germany",
    "MT Melsungen": "Melsungen, Germany",
    "Rhein-Neckar Löwen": "Mannheim, Germany",
    "SC DHfK Leipzig": "Leipzig, Germany",
    "SC Magdeburg": "Magdeburg, Germany",
    "SG Flensburg-Handewitt": "Flensburg, Germany",
    "TBV Lemgo Lippe": "Lemgo, Germany",
    "THW Kiel": "Kiel, Germany",
    "TuS N-Lübbecke": "Lübbecke, Germany",
    "TVB Stuttgart": "Stuttgart, Germany",
    "VfL Gummersbach": "Gummersbach, Germany",
    "Bergischer HC": "Solingen, Germany",
    "SG BBM Bietigheim": "Bietigheim, Germany",
    "HBW Balingen-Weilstetten": "Weilstetten, Germany",
    "HSG Nordhorn-Lingen": "Nordhorn-Lingen, Germany",
    "HSC 2000 Coburg": "Coburg, Germany",
    "TuSEM Essen": "Essen, Germany",
    "Handball Sport Verein Hamburg": "Hamburg, Germany",
    "ASV Hamm-Westfalen": "Hamm, Germany",
}


class Distances:
    def __init__(self, city_dict=team_city_dict) -> None:
        self.locator: Nominatim = Nominatim(user_agent="handball-distances", timeout=5)
        self.geocode: RateLimiter = RateLimiter(
            self.locator.geocode, min_delay_seconds=1, max_retries=2
        )
        self.teams: dict[str, str] = city_dict
        self.city_codes: pd.DataFrame = self.make_city_codes()

    def make_city_codes(self) -> pd.DataFrame:
        res: dict[str, tuple] = dict()
        hans: pd.DataFrame
        for team, fallback in self.teams.items():
            # get location for team
            team_location = self.geocode(team)
            if team_location is None:
                team_location = self.geocode(fallback)
                assert team_location is not None, f"{team} not found"

            # add location latitude and longitude to city_codes
            res[team] = (team_location.latitude, team_location.longitude)

            hans = pd.DataFrame.from_dict(
                res, orient="index", columns=["latitude", "longitude"]
            )
            hans.index.name = "team"
        return hans

    def get_distance(self, team_a: str, team_b: str) -> float:
        ok_a, ok_b = self.city_codes.get(team_a, ()), self.teams.get(team_b, ())
        if not ok_a:
            return -1
        if not ok_b:
            return -1
        lat_long_a = (ok_a[0], ok_a[1])
        lat_long_b = (ok_b[0], ok_b[1])
        distance = geodesic(lat_long_a, lat_long_b).km
        return distance

    def write_city_codes_csv(self, path: str) -> None:
        self.city_codes.to_csv(path)


if __name__ == "__main__":
    test = Distances()
    test.write_city_codes_csv("./data/city_codes.csv")
