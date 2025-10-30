import json

import requests as r
import urllib3
from hecdss import HecDss

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

server_url = "https://84.88.76.18/wot/"


def read_from_file(filename, filepath, deviceID, property_key):
    measures = []
    with HecDss(filename) as dss:
        dataserie = dss.get(filepath)
        for i, value in enumerate(dataserie.values):
            measure = {
                'info': {
                    'deviceID': deviceID,
                    'timestamp': dataserie.times[i].strftime("%Y-%m-%dT%H:%M:%SZ")
                },
                'values': {
                    property_key: value
                }
            }
            measures.append(measure)
    return measures


def upload_to_wot(measures, thing_url):
    url = f"{server_url}/{thing_url}/actions/receiveMeasure"

    for packet in measures:
        if "device_id" in packet["info"]:
            packet["info"]["deviceID"] = packet["info"]["device_id"]
            del packet["info"]["device_id"]
        res = r.post(url, data=json.dumps(packet), verify=False)
        if res.status_code != 200:
            print(res.status_code)


if __name__ in "__main__":
    with open("modelUploadConfig.json", "r") as f:
        config_file = json.loads(f.read())

    filename = config_file["filename"]
    thing_url = config_file["thing_url"]

    for config in config_file["configs"]:
        deviceID = config["deviceID"]
        property_key = config["property_key"]

        # for filepath in config["filepaths"]:
        filepath = config["filepaths"][0]
        data = read_from_file(filename, filepath, deviceID, property_key)
        # print(len(data), json.dumps(data[0]))
        upload_to_wot(data, thing_url)
