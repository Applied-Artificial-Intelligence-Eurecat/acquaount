import os
import sys
import zipfile

import cdsapi
import requests.exceptions
import xarray as xr

client = cdsapi.Client()


def download_data(variable, save_path, file_prefix):
    year = sys.argv[1]
    month = sys.argv[2]

    product_types = ["monthly_mean",
                     "monthly_minimum",
                     "monthly_maximum"]

    for prodtype in product_types:
        dataset = "seasonal-monthly-single-levels"
        request = {
            "originating_centre": "ecmwf",
            "system": "51",
            "variable": [variable],
            "product_type": [
                prodtype
            ],
            "year": [year],
            "month": [month],
            "leadtime_month": [
                "1",
                "2",
                "3",
                "4",
                "5",
                "6"
            ],
            "data_format": "netcdf",
            "area": [40, 8, 39, 10],
        }

        try:
            client.retrieve(dataset, request, f"{save_path}{file_prefix}_SEASONAL_{prodtype}.nc")
        except requests.exceptions.HTTPError:
            print("The request has failed, skipping")


def concatenate_netcdf(directory, output_file):
    print("Concatenating ", directory)
    zip_files = [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith('.zip')]
    for file in zip_files:
        with zipfile.ZipFile(file, "r") as zipF:
            zipF.extractall(directory)
    netcdf_files = [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith('.nc')]
    netcdf_files.sort()
    combined_data = xr.concat([xr.open_dataset(f) for f in netcdf_files], dim='time')
    combined_data.to_netcdf(output_file)


# Paths for saving data
precipitation_path = '../data_test/Precipitation/'
temperature_path = '../data_test/Temperature/'

if not os.path.exists(precipitation_path):
    os.mkdir(precipitation_path)

if not os.path.exists(temperature_path):
    os.mkdir(temperature_path)

# Download Precipitation Data
download_data('total_precipitation', precipitation_path, 'precip')

# Download Temperature Data
download_data("2m_dewpoint_temperature", temperature_path, 'dewt2m')

concatenate_netcdf(temperature_path, f'{temperature_path}combined_forecast_temp.nc')
concatenate_netcdf(precipitation_path, f'{precipitation_path}combined_forecast_precip.nc')
