import os
import sys

import cdsapi
import xarray as xr


def download_data(variable, save_path, time, file_prefix):
    start_year = int(sys.argv[1])
    end_year = int(sys.argv[2])

    c = cdsapi.Client()

    for year in range(start_year, end_year + 1):
        for month in range(1, 13):
            c.retrieve(
                'reanalysis-era5-land',
                {
                    'variable': variable,
                    'year': str(year),
                    'month': str(month).zfill(2),
                    'day': [
                        '01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
                        '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
                        '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31',
                    ],
                    'time': time,
                    'data_format': 'netcdf',
                },
                f'{save_path}{file_prefix}_ERA5-Land_{year}_{month:02d}.nc'
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

if not os.path.exists(precipitation_path):
    os.mkdir(precipitation_path)

if not os.path.exists(temperature_path):
    os.mkdir(temperature_path)

# Download Precipitation Data
download_data('total_precipitation', precipitation_path, ['00:00'], 'precip')

# Download Temperature Data
download_data('2m_dewpoint_temperature', temperature_path, [
    '00:00', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00',
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
    '21:00', '22:00', '23:00'], 'dewt2m')

# Concatenate Temperature Data
concatenate_netcdf(temperature_path, 'data_test/ERA5_Land_Temp.nc')
concatenate_netcdf(precipitation_path, 'data_test/ERA5_Land_Precip.nc')
