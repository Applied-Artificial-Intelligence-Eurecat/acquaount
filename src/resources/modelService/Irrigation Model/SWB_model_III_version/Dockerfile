FROM rocker/r-ver:4.3.1

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev \
    git \
    && apt-get clean

# Instala dependencias Python
COPY requirements.txt .
RUN pip install -r requirements.txt

# Instala paquetes R desde CRAN
RUN R -e "install.packages(c('remotes', 'tictoc', 'readxl', 'lubridate', 'units', 'dplyr', 'randomForest', 'outliers', 'aqp', 'ranger', 'parallel', 'stringr'), repos='https://cloud.r-project.org')"

# Instala soilDB desde GitHub
RUN R -e "remotes::install_github('ncss-tech/soilDB')"

# Instala jsonlite desde CRAN
RUN R -e "install.packages('jsonlite', repos='https://cloud.r-project.org')"
# Instala rstudioapi desde CRAN
RUN R -e "install.packages('rstudioapi', repos='https://cloud.r-project.org')"

# Instala httr desde CRAN
RUN R -e "install.packages('httr', repos='https://cloud.r-project.org')"
# Instala here desde CRAN
RUN R -e "install.packages('here', repos='https://cloud.r-project.org')"

# Copia tus scripts
COPY src .

RUN ls /Functions
# Comando de entrada
# CMD ["sh", "-c", "python3 download_data.py run.json && echo 'Download Data  Done' && python3 createJSONconfig.py run.json && Rscript Input_data/crop_table.R && echo 'Create JSON Config Done' && Rscript crop_water_req_model_farm_multilayer.R && echo 'Crop Done' && python3 processOutputs.py && echo 'Process Outputs Done'"]
CMD ["sh", "-c", "python3 download_data.py run.json && echo 'Download Data  Done' && python3 createJSONconfig.py run.json && echo 'Create JSON Config Done' && Rscript crop_water_req_model_farm_SWB_ONLY.R && echo 'Crop Done' && python3 processOutputs.py && echo 'Process Outputs Done'"]