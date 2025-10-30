import csv
import datetime
import json
import sys

import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

import requests as r

server_url = "https://84.88.76.18/wot/"
st_url = "https://84.88.76.18/wotst"


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
    if len(sys.argv) > 1:
        run_file = sys.argv[1]
    else:
        print("ERROR Run File Not Specified")
        sys.exit(-1)

    # Eliminar prediccions mes velles
    datastreams = [
        run_file["fieldName"] + "IrrigationVolumePrediction",
        run_file["fieldName"] + "IrrigationDeficitPrediction",
        run_file["fieldName"] + "SoilMoisturePrediction",
        run_file["fieldName"] + "DailyIrrigationGivenPrediction",
    ]

    now = datetime.datetime.now()
    today_date = datetime.datetime(year=now.year, month=now.month, day=now.day, hour=0, minute=0, second=0)

    for datastream in datastreams:
        url = st_url + "/FROST-Server/v1.1/Datastreams?$filter=name eq '" + datastream + "'"
        req = r.get(url)

        req_json = json.loads(req.text)
        observations_url = req_json["value"]["0"]["@Observations@iot.navigationLink"].replace("http://localhost:8008",
                                                                                              st_url)

        observations_url += "?$filter=phenomenonTime gt " + today_date.strftime("%Y-%m-%dT%H:%M:%SZ")

        hasnext = True
        while hasnext:
            req = r.get(observations_url)
            req_json = json.loads(req.text)

            for measure in req_json["value"]:
                r.delete(measure["@iot.selfLink"].replace("http://localhost:8008", st_url))

            if "@iot.nextLink" in req_json:
                hasnext = True
            else:
                hasnext = False

    # Llegir fitxers de resultats
    irr_vol = []
    irr_deficit = []
    soil_moisture = []
    irr_daily = []

    with open('Output_data/hourly_variables_final.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            mt = datetime.datetime.strptime(row["\"TIME\""], "%Y-%m-%d %H:%M:%S")

            irr_vol.append({
                "info": {
                    "deviceID": run_file['fieldTitle'].lower(),
                    "timestamp": mt.strftime("%Y-%m-%dT%H:%M:%SZ")
                }, "values": {
                    "Irrigation Volume Prediction": float(row["\"Irr_vol_m3\""])
                }
            })

            irr_deficit.append({
                "info": {
                    "deviceID": run_file['fieldTitle'].lower(),
                    "timestamp": mt.strftime("%Y-%m-%dT%H:%M:%SZ")
                }, "values": {
                    "Irrigation Deficit Prediction": float(row["\"Irr_deficit_m3\""])
                }
            })

            soil_moisture.append({
                "info": {
                    "deviceID": run_file['fieldTitle'].lower(),
                    "timestamp": mt.strftime("%Y-%m-%dT%H:%M:%SZ")
                }, "values": {
                    "Soil Moisture Prediction": float(row["\"Soil_moisture\""])
                }
            })

    with open('Output_data/Irr_daily.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            mt = datetime.datetime.strptime(row["\"Date\""], "%Y-%m-%d")

            irr_daily.append({
                "info": {
                    "deviceID": run_file['fieldTitle'].lower(),
                    "timestamp": mt.strftime("%Y-%m-%dT00:00:00Z")
                }, "values": {
                    "Daily Irrigation Given Prediction": float(row["\"Irr_given\""])
                }
            })

    # Penjar dades als datastreams
    upload_to_wot(irr_vol, run_file['fieldTitle'].lower())
    upload_to_wot(irr_deficit, run_file['fieldTitle'].lower())
    upload_to_wot(soil_moisture, run_file['fieldTitle'].lower())
    upload_to_wot(irr_daily, run_file['fieldTitle'].lower())

    # Penjar dades de dies a les properties de la thing
    with open('Output_data/Irrigation_dates.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # TODO Llegir i parsejar a datetime
            early = row["Early"]
            late = row["Late"]
            limit = row["Limit"]

            url = st_url + "/FROST-Server/v1.1/Things?$filter=name eq '" + run_file["fieldTitle"] + "'";

            req = r.get(url)
            req_data = json.loads(req.text)

            properties = req_data["value"][0]["properties"]
            thingId = req_data["value"][0]["@iot.id"]

            properties["early"] = early
            properties["late"] = late
            properties["limit"] = limit

            url = st_url + f"/FROST-Server/v1.1/Things({thingId})"

            req = r.patch(url, {
                "properties": properties
            })
