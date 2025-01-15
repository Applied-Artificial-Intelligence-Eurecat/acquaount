# Stage 1: Build Angular application
FROM node:18.18.2-alpine as builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build --prod

# Stage 2: Setup NGINX and deploy built app
FROM nginx:alpine

COPY --from=builder /app/dist/monitoring-platform/browser /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
