#####################
#  Build stage
#####################
FROM golang:1.24-alpine AS builder

# Install git (needed if you 'go get' private repos)
RUN apk add --no-cache git

# Create workspace
WORKDIR /src

# Cache deps first
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source
COPY . .

# Build the binary
# CGO_ENABLED=0 makes a static binary that runs fine on scratch/alpine
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

#####################
#  Runtime stage
#####################
FROM alpine:latest

# Minimal CA certificates for HTTPS outbound calls
RUN apk --no-cache add ca-certificates

# Create non‑root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy binary
COPY --from=builder /src/server /server

# Cloud Run expects the service to listen on $PORT (default 8080)
EXPOSE 8080
ENV PORT=8080

ENTRYPOINT ["/server"]
