# Start from the official Go image.
# Using an Alpine-based image is common for smaller footprints.
FROM golang:1.24-alpine AS builder

# Create and set working directory inside the container
WORKDIR /src

# Copy go.mod and go.sum files first (better for build caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the Go binary
RUN go build -o server ./src

# Now create a small final image
FROM alpine:latest
RUN apk --no-cache add ca-certificates

# Create a non-root user to run the service
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy the binary from the builder
COPY --from=builder /src/server /server

# Expose the port (not strictly required by Cloud Run, but useful for local tests)
EXPOSE 9000

# Command to run when starting the container
ENTRYPOINT ["/server"]
