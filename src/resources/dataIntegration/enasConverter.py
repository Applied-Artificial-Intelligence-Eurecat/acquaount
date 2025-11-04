import json
import math
import sys

import requests as r
import urllib3

from src.resources.dataIntegration.enas import level_to_volume

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

sensor_id = "1067" #1067 10329
datastream_mslm_id = "1435" #1435 1436
datastream_m3_id = "1949" #1949 1952

serverUrl = "https://84.88.76.18/wotst"

if __name__ in "__main__":
    req = r.get(serverUrl + f"/FROST-Server/v1.1/Datastreams({datastream_mslm_id})", verify=False)
    resp = json.loads(req.text)

    observations_url = str(resp['Observations@iot.navigationLink']).replace(
        "http://localhost:8008", serverUrl)

    req = r.get(serverUrl + f"/FROST-Server/v1.1/Datastreams({datastream_m3_id})", verify=False)
    resp = json.loads(req.text)

    observations_url_2 = str(resp['Observations@iot.navigationLink']).replace(
        "http://localhost:8008", serverUrl)

    measures_skip = 69200
    measures_num = 100

    total_measures = 0
    total_value = 0

    has_measures = False

    while measures_num >= 100:
        print(measures_skip)
        req = r.get(observations_url + f"?$skip={measures_skip}", verify=False)

        measures = json.loads(req.text)
        measures_num = len(measures['value'])
        measures_skip += 100

        for measure in measures['value']:
            r.delete(serverUrl + f"/FROST-Server/v1.1/Observations({measure['@iot.id']})", verify=False)

            packet = {
                "result": int(math.floor(level_to_volume(sensor_id, measure['result']))),
                "phenomenonTime": measure['phenomenonTime']
            }

            req = r.post(observations_url_2, json=packet, verify=False)
