import json

import requests as r
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# serverUrl = "http://sensorthings-api:8080"
serverUrl = "https://84.88.76.18/wotst"


def clean_duplicates():
    skip = 0
    num_of_ds = 100

    skip_until = "Well_178_Santa_Giusta_000279_Depth_mH2O"
    skip_datastreams = True

    while num_of_ds >= 100:
        req = r.get(serverUrl + f"/FROST-Server/v1.1/Datastreams?$skip={skip}", verify=False)

        all_datastreams = json.loads(req.text)["value"]
        num_of_ds = len(all_datastreams)
        skip += num_of_ds

        for datastream in all_datastreams:
            if skip_datastreams:
                if datastream['name'] == skip_until:
                    skip_datastreams = False
                else:
                    continue
            print(datastream['name'])

            current_check_date = None

            observations_url = str(datastream['Observations@iot.navigationLink']).replace(
                "http://localhost:8008", serverUrl)

            measures_skip = 0
            measures_num = 100

            while measures_num >= 100:
                print("|", end="")
                req = r.get(observations_url + f"?$orderby=phenomenonTime asc&$skip={measures_skip}", verify=False)

                measures = json.loads(req.text)["value"]
                measures_num = len(measures)
                measures_skip += 100

                for measure in measures:
                    if current_check_date is not None and measure['phenomenonTime'] == current_check_date:
                        req2 = r.delete(str(measure['@iot.selfLink']).replace(
                            "http://localhost:8008", serverUrl), verify=False)
                    else:
                        current_check_date = measure['phenomenonTime']
            print()


if __name__ in "__main__":
    clean_duplicates()
