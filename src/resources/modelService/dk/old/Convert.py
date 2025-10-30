from java.time import LocalDate
from java.time.format import DateTimeFormatter
from java.util import ArrayList, HashMap
from java.util import Locale
from mil.army.usace.hec.vortex.io import BatchImporter

#
in_files = ArrayList()
in_files.add("data_test/ERA5_Land_Precip.nc")

variables = ArrayList()
variables.add("tprate")

# clip_shp = "D:\\CMCC\\HECHMS_AUTOMATION\\HMS\\basin_Tirso.shp"
print("Test running")

start_date = LocalDate.of(2024, 12, 1)
end_date = LocalDate.of(2025, 6, 1)
current_date = start_date

wkt_string = "PROJCS[\"WGS_1984_UTM_Zone_32N\",GEOGCS[\"GCS_WGS_1984\",DATUM[\"D_WGS_1984\",SPHEROID[\"WGS_1984\",6378137.0,298.257223563]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"False_Easting\",500000.0],PARAMETER[\"False_Northing\",0.0],PARAMETER[\"Central_Meridian\",9.0],PARAMETER[\"Scale_Factor\",0.9996],PARAMETER[\"Latitude_Of_Origin\",0.0],UNIT[\"Meter\",1.0]]"

destination = "data_test/test.dss"

while not current_date.isAfter(end_date):
    formatter = DateTimeFormatter.ofPattern("ddMMMyyyy", Locale.ENGLISH)
    date_formatted = current_date.format(formatter).upper()

    importer_builder = BatchImporter.builder() \
        .inFiles(in_files) \
        .variables(variables) \
        .destination(destination)

    geo_options = HashMap()
    # geo_options.put("pathToShp", clip_shp)
    geo_options.put("targetCellSize", "1000")
    geo_options.put("targetWkt", wkt_string)
    geo_options.put("resamplingMethod", "Bilinear")
    importer_builder.geoOptions(geo_options)

    write_options = HashMap()
    write_options.put("partF", "PRECIPIT")
    write_options.put("dataType", "PER-CUM")
    write_options.put("units", "MM")
    write_options.put("partA", "UTM32N")
    write_options.put("partB", "TIRSO")
    write_options.put("partC", "PRECIPITATION")
    write_options.put("partD", date_formatted + ":0000")
    write_options.put("partE", date_formatted + ":2400")
    importer_builder.writeOptions(write_options)

    batch_importer = importer_builder.build()
    batch_importer.process()

    current_date = current_date.plusDays(1)
