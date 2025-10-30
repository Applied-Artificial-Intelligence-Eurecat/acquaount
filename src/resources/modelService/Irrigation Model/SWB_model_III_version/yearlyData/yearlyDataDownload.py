import calendar
import json
from datetime import datetime, timedelta

import numpy as np
import requests
import unicodecsv as csv
import urllib3
from hecdss import HecDss
from hecdss import irregular_timeseries
from tqdm import tqdm

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

end_time = datetime.now().strftime("%Y-%m-%dT00:00:00Z")
start_time = (datetime.now() - timedelta(days=365)).strftime("%Y-%m-%dT00:00:00Z")


def download_data(thing):
    return_data = []
    url = f"https://84.88.76.18/wot/{thing}/properties/datastreamsList"

    req = requests.get(url, verify=False)

    if req.status_code != 200:
        print(f"ERROR with thing {thing}")
        return []

    d = json.loads(req.text)

    for datastream in tqdm(d):
        datastream_name = datastream['name']

        baseurl = f"https://84.88.76.18/wot/{thing}/properties/datastreamTimeRangeMeasures?name={datastream_name}&&start_time={start_time}&end_time={end_time}&items=100&page="

        measures = []
        page = 0
        measures_num = 100

        while measures_num >= 100:
            url = baseurl + str(page)
            req = requests.get(url, verify=False)

            if req.status_code != 200:
                print("ERROR with REQ")
                measures = []
                break

            data = json.loads(req.text)

            measures_num = len(data)
            measures.extend(data)
            page += 1

        measures.reverse()
        if len(measures) > 0:
            return_data.append(measures)
        break
    return return_data


def save_in_dss(file_path, data, thing):
    # Open a DSS file
    with HecDss(file_path) as dss:
        for data_list in data:
            if len(data_list) == 0:
                continue

            p = data_list[0]
            first_month = datetime.strptime(p['time_of_measure'], "%Y-%m-%dT%H:%M:%SZ").month - 1
            all_values = [m['value'] for m in data_list]
            all_times = [datetime.strptime(m['time_of_measure'], "%Y-%m-%dT%H:%M:%SZ") for m in data_list]
            for month_number in range(12):
                month_actual = ((first_month + month_number) % 12) + 1
                month = calendar.month_name[month_actual]
                data_path = f"/{thing}/{p['datastream_name']}/{p['property_name']}/{p['deviceID']}/{month}/"
                timeserie = irregular_timeseries.IrregularTimeSeries()

                times = []
                values = []
                for i, time in enumerate(all_times):
                    if time.month == month_actual:
                        times.append(time)
                        values.append(all_values[i])

                timeserie.times = times
                timeserie.values = np.array(values)
                timeserie.data_type = "INST-CUM"
                timeserie.units = p['unit_of_measurement']
                timeserie.id = data_path
                dss.put(timeserie)


def save_in_csv(prefix, data):
    for data_list in data:
        if len(data_list) == 0:
            continue

        p = data_list[0]
        with open(f"{prefix}_{p['datastream_name']}.csv", 'wb+') as csvfile:
            writer = csv.writer(csvfile, delimiter=';', quotechar='|', quoting=csv.QUOTE_MINIMAL, encoding='utf-8')
            writer.writerow(
                ['Datastream Name', 'Device ID', 'Property Name', 'Time Of Measure', 'Value', 'Unit Of Measurement'])
            for measure in data_list:
                writer.writerow([str(measure['datastream_name']),
                                 str(measure['deviceID']),
                                 str(measure['property_name']),
                                 str(measure['time_of_measure']),
                                 str(measure['value']),
                                 str(measure['unit_of_measurement'])])


if __name__ in "__main__":
    things = []
    with open("things.txt", "r") as f:
        for line in [l.rstrip('\n') for l in f.readlines()]:
            things.append(line)

    for thing in things:
        data = download_data(thing)
        save_in_csv(f'CSV/{thing}', data)
        # save_in_dss(f'{thing}.dss', data, thing)
