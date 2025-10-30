import json
import math
import sys

import requests

# baseurl = "http://backend.acquaount.development.abidevops.website/api/field-data/filtered?name="
# baseurl = "http://backend.acquaount.development.abidevops.website/api/field-data/filtered?name={username}&id_thing={thing_id}"
baseurl = "http://backend.acquaount.development.abidevops.website/api/field-data/filtered?id_thing="


r = requests.get(baseurl)


if __name__ in "__main__":
    if len(sys.argv) > 1:
        run_file = sys.argv[1]
    else:
        print("ERROR Run File Not Specified")
        sys.exit(-1)

    with open(sys.argv[1], "r") as run:
        run_data = json.loads(run.read())

    url = f"{baseurl}{run_data['id_thing']}"

    # with open("apikey.txt", "r") as f:
    with open("/apikey.txt", "r") as f:
        apikey = f.read().rstrip()

    config_values = {}

    headers = {
        "Authorization": f"Bearer {apikey}"
    }

    r = requests.get(url, headers=headers, data={})
    data = json.loads(r.text)
    for field in data['data']:
        if field['id_thing'] == run_data['id_thing']:
            print(field)
            config_values['crop_name'] = field['crop']['species']
            config_values['season_start'] = field['crop']['planting_date']
            config_values['season_end'] = field['crop']['expected_harvest_date']
            config_values['plant_spacing'] = field['crop']['distance_individuals']
            config_values['line_spacing'] = field['crop']['distance_line']
            config_values['kc_correction_filepath'] = "crop_data/kc_correction.csv"
            config_values['extremes_previous_run'] = "soil_moisture_data/SM_extremes_previous_run.csv"
            config_values['P_sand'] = field['soil_type']["sand"]
            config_values['P_clay'] = field['soil_type']["clay"]
            config_values['P_silt'] = field['soil_type']["silt"]
            config_values['P_om'] = field['soil_type']["organic_matter"]
            config_values['Ks'] = field['soil_type']["saturated_hydraulic_conductivity"]
            config_values['Pb'] = field['soil_type']["bulk_density"]
            config_values['soil_SAT_user'] = field['soil_type']["soil_porosity"]
            config_values['theta_fc_user'] = field['soil_type']["water_content_saturation"]
            config_values['theta_wp_user'] = field['soil_type']["permanent_wilting_point"]

            if field["soil_type"]["climate_zone"] == "Mediterranean":
                config_values['climate_zone'] = 1
            else:
                config_values['climate_zone'] = 2

            config_values['lat'] = int(math.floor(field["polygons"][0]["centroid"][0]))
            # TODO elevation
            config_values['elev'] = 8
            config_values['irr_method'] = field["irrigations_system"]["system"]

            # Linia 169 model
            if field["irrigations_system"]["system"] == "drip":
                config_values["n_drip_per_line"] = field["irrigations_system"]["number_dripping_pipes"]
                config_values["d_spacing"] = field["irrigations_system"]["spacing_dripping_bore"]
                config_values["d_rate"] = field["irrigations_system"]["d_rate"]
                config_values["w_length"] = field["irrigations_system"]["wetted_length"]
            elif field["irrigations_system"]["system"] == "sprinkler":
                config_values["n_emitter"] = field["irrigations_system"]["number"]
                config_values["s_rate"] = field["irrigations_system"]["s_rate"]
            elif field["irrigations_system"]["system"] == "suterranean":
                config_values["n_drip_per_line"] = field["irrigations_system"]["number_dripping_pipes"]
                config_values["d_depth"] = field["irrigations_system"]["dripping_depth"]
                config_values["d_spacing"] = field["irrigations_system"]["spacing_dripping_bore"]
                config_values["d_rate"] = field["irrigations_system"]["d_rate"]
                config_values["w_length"] = field["irrigations_system"]["wetted_length"]
            elif field["irrigations_system"]["system"] == "surface irrigation":
                config_values["w_distributed"] = ""
            break
    with open("/data/modelconfig.input.json", "w+") as f:
    # with open("/data/modelconfig.input.json", "w+") as f:
        f.write(json.dumps(config_values))
