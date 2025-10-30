from datetime import datetime, timedelta

from netCDF4 import Dataset
from pydsstools import DSSFile

# Input and Output file paths
input_file = '/data/Precipitation/precip_SEASONAL_monthly_mean.nc'  # Replace with your NETCDF file path
output_file = '/data_test/Precipitation/output.dss'  # Replace with your desired HEC-DSS file path

# Open the NETCDF file
nc_file = Dataset(input_file, mode='r')

# Inspect the file structure
print("Variables in the NETCDF file:", nc_file.variables.keys())

# Assuming the file contains a variable like 'precipitation'
# You may need to replace this with the correct variable name
variable_name = 'tprate'  # Replace with the actual variable name from the NETCDF file
forecast_month_var = 'forecastMonth'  # Replace with the actual variable name for forecast month if different

data_variable = nc_file.variables[variable_name]
latitudes = nc_file.variables['latitude'][:]
longitudes = nc_file.variables['longitude'][:]
time = nc_file.variables['time'][:]
forecast_month = nc_file.variables[forecast_month_var][:]

# Extract data and metadata
precip_data = data_variable[:]
time_units = nc_file.variables['time'].units
forecast_start_date = datetime.strptime(time_units.split('since ')[1], "%Y-%m-%d %H:%M:%S")
current_date = datetime.now()

# Create DSS file
with DSSFile(output_file) as dss:
    for t_idx, time_value in enumerate(time):
        # Loop through time slices (e.g., monthly data)
        precip_slice = precip_data[t_idx, :, :]

        # Calculate the forecast date
        forecast_offset = int(forecast_month[t_idx])
        forecast_date = current_date + timedelta(days=30 * forecast_offset)  # Approximate monthly offset
        forecast_date_str = forecast_date.strftime("%d%b%Y").upper()

        # Metadata for DSS pathname
        pathname = f"/BASIN/LOCATION/{variable_name.upper()}/{forecast_date_str}/1MONTH/FORECAST/"

        # Write data to DSS
        dss.write_grid(
            grid_data=precip_slice,
            pathname=pathname,
            grid_info={
                'type': 'HRAP',
                'rows': precip_slice.shape[0],
                'columns': precip_slice.shape[1],
                'x_origin': longitudes.min(),
                'y_origin': latitudes.max(),
                'cell_size': (latitudes[1] - latitudes[0]),
            }
        )

# Close NETCDF file
nc_file.close()

print("Conversion to HEC-DSS format complete. File saved at:", output_file)
