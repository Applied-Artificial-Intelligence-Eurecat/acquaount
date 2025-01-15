# Use node:18.12.1-slim image as the base
FROM node:18.12.1-slim

# Create and set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY ./src/main ./src/main
COPY ./src/resources/thingDescription ./src/resources/thingDescription
COPY ./src/resources/configs ./src/resources/configs

# Expose port 80 for the Node.js application
EXPOSE 80

# Define the command to run when the container starts
CMD [ "node", "src/main/server.js", "src/resources/configs/prod.json" ]