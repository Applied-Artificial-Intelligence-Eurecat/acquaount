#!/bin/sh

python3 DownloadSinglesForecast.py

if [ $? -ne 0 ]; then
  echo "Download execution failed"
  sleep 3600
  exit 1  # Exit with -1 if there was an error
else
  echo "Download execution completed successfully"
fi

python3 ConvertAlternative.py

# "$JYTHON_HOME/bin/jython" -J-Xmx2g -Djava.library.path="$VORTEX_HOME/bin;$VORTEX_HOME/bin/gdal" Convert.py
# python3 Convert2.py
# Check the exit status of the Java command
if [ $? -ne 0 ]; then
  echo "Convert execution failed"
  sleep 3600
  exit 1  # Exit with -1 if there was an error
else
  echo "Convert execution completed successfully"
fi

# Set the path to Vortex installation
export HMS_HOME="/dk/requirements/HEC-HMS-4.11-linux64/HEC-HMS-4.11"
export JYTHON_HOME="/dk/requirements/jython-installer-2.7.3"
export JAVA_LIB_PATH="$HMS_HOME/bin:$HMS_HOME/bin/gdal"
export PATH="$HMS_HOME/bin/taudem:$HMS_HOME/bin/mpi:$PATH"
export GDAL_DATA="$HMS_HOME/bin/gdal/gdal-data"
export PROJ_LIB="$HMS_HOME/bin/gdal/proj"
export LD_LIBRARY_PATH="$JAVA_LIB_PATH:$LD_LIBRARY_PATH"

export CLASSPATH="%VORTEX_HOME%\lib\*:%CLASSPATH%"

if [ ! -d "$HMS_HOME" ]; then
  echo "Error: HMS_HOME no está disponible en la ruta $HMS_HOME"
  exit 1
fi

if [ ! -f "$HMS_HOME/jre/bin/java" ]; then
  echo "Error: java no encontrado en $HMS_HOME"
  exit 1
fi

# Set the path to Jython script
export SCRIPT_PATH="Execute.py"
# Running the script using the Jython interpreter from HEC-HMS
# "$HMS_HOME/jre/bin/java"  -Djava.awt.headless=true -Djava.library.path="$JAVA_LIB_PATH" -Dsun.awt.fontconfig="$HMS_HOME/jre/lib/psfontj2d.properties" -cp "$HMS_HOME/hms.jar:$HMS_HOME/lib/*" org.python.util.jython -S $SCRIPT_PATH

echo "Model execution test"

# Check the exit status of the Java command
if [ $? -ne 0 ]; then
  echo "Script execution failed"
  exit 1  # Exit with -1 if there was an error
else
  echo "Script execution completed successfully"
  # Moure el fitxer a results
  mv /dk/HMS_Tirso_v3/ERA5_Land_current.dss /dk/HMS_Tirso_v2/results/ERA5_Land_current.dss
  # exit 0  # Exit with 0 if successful
fi

python3 UploadToWot.py