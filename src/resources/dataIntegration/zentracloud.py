import json
import math
import time
from datetime import datetime, timedelta

import requests as r


def get_function(deviceID):
    def get_data_from_zentracloud():
        current_utc_time = datetime.utcnow()
        today_time = current_utc_time.strftime("%m-%d-%Y %H:%M")

        yesterday_utc_time = current_utc_time - timedelta(days=1)
        yesterday_time = yesterday_utc_time.strftime("%m-%d-%Y %H:%M")

        output_data = []

        time.sleep(61)
        # for deviceID in ['z6-19947', 'z6-19948']:
        req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
            'device_sn': deviceID,
            'start_date': yesterday_time,
            'end_date': today_time,
            'page_num': 1,
            'per_page': 2000,
            'sort_by': 'ascending'
        }, headers={
            # TODO Fer aixo secret
            'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
        })
        while req.status_code != 200:
            time.sleep(61)
            req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
                'device_sn': deviceID,
                'start_date': yesterday_time,
                'end_date': today_time,
                'page_num': 1,
                'per_page': 2000,
                'sort_by': 'ascending'
            }, headers={
                # TODO Fer aixo secret
                'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
            })
        data = json.loads(req.text)["data"]
        for key in data:
            readings = data[key][0]['readings']
            for reading in readings:
                dt = datetime.utcfromtimestamp(reading['timestamp_utc'])
                formatted_timestamp = dt.strftime("%Y-%m-%dT%H:%M:%SZ")
                measure = {
                    'info': {
                        'deviceID': deviceID,
                        'timestamp': formatted_timestamp
                    },
                    'values': {
                        key: reading['value']
                    }
                }
                output_data.append(measure)
        return output_data

    return get_data_from_zentracloud


def get_historic_function(deviceID, jobName):
    def get_historic_from_zentracloud():
        output_data = []

        time.sleep(61)
        req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
            'device_sn': deviceID,
            'page_num': 1,
            'per_page': 1,
            'sort_by': 'ascending'
        }, headers={
            # TODO Fer aixo secret
            'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
        })
        print(f"{jobName}: {req.status_code}")
        while req.status_code != 200:
            time.sleep(61)
            req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
                'device_sn': deviceID,
                'page_num': 1,
                'per_page': 1,
                'sort_by': 'ascending'
            }, headers={
                # TODO Fer aixo secret
                'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
            })
            print(f"{jobName}: {req.status_code}")
        measures_num = int(json.loads(req.text)["pagination"]["max_mrid"])
        print(f"{jobName}: Need {math.ceil(measures_num / 2000)} requests")
        for i in range(math.ceil(measures_num / 2000)):
            # La API nomes deixa fer calls cada minut
            time.sleep(61)
            # for deviceID in ['z6-19947', 'z6-19948']:
            req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
                'device_sn': deviceID,
                'page_num': i + 1,
                'per_page': 2000,
                'sort_by': 'ascending'
            }, headers={
                # TODO Fer aixo secret
                'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
            })
            print(f"{jobName}: {req.status_code}")
            while req.status_code != 200:
                time.sleep(61)
                req = r.get("https://zentracloud.com/api/v4/get_readings/", params={
                    'device_sn': deviceID,
                    'page_num': i + 1,
                    'per_page': 2000,
                    'sort_by': 'ascending'
                }, headers={
                    # TODO Fer aixo secret
                    'Authorization': 'Token c9429f0942bf6363c40c9d90d48c08cb21005c48'
                })
                print(f"{jobName}: {req.status_code}")
            data = json.loads(req.text)["data"]
            for key in data:
                readings = data[key][0]['readings']
                for reading in readings:
                    dt = datetime.utcfromtimestamp(reading['timestamp_utc'])
                    formatted_timestamp = dt.strftime("%Y-%m-%dT%H:%M:%SZ")
                    measure = {
                        'info': {
                            'deviceID': deviceID,
                            'timestamp': formatted_timestamp
                        },
                        'values': {
                            key: reading['value']
                        }
                    }
                    output_data.append(measure)
        return output_data

    return get_historic_from_zentracloud


if __name__ in "__main__":
    # func = get_function('z6-19947')
    # print(func())
    print(get_historic_function('z6-19947'))
