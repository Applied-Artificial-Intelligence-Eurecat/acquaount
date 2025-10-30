# Use an official R image as the base
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    r-base \
    && apt-get clean

# Set the working directory in the container
WORKDIR /

# Copy the R script to the container
COPY . .

RUN pip install -r requirements.txt

# RUN apt-get update
RUN echo 'Y' | apt-get install libudunits2-dev
# Install any required R packages
# If your script requires specific R packages, install them here
RUN R -e "install.packages(c('tictoc', 'readxl', 'lubridate', 'units', 'dplyr', 'randomForest', 'outliers'), repos='http://cran.r-project.org')"

# Run the R script