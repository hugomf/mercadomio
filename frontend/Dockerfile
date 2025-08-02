# syntax=docker/dockerfile:1
FROM ghcr.io/cirruslabs/flutter:3.32.8 AS build
WORKDIR /app
COPY . .
RUN flutter build web

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
