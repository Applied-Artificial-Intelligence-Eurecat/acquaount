import datetime
import os

import cdsapi
import requests.exceptions

client = cdsapi.Client()


def download_forecast_data(variable, save_path, file_prefix):
    dt = datetime.datetime.now()

    year = dt.year if dt.month > 1 else dt.year - 1
    month = dt.month - 1 if dt.month > 1 else 12

    dataset = "seasonal-original-single-levels"
    request = {
        "originating_centre": "cmcc",
        "system": "35",
        "variable": [
            variable
        ],
        "year": [str(year)],
        "month": [f"{month:02d}"],
        "day": ["01"],
        "leadtime_hour": [str((i + 1) * 6) for i in range(180 * 4)],
        "data_format": "netcdf",
        "area": [40, 8, 39, 10]
    }

    try:
        client.retrieve(dataset, request, f"{save_path}{file_prefix}_forecast.nc")
    except requests.exceptions.HTTPError:
        print("The request has failed, skipping")


def download_reanalysis_data(variable, save_path, file_prefix, year, month):
    dataset = "reanalysis-era5-land"
    request = {
        "variable": [
            variable
        ],
        "year": str(year),
        "month": f"{month:02d}",
        "day": [
            "01", "02", "03",
            "04", "05", "06",
            "07", "08", "09",
            "10", "11", "12",
            "13", "14", "15",
            "16", "17", "18",
            "19", "20", "21",
            "22", "23", "24",
            "25", "26", "27",
            "28", "29", "30",
            "31"
        ],
        "time": [
            "00:00", "06:00", "12:00",
            "18:00"
        ],
        "data_format": "netcdf",
        "download_format": "unarchived",
        "area": [40, 8, 39, 10]
    }

    try:
        client.retrieve(dataset, request, f"{save_path}{file_prefix}_{year}_{month:02d}_reanalysis.nc")
    except requests.exceptions.HTTPError:
        print("The request has failed, skipping")


# Paths for saving data
precipitation_path = 'HMS_Tirso_v3/data/Precipitation/'
temperature_path = 'HMS_Tirso_v3/data/Temperature/'

if not os.path.exists(precipitation_path):
    os.mkdir(precipitation_path)

if not os.path.exists(temperature_path):
    os.mkdir(temperature_path)

dt = datetime.datetime.now()
if dt.month == 1:
    use_month = 12
else:
    use_month = dt.month - 1
if use_month > 9:  # month is later than september, use september for this year
    reanalysis_months = [9 + i for i in range(use_month - 9)]
    reanalysis_years = [dt.year for _ in range(use_month - 9)]
else:  # month is september or earlier, use last september
    reanalysis_months = []
    reanalysis_years = []
    if use_month == 9:
        r = range(12)
    else:
        r = range((use_month - 9) % 12)
    for i in r:
        new_month = 9 + i
        if new_month > 12:
            new_month = new_month % 12
            reanalysis_years.append(dt.year)
        else:
            reanalysis_years.append(dt.year - 1)
        reanalysis_months.append(new_month)

print(reanalysis_months)
print(reanalysis_years)
for i, month in enumerate(reanalysis_months):
    download_reanalysis_data("total_precipitation", precipitation_path, 'precip', reanalysis_years[i], month)
    download_reanalysis_data("2m_dewpoint_temperature", temperature_path, 'dewt2m', reanalysis_years[i], month)

# Download Precipitation Data
download_forecast_data('total_precipitation', precipitation_path, 'precip')
# Download Temperature Data
download_forecast_data("2m_dewpoint_temperature", temperature_path, 'dewt2m')
