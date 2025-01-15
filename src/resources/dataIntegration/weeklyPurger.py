import datetime
import json

import requests as r
import urllib3
from tqdm import tqdm

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

serverUrl = "https://84.88.76.18/wotst"


def purge_weekly():
    skip = 0
    num_of_ds = 100

    while num_of_ds >= 100:
        req = r.get(serverUrl + f"/FROST-Server/v1.1/Datastreams?$skip={skip}", verify=False)

        all_datastreams = json.loads(req.text)["value"]
        num_of_ds = len(all_datastreams)
        skip += num_of_ds

        for datastream in tqdm(all_datastreams):
            if "AVG_WEEKLY_" not in datastream['name']:
                continue

            observations_url = str(datastream['Observations@iot.navigationLink']).replace(
                "http://localhost:8008", serverUrl)

            measures_skip = 0
            measures_num = 100

            while measures_num >= 100:
                req = r.get(observations_url + f"?$skip={measures_skip}", verify=False)

                measures = json.loads(req.text)["value"]
                measures_num = len(measures)
                measures_skip += 100

                for measure in measures:
                    # Mirar si la data de la mesura ere dilluns
                    try:
                        measureDate = datetime.datetime.strptime(measure['phenomenonTime'], "%Y-%m-%dT%H:%M:%S.%fZ")
                    except ValueError:
                        measureDate = datetime.datetime.strptime(measure['phenomenonTime'], "%Y-%m-%dT%H:%M:%SZ")
                    if measureDate.weekday() != 0:
                        delete_observations_url = measure['@iot.selfLink'].replace("http://localhost:8008", serverUrl)
                        req = r.delete(delete_observations_url, verify=False)
                        print(req.status_code)


if __name__ in "__main__":
    purge_weekly()
