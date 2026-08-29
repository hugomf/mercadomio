# syntax=docker/dockerfile:1
FROM ghcr.io/cirruslabs/flutter:3.32.8 AS build
WORKDIR /app
COPY . .
ARG USERBREW_ISSUER=http://localhost:8090
ARG USERBREW_CLIENT_ID=mercadomio-admin
ARG USERBREW_REDIRECT_URI=http://localhost:3100/auth/callback
RUN flutter build web \
  --dart-define=USERBREW_ISSUER=$USERBREW_ISSUER \
  --dart-define=USERBREW_CLIENT_ID=$USERBREW_CLIENT_ID \
  --dart-define=USERBREW_REDIRECT_URI=$USERBREW_REDIRECT_URI

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]