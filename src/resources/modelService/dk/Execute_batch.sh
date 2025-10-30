#!/bin/sh

# Set the path to Vortex installation
echo Setting Vortex Home...
export VORTEX_HOME="/dk/requirements/vortex-0.10.20"
echo Vortex Home set to $VORTEX_HOME
export HMS_HOME="/dk/HEC-HMS-4.11-linux64/HEC-HMS-4.11"
export JAVA_LIB_PATH="$HMS_HOME/bin:$HMS_HOME/bin/gdal"
export PATH="$HMS_HOME/bin/taudem:$HMS_HOME/bin/mpi:$PATH"
export GDAL_DATA="$HMS_HOME/bin/gdal/gdal-data"
export PROJ_LIB="$HMS_HOME/bin/gdal/proj"
export LD_LIBRARY_PATH="$JAVA_LIB_PATH:$LD_LIBRARY_PATH"

# Set the path to Jython script
export SCRIPT_PATH="Execute.py"

if [ ! -d "$HMS_HOME" ]; then
  echo "Error: HMS_HOME no está disponible en la ruta $HMS_HOME"
  exit 1
fi

if [ ! -f "$HMS_HOME/jre/bin/java" ]; then
  echo "Error: java no encontrado en $HMS_HOME"
  exit 1
fi

# Running the script using the Jython interpreter from HEC-HMS
"$HMS_HOME/jre/bin/java"  -Djava.awt.headless=true -Djava.library.path="$JAVA_LIB_PATH" -Dsun.awt.fontconfig="$HMS_HOME/jre/lib/psfontj2d.properties" -cp "$HMS_HOME/hms.jar:$HMS_HOME/lib/*" org.python.util.jython -S $SCRIPT_PATH


# Check the exit status of the Java command
if [ $? -ne 0 ]; then
  echo "Script execution failed"
  exit 1  # Exit with -1 if there was an error
else
  echo "Script execution completed successfully"
  # Moure el fitxer a results
  mv /dk/HMS_Tirso_v2/ERA5_Land_2006_2022_v2.dss /dk/HMS_Tirso_v2/results/ERA5_Land_2006_2022_v2.dss
  sleep 3600
  exit 0  # Exit with 0 if successful
fi