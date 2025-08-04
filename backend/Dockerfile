
FROM golang:1.24.5-alpine3.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o server ./main.go

FROM alpine:3.21.3
RUN apk --no-cache add ca-certificates tzdata && \
    apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=builder /app/server ./server
RUN chmod +x ./server && \
    addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /app
USER appuser
EXPOSE 8080
CMD ["./server"]