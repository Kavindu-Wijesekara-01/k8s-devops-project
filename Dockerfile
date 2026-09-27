# =============================================================================
# Stage 1: Builder
# =============================================================================
FROM golang:1.22-alpine AS builder

# Install dependencies for CGO-disabled build + TLS + timezone support
RUN apk add --no-cache git ca-certificates tzdata

# Create a non-root user to copy into the final image
RUN adduser -D -g '' appuser

WORKDIR /app

# Copy dependency manifests first (maximises Docker layer cache hits)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Compile: static binary, stripped debug symbols, no local paths embedded
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -trimpath \
    -o /go/bin/server \
    .

# =============================================================================
# Stage 2: Final (scratch)
# scratch = zero bytes; only our binary + essentials land in the image
# =============================================================================
FROM scratch

# Timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# CA certificates (required for outbound HTTPS)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Non-root user definition
COPY --from=builder /etc/passwd /etc/passwd

# The compiled binary
COPY --from=builder /go/bin/server /server

USER appuser

EXPOSE 8080

ENTRYPOINT ["/server"]
