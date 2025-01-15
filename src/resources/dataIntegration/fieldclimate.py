import json
import time
from datetime import datetime, timedelta

import requests
from Crypto.Hash import HMAC
from Crypto.Hash import SHA256
from requests.auth import AuthBase


class AuthHmacMetos(AuthBase):
    """Creates HMAC authorization header for Metos REST service POST request."""

    def __init__(self, apiRoute, publicKey, privateKey, method):
        self._publicKey = publicKey
        self._privateKey = privateKey
        self._method = method
        self._apiRoute = apiRoute

    def __call__(self, request):
        dateStamp = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')  # 'Mon, 23 Jul 2018 13:24:09 GMT'#
        request.headers['Date'] = dateStamp
        msg = (self._method + self._apiRoute + dateStamp + self._publicKey).encode(encoding='utf-8')
        h = HMAC.new(self._privateKey.encode(encoding='utf-8'), msg, SHA256)
        signature = h.hexdigest()
        authorizationStr = 'hmac ' + self._publicKey + ':' + signature
        request.headers['Authorization'] = authorizationStr
        return request


class FcApi:
    """Sets API endpoint URL for GET"""

    def __init__(self, apiUri, publicKey, privateKey):
        self._apiUri = apiUri
        self._publicKey = publicKey
        self._privateKey = privateKey

    def __checkStatus(self, response, auth, route):
        response.close()
        # print(" > {} {}".format(auth._method, self._apiUri + route))
        if response.status_code != 200:
            # print(" > {} {}".format(response.status_code, response.reason))
            pass

    def get(self, route):
        # remove parameters from the route for signature calculation
        auth = AuthHmacMetos(route.split('?', 1)[0], self._publicKey, self._privateKey, 'GET')
        response = requests.get(self._apiUri + route, headers={'Accept': 'application/json'}, auth=auth)
        response.close()
        self.__checkStatus(response, auth, route)
        return response


class FieldClimateConnector:
    API_URL = 'https://api.fieldclimate.com/v2'

    def __init__(self, public_key: str, private_key: str):
        self.__api = FcApi(self.API_URL, public_key, private_key)

    def get_data_hourly(self, station_id, from_timestamp, to_timestamp):
        return self.__api.get(f"/data/{station_id}/raw/from/{from_timestamp}/to/{to_timestamp}")

    def get_min_and_max_time(self, station_id):
        return self.__api.get(f"/data/{station_id}")


def get_function(station_id):
    def get_data_from_field_climate():
        # TODO make this secret
        public_key = "b3dfa3f2b868a5cdc76429abcb4064415be36f8bad19fbea"
        private_key = "4884f7544e08a7646b513dee6469dad5932c69ca43b9e85c"

        connector = FieldClimateConnector(public_key, private_key)

        today = int(datetime.utcnow().timestamp())
        yesterday = int((datetime.utcnow() - timedelta(days=1)).timestamp())

        print(yesterday, today)
        try:
            had_success = False
            while not had_success:
                try:
                    data = json.loads(
                        connector.get_data_hourly(station_id, yesterday, today).content.decode(encoding='utf-8'))
                    had_success = True
                except requests.exceptions.ConnectionError:
                    print("Requests error")
                    time.sleep(10)
        except json.decoder.JSONDecodeError:
            print("Json decoder error")
            return []
        try:
            if data["message"] == "No API client license found":
                return []
        except KeyError:
            pass
        formatted_timestamps = []
        output_data = []
        for date in data["dates"]:
            date_format = "%Y-%m-%d %H:%M:%S"
            dt_object = datetime.strptime(date, date_format)
            formatted_timestamps.append(dt_object.strftime("%Y-%m-%dT%H:%M:%SZ"))
        for datastream in data["data"]:
            print(datastream)
            if datastream["type"] == "Sensor":
                for aggr in datastream["aggr"]:
                    for i, value in enumerate(datastream["values"][aggr]):
                        measure = {
                            'info': {
                                'deviceID': station_id,
                                'timestamp': formatted_timestamps[i]
                            },
                            'values': {
                                datastream["name"] + " " + aggr: value
                            }
                        }
                        output_data.append(measure)
            else:
                for i, value in enumerate(datastream["values"]["result"]):
                    measure = {
                        'info': {
                            'deviceID': station_id,
                            'timestamp': formatted_timestamps[i]
                        },
                        'values': {
                            datastream["name"]: value
                        }
                    }
                    output_data.append(measure)
        return output_data

    return get_data_from_field_climate


def get_historic_function(station_id):
    def get_historic_from_field_climate():
        # TODO make this secret
        public_key = "b3dfa3f2b868a5cdc76429abcb4064415be36f8bad19fbea"
        private_key = "4884f7544e08a7646b513dee6469dad5932c69ca43b9e85c"

        connector = FieldClimateConnector(public_key, private_key)

        times = json.loads(connector.get_min_and_max_time(station_id).content.decode('utf-8'))

        date_format = "%Y-%m-%d %H:%M:%S"
        start_dt = datetime.strptime(times['min_date'], date_format)
        end_dt = datetime.strptime(times['max_date'], date_format)

        times = [int(start_dt.timestamp())]
        current_t = times[0]
        end_ts = int(end_dt.timestamp())
        while current_t < end_dt.timestamp():
            new_t = int(current_t + (24 * 3600 * 6))
            if new_t > end_ts:
                times.append(end_ts)
                break
            else:
                times.append(new_t)
                current_t = new_t

        output_data = []
        for ti, time_v in enumerate(times[:-1]):
            try:
                had_success = False
                while not had_success:
                    try:
                        data = json.loads(
                            connector.get_data_hourly(station_id, time_v, times[ti + 1]).content.decode(encoding='utf-8'))
                        had_success = True
                    except requests.exceptions.ConnectionError:
                        time.sleep(10)
            except json.decoder.JSONDecodeError:
                return []
            formatted_timestamps = []
            for date in data["dates"]:
                dt_object = datetime.strptime(date, date_format)
                formatted_timestamps.append(dt_object.strftime("%Y-%m-%dT%H:%M:%SZ"))
            for datastream in data["data"]:
                if datastream["type"] == "Sensor":
                    for aggr in datastream["aggr"]:
                        for i, value in enumerate(datastream["values"][aggr]):
                            measure = {
                                'info': {
                                    'deviceID': station_id,
                                    'timestamp': formatted_timestamps[i]
                                },
                                'values': {
                                    datastream["name"] + " " + aggr: value
                                }
                            }
                            output_data.append(measure)
                else:
                    for i, value in enumerate(datastream["values"]["result"]):
                        measure = {
                            'info': {
                                'deviceID': station_id,
                                'timestamp': formatted_timestamps[i]
                            },
                            'values': {
                                datastream["name"]: value
                            }
                        }
                        output_data.append(measure)
        return output_data
    return get_historic_from_field_climate


if __name__ in "__main__":
    station_ids = [
        "000008D6",
        "000008DD",
        "000008E0",
        "000008E4",
        "000008E5",
        "000008F7",
        "000010CC",
        "00001896",
        "000025BD",
        "00204B21",
        "00204EA1",
        "00204EB1"
    ]
    for station in station_ids:
        print(station.center(30, "="))
        get_function(station)()
        print("=" * 30)
