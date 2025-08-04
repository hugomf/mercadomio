# syntax=docker/dockerfile:1
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go version
RUN apk add --no-cache git
RUN go mod download
RUN go build -o server ./main.go

FROM alpine:3.18
WORKDIR /app
COPY --from=builder /app/server ./server
EXPOSE 8080
CMD ["./server"] 