import datetime
import glob

import hecdss
import netCDF4
import numpy as np
from hecdss import HecDss

translate_variable = {
    "tp": "TOTAL_PRECIPITATION",
    "d2m": "2M_DEWPOINT_TEMPERATURE"
}

translate_units = {
    "tp": "m",
    "d2m": "K"
}


def read_netcdf(variable_name, file_path):
    ncfile = netCDF4.Dataset(file_path, 'r')
    # print(ncfile.variables.keys()) ['number', 'forecast_reference_time', 'forecast_period', 'latitude', 'longitude', 'valid_time', 'tp']
    # print(ncfile.variables["tp"]) (50, 1, 45, 2, 3)

    now = datetime.datetime.now()
    year = now.year if now.month > 1 else now.year - 1
    month = now.month - 1 if now.month > 1 else 12
    init_date = datetime.datetime(year, month, 1)

    data = []

    variable = ncfile.variables[variable_name]
    for lat in range(2):
        for lon in range(3):
            print(lat, lon)
            v = variable[:, 0, :, lat, lon]

            data_row = {
                "latitude": lat + 39,
                "longitude": lon + 8,
                "variable": translate_variable[variable_name],
                "init_date": init_date.strftime("%Y-%m-%d"),
                "units": translate_units[variable_name]
            }
            values = []
            times = []
            for i in range(v.shape[1]):  # Forecast reference time
                total_ensemble_measure = 0
                for measure in v[:, i]:
                    total_ensemble_measure += measure
                average_ensemble_measure = total_ensemble_measure / len(v[:, i])
                values.append(average_ensemble_measure)
                if len(times) == 0:
                    times.append(init_date + datetime.timedelta(hours=6))
                else:
                    times.append(times[-1] + datetime.timedelta(hours=6))
            data_row["values"] = values
            data_row["times"] = times
            data.append(data_row)
    return data


def read_netcdf_reanalysis(variable_name, file_path):
    ncfile = netCDF4.Dataset(file_path, 'r')
    # print(ncfile.variables.keys()) ['number', 'valid_time', 'latitude', 'longitude', 'expver', 'tp']
    # print(ncfile.variables["tp"]) (120, 11, 21)

    init_date = datetime.datetime.now()

    data = []

    variable = ncfile.variables[variable_name]
    for lt, lat in enumerate(ncfile.variables['latitude']):
        for ln, lon in enumerate(ncfile.variables['longitude']):
            latitude = round(lat.data.item(), 1)
            longitude = round(lon.data.item(), 1)
            if not latitude.is_integer() or not longitude.is_integer():
                continue
            print(latitude, longitude)
            v = variable[:, lt, ln]

            print(v)

            data_row = {
                "latitude": int(latitude),
                "longitude": int(longitude),
                "variable": translate_variable[variable_name],
                "init_date": init_date.strftime("%Y-%m-%d"),
                "units": translate_units[variable_name]
            }
            values = []
            times = []
            t = ncfile.variables["valid_time"]
            for i, time in enumerate(t):  # Forecast reference time
                time_in_dt = datetime.datetime.utcfromtimestamp(time)
                val = v[i]
                values.append(val.__float__())
                times.append(time_in_dt)
            data_row["values"] = values
            data_row["times"] = times
            data.append(data_row)
    return data


def save_in_dss(file_path, data):
    # Open a DSS file
    with HecDss(file_path) as dss:
        for data_pack in data:
            data_path = f"/{data_pack['variable']}/{data_pack['latitude']}/{data_pack['longitude']}/{min(data_pack['times']).strftime('%Y-%m-%d')}/6Hour/"
            print(data_path)
            timeserie = hecdss.RegularTimeSeries()
            timeserie.times = data_pack['times']
            timeserie.values = np.array(data_pack['values'])
            timeserie.data_type = "PER-CUM"
            timeserie.start_date = min(data_pack['times'])
            timeserie.interval = 3600 * 6
            timeserie.units = data_pack['units']
            timeserie.id = data_path
            dss.put(timeserie)


def main():
    data_in_files = []

    for file in glob.glob("HMS_Tirso_v3/data/Precipitation/*_reanalysis.nc"):
        data_in_files.extend(read_netcdf_reanalysis("tp", file))

    data_in_files.extend(read_netcdf("tp", "HMS_Tirso_v3/data/Precipitation/precip_forecast.nc"))
    save_in_dss("HMS_Tirso_v3/data/ERA5_Land_P_current.dss", data_in_files)

    data_in_files = []

    for file in glob.glob("HMS_Tirso_v3/data/Temperature/*_reanalysis.nc"):
        data_in_files.extend(read_netcdf_reanalysis("d2m", file))

    data_in_files.extend(read_netcdf("d2m", "HMS_Tirso_v3/data/Temperature/dewt2m_forecast.nc"))
    save_in_dss("HMS_Tirso_v3/data/ERA5_Land_T_current.dss", data_in_files)


if __name__ in "__main__":
    main()
