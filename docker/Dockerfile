# Dockerfile for Prebid Server Java
# This builds the official Prebid Server Java from source
# For production, you can use the prebuilt image: prebid/prebid-server-java:latest

FROM maven:3.9-amazoncorretto-21 AS builder

WORKDIR /build

# Clone and build Prebid Server Java
RUN yum install -y git && \
    git clone https://github.com/prebid/prebid-server-java.git . && \
    mvn clean package -DskipTests

# Runtime stage
FROM amazoncorretto:21-alpine

WORKDIR /app/prebid-server

# Install curl for health checks
RUN apk add --no-cache curl bash

# Copy built JAR and configuration from builder
COPY --from=builder /build/target/prebid-server.jar ./
COPY --from=builder /build/src/main/docker/run.sh ./
COPY --from=builder /build/src/main/docker/application.yaml ./

# Create volumes for configuration and data
VOLUME /app/prebid-server/conf
VOLUME /app/prebid-server/data

# Create non-root user
RUN addgroup -g 1000 prebid && \
    adduser -D -u 1000 -G prebid prebid && \
    chown -R prebid:prebid /app/prebid-server && \
    chmod +x /app/prebid-server/run.sh

USER prebid

# Expose ports (8080 for API, 8060 for admin)
EXPOSE 8080
EXPOSE 8060

# Health check on /status endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/status || exit 1

# Run Prebid Server
ENTRYPOINT ["/app/prebid-server/run.sh"]
