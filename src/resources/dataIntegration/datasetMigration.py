import json

import requests
import tqdm

baseurl = "http://172.20.49.81"
uploadurl = baseurl + "/acquaounttirsoaquifer/actions/receiveMeasure"

thingsnames = ["Well_N8_Arborea", "Well_N10_Arborea", "Well_178_Santa_Giusta"]

if __name__ in "__main__":
    print("Hello world")

    r = requests.get(baseurl)

    things_list = r.text.replace("[", "").replace("]", "").replace("\"", "").split(",")
    for thing in things_list:
        if "well_" in thing:
            print(thing)
            url = baseurl + "/" + thing.split("/")[-1] + "/properties/datastreamsList"

            r = requests.get(url)

            datastreams_list = json.loads(r.text)

            for datastream in datastreams_list:
                dname = datastream['name']
                print(dname)
                for n in thingsnames:
                    dname = dname.replace(n, "Tirso_Aquifer")

                for i in tqdm.tqdm(range(20)):
                    data_r = requests.get(baseurl + "/" + thing.split("/")[
                        -1] + f"/properties/datastreamMeasures?name={datastream['name']}&items=200&page={i}")

                    datastream_data = json.loads(data_r.text)
                    for measure in datastream_data:
                        measure_packet = {
                            'info': {
                                'deviceID': measure['deviceID'],
                                'timestamp': measure['time_of_measure']
                            },
                            'values': {
                                measure['property_name']: measure['value']
                            }
                        }
                        payload = json.dumps(measure_packet)
                        headers = {
                            'Content-Type': 'application/json'
                        }

                        response = requests.request("POST", uploadurl, headers=headers, data=payload)
                        if response.status_code != 200:
                            print(response.status_code)
                            break
