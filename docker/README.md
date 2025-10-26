# Prebid Server Java Docker Configuration

This directory contains Docker configuration for deploying the official [Prebid Server Java](https://github.com/prebid/prebid-server-java).

## Files

- `Dockerfile` - Builds Prebid Server Java from source
- `docker-compose.yml` - Docker Compose setup for local development

## Quick Start

### Option 1: Using Docker Compose (Recommended for Testing)

```bash
# Build and start Prebid Server
docker-compose up

# Server will be available at:
# - API: http://localhost:8080
# - Admin: http://localhost:8060
# - Status: http://localhost:8080/status
```

### Option 2: Using Prebuilt Image (Recommended for Production)

Instead of building from source, you can use the official prebuilt image:

```bash
docker run -d \
  -p 8080:8080 \
  -p 8060:8060 \
  --name prebid-server \
  prebid/prebid-server-java:latest
```

Or update the `docker-compose.yml` to use the prebuilt image:

```yaml
services:
  prebid-server:
    image: prebid/prebid-server-java:latest
    # Remove the 'build:' section
```

## Configuration

### Custom Configuration Files

Create a `config` directory and add your custom configuration:

```bash
mkdir -p config data
```

Download sample configuration:

```bash
curl -o config/prebid-config.yaml \
  https://raw.githubusercontent.com/prebid/prebid-server-java/master/sample/configs/prebid-config.yaml

curl -o config/sample-app-settings.yaml \
  https://raw.githubusercontent.com/prebid/prebid-server-java/master/sample/configs/sample-app-settings.yaml
```

The volumes in `docker-compose.yml` will mount these to the container.

### Environment Variables

You can customize Java options via the `JAVA_OPTS` environment variable in `docker-compose.yml`:

```yaml
environment:
  - JAVA_OPTS=-Xmx2g -Xms1g
```

## Ports

- **8080**: Main API endpoint for bid requests
- **8060**: Admin endpoint for management and metrics

## Health Check

The container includes a health check that pings `/status` every 30 seconds:

```bash
curl http://localhost:8080/status
```

Expected response: `200 OK`

## Verifying Deployment

After starting the server:

1. Check status:
   ```bash
   curl http://localhost:8080/status
   ```

2. Check container logs:
   ```bash
   docker-compose logs -f prebid-server
   ```

3. Test a sample request (see [Prebid Server documentation](https://docs.prebid.org/prebid-server/endpoints/openrtb2/pbs-endpoint-auction.html))

## Building for Production

### Build the Image

```bash
docker build -t your-registry/prebid-server:latest .
```

### Push to Registry

For AWS ECR:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

docker tag prebid-server:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/prebid-server:latest
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/prebid-server:latest
```

For GCP Container Registry:
```bash
gcloud auth configure-docker

docker tag prebid-server:latest gcr.io/YOUR_PROJECT/prebid-server:latest
docker push gcr.io/YOUR_PROJECT/prebid-server:latest
```

## Resources

- [Prebid Server Java GitHub](https://github.com/prebid/prebid-server-java)
- [Prebid Server Documentation](https://docs.prebid.org/prebid-server/overview/prebid-server-overview.html)
- [Configuration Guide](https://github.com/prebid/prebid-server-java/blob/master/docs/config.md)
- [API Endpoints](https://github.com/prebid/prebid-server-java/blob/master/docs/endpoints)
- [Prebid Server Releases](https://github.com/prebid/prebid-server-java/releases)
