# Build Stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install git & dependencies
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download || true

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server cmd/api/main.go

# Production Scratch Stage (~15MB Image)
FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata
ENV TZ=Asia/Jakarta

COPY --from=builder /app/server /app/server
COPY --from=builder /app/migrations /app/migrations
COPY --from=builder /app/uploads /app/uploads

EXPOSE 8080

CMD ["/app/server"]
