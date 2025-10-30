import json
import sys
from datetime import datetime

import numpy as np
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def past_data():
    # PAST DATA FROM PLATFORM
    datastream_names = {
        'precipitation': "Noureddine_Rojbani_TS02_rain_intensity",
        'humidity': "Noureddine_Rojbani_TS01_air_humidity",
        'solar_rad': "Noureddine_Rojbani_TS01_solar_radiation",
        'temperature': "Noureddine_Rojbani_TS01_temperature",
        'wind_speed': "Noureddine_Rojbani_TS01_wind_speed",
        'water_flow': "Noureddine_Rojbani_TS027_water_flow",
        'SM': [
            "Noureddine_Rojbani_TS06_soil_moisture_10cm",
            "Noureddine_Rojbani_TS07_soil_moisture_20cm",
            "Noureddine_Rojbani_TS08_soil_moisture_30cm"
        ]
    }

    for key in datastream_names.keys():
        if key == "SM":
            file_path = f"data/Input_data/soil_moisture_data/SM.csv"
            measures_matrix = []
            days = []
            hours = []

            for datastream in datastream_names[key]:
                days = []
                hours = []
                measures = []
                url = f"https://84.88.76.18/wot/acquaountnoureddinerojbani/properties/datastreamMeasures?name={datastream}&items=72&page=0"

                response = requests.request("GET", url, headers={}, data={}, verify=False)

                response_data = json.loads(response.text)

                for measure in response_data[::-1]:
                    measures.append(float(measure["value"]))
                    date_format = "%Y-%m-%dT%H:%M:%SZ"
                    dt_object = datetime.strptime(measure["time_of_measure"].strip("\""), date_format)
                    days.append(dt_object.strftime("%Y-%m-%d"))
                    hours.append(dt_object.strftime("%H"))

                measures_matrix.append(measures[:])

            with open(file_path, "w+") as f:
                f.write("\"SM_10cm\" \"SM_20cm\" \"SM_30cm\"\n")
                np_matrix = np.array(measures_matrix)

                for i in range(np_matrix.shape[1]):
                    column = np_matrix[:, i]
                    f.write(" ".join([str(m) for m in column]) + "\n")

            with open("data/Input_data/climate_data/date.csv", "w+") as f:
                f.write("\"x\"\n")
                for m in days:
                    f.write(f"\"{m}\"\n")
            with open("data/Input_data/climate_data/hour.csv", "w+") as f:
                f.write("\"x\"\n")
                for m in hours:
                    f.write(f"{m}\n")
        else:
            if key == "water_flow":
                file_path = "data/Input_data/irrigation_data/water_flow.csv"
            else:
                file_path = f"data/Input_data/climate_data/{key}.csv"
            measures = []

            url = f"https://84.88.76.18/wot/acquaountnoureddinerojbani/properties/datastreamMeasures?name={datastream_names[key]}&items=72&page=0"

            response = requests.request("GET", url, headers={}, data={}, verify=False)

            response_data = json.loads(response.text)

            for measure in response_data[::-1]:
                measures.append(float(measure["value"]))

            with open(file_path, "w+") as f:
                f.write("\"x\"\n")
                for m in measures:
                    f.write(f"{m}\n")


def future_data():
    # FUTURE DATA FROM WEATHERAPI 3 DAYS
    with open("data/Input_data/apikey.txt") as f:
        apikey = f.read().strip()

    url = "https://api.weatherapi.com/v1/forecast.json"

    response = requests.request("GET", url, headers={}, data={}, params={
        'key': apikey,
        'q': '33.310748,10.350577',
        'days': 3
    }, verify=False)

    if response.status_code == 200:
        jsondata = json.loads(response.text)

        data = {
            'date': [],
            'hour': [],
            'humidity': [],
            'precipitation': [],
            'solar_rad': [],
            'temperature': [],
            'wind_speed': []
        }

        data_keys = {
            'humidity': 'humidity',
            'precipitation': 'precip_mm',
            'solar_rad': 'uv',
            'temperature': 'temp_c',
            'wind_speed': 'wind_kph'
        }

        for forecastday in jsondata["forecast"]["forecastday"]:
            for forecasthour in forecastday["hour"]:
                data['date'].append(forecastday["date"])
                date_format = "%Y-%m-%d %H:%M"
                dt_object = datetime.strptime(forecasthour["time"], date_format)
                data['hour'].append(int(dt_object.strftime("%H")))

                for key in data_keys.keys():
                    data[key].append(forecasthour[data_keys[key]])

        for key in data:
            with open(f"data/Input_data/climate_data/{key}_fut.csv", 'w+') as f:
                f.write("\"x\"\n")
                for item in data[key]:
                    if type(item) == str:
                        f.write(f"\"{item}\"\n")
                    else:
                        f.write(f"{item}\n")


if __name__ in "__main__":
    print(sys.argv)
    past_data()
    future_data()
