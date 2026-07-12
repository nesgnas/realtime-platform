FROM docker.io/library/node:22-alpine AS build
WORKDIR /app
ARG VITE_API_URL
ARG VITE_SOCKET_URL
ARG VITE_ICE_SERVERS
ENV VITE_API_URL=$VITE_API_URL VITE_SOCKET_URL=$VITE_SOCKET_URL VITE_ICE_SERVERS=$VITE_ICE_SERVERS
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM docker.io/library/nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
