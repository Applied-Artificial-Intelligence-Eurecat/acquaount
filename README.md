# ACQUAOUNT
Versió de node **v18.12.0**  
Per instal·lar:
>npm install

#How to deploy: 

git diff --name-only
#git add --all

!!!!!!!copy all Custom fields from the server to the repostory!!!!
Custom fields are located in /Projects/ACQUAOUNT/acquaount-platform/src/resources/thingDescription/Fields/Custom/ 
Download them to your PC and push to the repo (trying to push to git from server fails)

docker compose up -d --build --force-recreate acquaount-platform