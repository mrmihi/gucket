#####################
#  Build stage
#####################
FROM golang:1.24-alpine AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Static Linux binary
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

#####################
#  Runtime stage
#####################
FROM alpine:3.19

# Trust HTTPS in case your app calls external APIs
RUN apk --no-cache add ca-certificates

# ----- copy binary as root and make sure it is executable -----
COPY --from=builder /src/server /usr/local/bin/server
RUN chmod +x /usr/local/bin/server

# ----- create non‑root user AFTER the copy -----
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
 && chown appuser:appgroup /usr/local/bin/server

USER appuser

# Cloud Run uses $PORT (8080 by default)
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/server"]
