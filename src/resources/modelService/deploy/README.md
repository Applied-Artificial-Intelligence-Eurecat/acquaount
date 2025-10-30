# DOCKER

## build docker:

docker-compose --project-directory ./ -f .\deploy\docker-compose.yml build

## start docker:

docker-compose --project-directory ./ -f .\deploy\docker-compose.yml up -d

## stop docker:

docker-compose --project-directory ./ -f .\deploy\docker-compose.yml down