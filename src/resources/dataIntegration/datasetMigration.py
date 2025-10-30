import json

import requests
from tqdm import tqdm

baseurl = "http://172.20.49.81"
uploadurl = baseurl + "/acquaounttriassicacquifer/actions/receiveMeasure"

thingsnames = ["SONEDE - Well Drilling 1", "SONEDE - Well Drilling 2", "SONEDE - Well Drilling 3",
               "SONEDE - Well Drilling 4", "SONEDE - Well Drilling 5", "SONEDE - Well Drilling 6", "DRW 1", "DRW 2",
               "WWQ 1", "WWQ 2"]
thingnames_links = ["acquaountsonedewelldrilling6",
                    "acquaountsonedewelldrilling5",
                    "acquaountsonedewelldrilling4",
                    "acquaountsonedewelldrilling3",
                    "acquaountsonedewelldrilling2",
                    "acquaountsonedewelldrilling1",
                    "acquaountdrw2",
                    "acquaountdrw1",
                    "acquaountwwq1",
                    "acquaountwwq2"]

if __name__ in "__main__":
    print("Hello world")

    r = requests.get(baseurl)

    things_list = r.text.replace("[", "").replace("]", "").replace("\"", "").split(",")
    for thing in things_list:
        thingname = thing.split("/")[-1]
        print(thingname)
        if thingname in thingnames_links:
            url = baseurl + "/" + thingname + "/properties/datastreamsList"

            r = requests.get(url)

            datastreams_list = json.loads(r.text)

            for datastream in datastreams_list:
                dname = datastream['name']
                print(dname)
                for n in thingsnames:
                    dname = dname.replace(n, "Tirso_Aquifer")

                for i in tqdm(range(20)):
                    data_r = requests.get(baseurl + "/" + thingname + f"/properties/datastreamMeasures?name={datastream['name']}&items=200&page={i}")

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
