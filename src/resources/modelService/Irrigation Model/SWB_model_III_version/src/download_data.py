import json
from datetime import datetime
import os

import numpy as np
import openmeteo_requests
import pandas as pd
import requests
import requests_cache
import urllib3
import sys

from retry_requests import retry

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def ensure_directory_exists(file_path):
    """Ensure the directory for a file exists, creating it if necessary."""
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        os.makedirs(directory)


def past_data(datastream_names, thing_title):
    # PAST DATA FROM PLATFORM

    for key in datastream_names.keys():
        if key == "SM":
            file_path = f"data/Input_data/soil_moisture_data/SM_past.csv"
            ensure_directory_exists(file_path)
            measures_matrix = []
            days = []
            hours = []

            for datastream in datastream_names[key]:
                days = []
                hours = []
                measures = []
                url = f"https://84.88.76.18/wot/{thing_title}/properties/datastreamMeasures?name={datastream}&items=72&page=0"

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

                try:
                    for i in range(np_matrix.shape[1]):
                        column = np_matrix[:, i]
                        f.write(" ".join([str(m) for m in column]) + "\n")
                except IndexError:
                    # print("WARNING: No soil moisture data available, creating empty file")
                    pass

            date_file = "data/Input_data/climate_data/date_past.csv"
            hour_file = "data/Input_data/climate_data/hour_past.csv"
            ensure_directory_exists(date_file)
            ensure_directory_exists(hour_file)
            
            with open(date_file, "w+") as f:
                f.write("\"x\"\n")
                for m in days:
                    f.write(f"\"{m}\"\n")
            with open(hour_file, "w+") as f:
                f.write("\"x\"\n")
                for m in hours:
                    f.write(f"{m}\n")
        else:
            if key == "water_flow":
                file_path = "data/Input_data/irrigation_data/water_flow_past.csv"
            else:
                file_path = f"data/Input_data/climate_data/{key}_past.csv"
            ensure_directory_exists(file_path)
            measures = []

            url = f"https://84.88.76.18/wot/{thing_title}/properties/datastreamMeasures?name={datastream_names[key]}&items=72&page=0"

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
    apikey_file = "weather-apikey.txt"
    ensure_directory_exists(apikey_file)
    
    with open(apikey_file) as f:
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
            file_path = f"/data/Input_data/climate_data/{key}_fut.csv"
            ensure_directory_exists(file_path)
            with open(file_path, 'w+') as f:
                f.write("\"x\"\n")
                for item in data[key]:
                    if type(item) == str:
                        f.write(f"\"{item}\"\n")
                    else:
                        f.write(f"{item}\n")


def future_data_openmeteo(latitude, longitude):
    # Set up the Open-Meteo API client with cache and retry on error
    cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
    retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
    openmeteo = openmeteo_requests.Client(session=retry_session)

    # Make sure all required weather variables are listed here
    # The order of variables in hourly or daily is important to assign them correctly below
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": 33.310748,
        "longitude": 10.35,
        "hourly": ["temperature_2m", "relative_humidity_2m", "precipitation", "wind_speed_80m", "direct_radiation"]
    }
    responses = openmeteo.weather_api(url, params=params)

    # Process first location. Add a for-loop for multiple locations or weather models
    response = responses[0]
    print(f"Coordinates {response.Latitude()}°N {response.Longitude()}°E")
    print(f"Elevation {response.Elevation()} m asl")
    print(f"Timezone {response.Timezone()} {response.TimezoneAbbreviation()}")
    print(f"Timezone difference to GMT+0 {response.UtcOffsetSeconds()} s")

    # Process hourly data. The order of variables needs to be the same as requested.
    hourly = response.Hourly()
    hourly_temperature_2m = hourly.Variables(0).ValuesAsNumpy()
    hourly_relative_humidity_2m = hourly.Variables(1).ValuesAsNumpy()
    hourly_precipitation = hourly.Variables(2).ValuesAsNumpy()
    hourly_wind_speed_80m = hourly.Variables(3).ValuesAsNumpy()
    hourly_direct_radiation = hourly.Variables(4).ValuesAsNumpy()

    hourly_data = {
        "date": pd.date_range(start=pd.to_datetime(hourly.Time(), unit="s", utc=True),
                              end=pd.to_datetime(hourly.TimeEnd(), unit="s", utc=True),
                              freq=pd.Timedelta(seconds=hourly.Interval()),
                              inclusive="left"),
        "temperature": hourly_temperature_2m,
        "humidity": hourly_relative_humidity_2m,
        "precipitation": hourly_precipitation,
        "wind_speed": hourly_wind_speed_80m,
        "solar_rad": hourly_direct_radiation
    }

    hourly_dataframe = pd.DataFrame(data=hourly_data)
    print(hourly_dataframe)

    data = {
        'date': [],
        'hour': [],
        'humidity': [],
        'precipitation': [],
        'solar_rad': [],
        'temperature': [],
        'wind_speed': []
    }

    for index, row in hourly_dataframe.iterrows():
        print(row)
        date_dt = row["date"].to_pydatetime()
        data["date"].append(date_dt.strftime("%Y-%m-%d"))
        data["hour"].append(date_dt.strftime("%H"))
        data["humidity"].append(row["humidity"])
        data["temperature"].append(row["temperature"])
        data["precipitation"].append(row["precipitation"])
        data["wind_speed"].append(row["wind_speed"])
        data["solar_rad"].append(row["solar_rad"])

    for key in data.keys():
        file_path = f"data/Input_data/climate_data/{key}_fut.csv"
        ensure_directory_exists(file_path)
        with open(file_path, 'w+') as f:
            f.write("\"x\"\n")
            for item in data[key]:
                if type(item) == str:
                    f.write(f"\"{item}\"\n")
                else:
                    f.write(f"{item}\n")


def find_datastream_names(field_title):
    datastreams_url = f"https://84.88.76.18/wot/{field_title}/properties/datastreamsList"
    req = requests.get(datastreams_url, verify=False)
    resp = json.loads(req.text)

    datastream_names = {}

    for datastream in resp:
        if datastream['observed_property'] == "rain_intensity" or datastream['observed_property'] == "precipitation":
            datastream_names['precipitation'] = datastream['name']
        if datastream['observed_property'] == "air_humidity":
            datastream_names['humidity'] = datastream['name']
        if datastream['observed_property'] == "solar_radiation":
            datastream_names['solar_rad'] = datastream['name']
        if datastream['observed_property'] == "temperature":
            datastream_names['temperature'] = datastream['name']
        if datastream['observed_property'] == "wind_speed":
            datastream_names['wind_speed'] = datastream['name']
        if datastream['observed_property'] == "water_flow":
            datastream_names['water_flow'] = datastream['name']

    datastream_names['SM'] = []
    for key in ['soil_moisture_10cm', 'soil_moisture_20cm', 'soil_moisture_30cm']:
        for datastream in resp:
            if datastream['observed_property'] == key:
                datastream_names['SM'].append(datastream['name'])
                break

    return datastream_names


if __name__ in "__main__":
    with open(sys.argv[1], 'r') as f:
        run_info = json.loads(f.read())
    fieldTitle = run_info["fieldTitle"]

    datastream_names = find_datastream_names(fieldTitle)

    past_data(datastream_names, fieldTitle)
    future_data()
