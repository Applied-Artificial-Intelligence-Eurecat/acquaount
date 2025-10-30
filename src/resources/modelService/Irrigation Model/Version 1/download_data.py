import json

import requests
import urllib3
import numpy as np
from datetime import datetime

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

if __name__ in "__main__":
    datastream_names = {
        'precipitation': "Noureddine_Rojbani_TS02_rain_intensity",
        'rel_hum': "Noureddine_Rojbani_TS01_air_humidity",
        'SW_rad': "Noureddine_Rojbani_TS01_solar_radiation",
        'temperature': "Noureddine_Rojbani_TS01_temperature",
        'wind_sp': "Noureddine_Rojbani_TS01_wind_speed",
        'irr_given': "Noureddine_Rojbani_TS027_water_flow",
        'soil_moisture': [
            "Noureddine_Rojbani_TS03_soil_moisture_10cm",
            "Noureddine_Rojbani_TS04_soil_moisture_20cm",
            "Noureddine_Rojbani_TS05_soil_moisture_30cm",
            "Noureddine_Rojbani_TS06_soil_moisture_10cm",
            "Noureddine_Rojbani_TS07_soil_moisture_20cm",
            "Noureddine_Rojbani_TS08_soil_moisture_30cm",
        ]
    }

    for key in datastream_names.keys():
        if key == "soil_moisture":
            file_path = f"data/Input_data/soil_moisture_data/soil_moisture.csv"
            measures_matrix = []
            days = []
            hours = []

            for datastream in datastream_names[key]:
                days = []
                hours = []
                measures = []
                url = f"https://84.88.76.18/wot/acquaountnoureddinerojbani/properties/datastreamMeasures?name={datastream}&items=96&page=0"

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
                f.write("Soil_1;Soil_2;Soil_3;Soil_4;Soil_5;Soil_6\n")
                np_matrix = np.array(measures_matrix)

                for i in range(np_matrix.shape[1]):
                    column = np_matrix[:, i]
                    f.write(";".join([str(m) for m in column]) + "\n")

            with open("data/Input_data/climate_data/date.csv", "w+") as f:
                for m in days:
                    f.write(f"{m}\n")
            with open("data/Input_data/climate_data/hour.csv", "w+") as f:
                for m in hours:
                    f.write(f"{m}\n")
        else:
            if key == "irr_given":
                file_path = "data/Input_data/irrigation_data/irr_given.csv"
            else:
                file_path = f"data/Input_data/climate_data/{key}.csv"
            measures = []

            url = f"https://84.88.76.18/wot/acquaountnoureddinerojbani/properties/datastreamMeasures?name={datastream_names[key]}&items=96&page=0"

            response = requests.request("GET", url, headers={}, data={}, verify=False)

            response_data = json.loads(response.text)

            for measure in response_data[::-1]:
                measures.append(float(measure["value"]))

            with open(file_path, "w+") as f:
                for m in measures:
                    f.write(f"{m}\n")
