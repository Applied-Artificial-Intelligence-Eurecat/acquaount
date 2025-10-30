# Download base image ubuntu 22.04
FROM ubuntu:20.04
WORKDIR /dk

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

# Update Ubuntu Software repository
RUN apt update
RUN apt upgrade -y

RUN apt-get update
RUN apt-get install -y \
    openjdk-17-jdk --fix-missing \
    && apt-get clean

RUN apt-get -y install gfortran

COPY pyrequirements.txt ./pyrequirements.txt

RUN apt update
RUN echo Y | apt install python3 python3-pip
RUN python3 -m pip install -r pyrequirements.txt

RUN python3 -m pip install https://github.com/gyanz/pydsstools/zipball/master

RUN python3 -m pip install -i https://test.pypi.org/simple/ hecdss

RUN echo 'url: https://cds.climate.copernicus.eu/api' > $HOME/.cdsapirc
RUN echo 'key: 02cb98fe-f4dd-42ef-b057-a9f397dc5e64' >> $HOME/.cdsapirc

COPY . .

CMD ["sh", "-c", "chmod -R 755 ./HMS_Tirso_v3 && sh Workflow.sh"]
