from datetime import datetime, timedelta

import requests


def get_function(specification):
    def get_data_from_ira_data():
        # DATA Authorization -----------------------------
        url = "https://data.ira.tn/api/ds/query"

        # En teoria no expira
        headers = {
            "Authorization": "Bearer eyJrIjoicTZkUlh6WkY4QTdVb3I3b2Vlc3JCZVFvRnZPVm8xR3IiLCJuIjoiQXBpIiwiaWQiOjF9",
            "Content-type": "application/json",
        }

        today_ts = int(datetime.now().timestamp())
        yesterday_ts = int((datetime.now() - timedelta(days=1)).timestamp())

        output_data = []

        for datastream_specification in specification["properties"]:
            querytext = f"""SELECT DATE_TIME AS "time",{datastream_specification['measureNumber']} FROM {datastream_specification['dataSource']} WHERE DATE_TIME BETWEEN FROM_UNIXTIME({yesterday_ts}) AND FROM_UNIXTIME({today_ts}) ORDER BY DATE_TIME"""

            data = {
                "queries": [
                    {
                        "refId": "A",
                        "datasource": {
                            "type": "mysql"
                        },
                        "datasourceId": specification['datasourceId'],
                        "rawSql": querytext,
                        "format": "table"
                    }
                ]
            }

            # Send the POST request
            response = requests.post(url, headers=headers, json=data)

            # Check for successful response
            if response.status_code == 200:
                panel_data = response.json()

                values = panel_data['results']['A']['frames'][0]['data']['values']
                timestamps = values[0]
                vals = values[1:]
                for i, value_list in enumerate(vals):
                    property_key = datastream_specification["propertyKey"]
                    for j, value in enumerate(value_list):
                        dt_string = datetime.fromtimestamp(timestamps[j] / 1000).strftime("%Y-%m-%dT%H:%M:%SZ")
                        measure = {
                            'info': {
                                'deviceID': datastream_specification["deviceID"],
                                'timestamp': dt_string
                            },
                            'values': {
                                property_key: value
                            }
                        }
                        output_data.append(measure)

        return output_data

    return get_data_from_ira_data


def get_historic_function(specification):
    def get_data_from_ira_data():
        # DATA Authorization -----------------------------
        url = "https://data.ira.tn/api/ds/query"

        # En teoria no expira
        headers = {
            "Authorization": "Bearer eyJrIjoicTZkUlh6WkY4QTdVb3I3b2Vlc3JCZVFvRnZPVm8xR3IiLCJuIjoiQXBpIiwiaWQiOjF9",
            "Content-type": "application/json",
        }

        today_ts = int(datetime.now().timestamp())
        years_ago_ts = int(datetime(2023, 1, 1, 00, 00, 1).timestamp())

        output_data = []

        for datastream_specification in specification["properties"]:
            querytext = f"""SELECT DATE_TIME AS "time",{datastream_specification['measureNumber']} FROM {datastream_specification['dataSource']} WHERE DATE_TIME BETWEEN FROM_UNIXTIME({years_ago_ts}) AND FROM_UNIXTIME({today_ts}) ORDER BY DATE_TIME"""

            data = {
                "queries": [
                    {
                        "refId": "A",
                        "datasource": {
                            "type": "mysql"
                        },
                        "datasourceId": specification["datasourceId"],
                        "rawSql": querytext,
                        "format": "table"
                    }
                ]
            }

            # Send the POST request
            response = requests.post(url, headers=headers, json=data)

            # Check for successful response
            if response.status_code == 200:
                panel_data = response.json()

                values = panel_data['results']['A']['frames'][0]['data']['values']
                timestamps = values[0]
                vals = values[1:]
                for i, value_list in enumerate(vals):
                    property_key = datastream_specification["propertyKey"]
                    for j, value in enumerate(value_list):
                        dt_string = datetime.fromtimestamp(timestamps[j] / 1000).strftime("%Y-%m-%dT%H:%M:%SZ")
                        measure = {
                            'info': {
                                'deviceID': datastream_specification["deviceID"],
                                'timestamp': dt_string
                            },
                            'values': {
                                property_key: value
                            }
                        }
                        output_data.append(measure)

        return output_data

    return get_data_from_ira_data


if __name__ in "__main__":
    print(get_function({
    "type": "Farm",
    "name": "Jomaa Dhibi",
    "title": "AcquaountJomaaDhibi",
    "datasourceId": 43,
    "properties": [
      {
        "deviceID": "TS033",
        "propertyKey": "water_flow",
        "dataSource": "ed_11976",
        "measureNumber": "MEAS_4"
      },
      {
        "deviceID": "TS042",
        "propertyKey": "water_flow",
        "dataSource": "ed_11974",
        "measureNumber": "MEAS_4"
      },
      {
        "deviceID": "TS09",
        "propertyKey": "soil_moisture_15cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_2"
      },
      {
        "deviceID": "TS09",
        "propertyKey": "soil_temperature_15cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_1"
      },
      {
        "deviceID": "TS10",
        "propertyKey": "soil_moisture_30cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_5"
      },
      {
        "deviceID": "TS10",
        "propertyKey": "soil_temperature_30cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_4"
      },
      {
        "deviceID": "TS11",
        "propertyKey": "soil_moisture_45cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_8"
      },
      {
        "deviceID": "TS11",
        "propertyKey": "soil_temperature_45cm",
        "dataSource": "ed_11180",
        "measureNumber": "MEAS_7"
      },
      {
        "deviceID": "TS12",
        "propertyKey": "soil_moisture_15cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_2"
      },
      {
        "deviceID": "TS12",
        "propertyKey": "soil_temperature_15cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_1"
      },
      {
        "deviceID": "TS13",
        "propertyKey": "soil_moisture_30cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_5"
      },
      {
        "deviceID": "TS13",
        "propertyKey": "soil_temperature_30cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_4"
      },
      {
        "deviceID": "TS14",
        "propertyKey": "soil_moisture_45cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_8"
      },
      {
        "deviceID": "TS14",
        "propertyKey": "soil_temperature_45cm",
        "dataSource": "ed_11954",
        "measureNumber": "MEAS_7"
      }
    ]
  })())
