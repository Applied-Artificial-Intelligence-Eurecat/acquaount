import os
import sys

import cdsapi
import xarray as xr


def download_data(variable, save_path, originating_centre,
                  system, leadtime_month, file_prefix):
    start_year = int(sys.argv[1])
    end_year = int(sys.argv[2])

    c = cdsapi.Client()

    for year in range(start_year, end_year + 1):
        for month in range(1, 13):
            target_file = f'{save_path}{file_prefix}_seasonal_{year}_{month:02d}.nc'
            if not os.path.exists(target_file):
                c.retrieve(
                    'seasonal-monthly-single-levels',
                    {
                        'originating_centre': originating_centre,
                        'system': system,
                        'variable': variable,
                        'product_type': [
                            'ensemble_mean',
                            'monthly_mean'
                        ],
                        'year': str(year),
                        'month': str(month).zfill(2),
                        'leadtime_month': leadtime_month,
                        'data_format': 'netcdf',
                    },
                    target_file
                )
            print(f"Downloaded {variable}: Year {year}, Month {month}")


def concatenate_netcdf(directory, output_file):
    netcdf_files = [os.path.join(directory, f) for f in os.listdir(directory) if f.endswith('.nc')]
    netcdf_files.sort()
    combined_data = xr.concat([xr.open_dataset(f) for f in netcdf_files], dim='time')
    combined_data.to_netcdf(output_file)


# Paths for saving data
precipitation_path = '../data_test/Precipitation/'
temperature_path = '../data_test/Temperature/'

# Download Precipitation Data
download_data('mean_total_precipitation_rate', precipitation_path, 'ecmwf', '51', ['1'], 'tprate')

# Download Temperature Data
download_data('2m_temperature', temperature_path, 'ecmwf', '51', ['1'], 't2m')

# Concatenate 
concatenate_netcdf(temperature_path, 'combined_forecast_temp.nc')
concatenate_netcdf(precipitation_path, 'combined_forecast_precip.nc')
