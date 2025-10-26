# Architecture Documentation

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Traffic                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   Route 53    │  ◄── DNS-based Failover
                    │ (Failover DNS)│
                    └───────┬───────┘
                            │
              ┌─────────────┴──────────────┐
              │                            │
    ┌─────────▼──────────┐     ┌──────────▼──────────┐
    │   PRIMARY (AWS)    │     │  FALLBACK (GCP)     │
    │                    │     │                     │
    │  ┌──────────────┐  │     │  ┌──────────────┐  │
    │  │     ALB      │  │     │  │  Global LB   │  │
    │  └──────┬───────┘  │     │  └──────┬───────┘  │
    │         │          │     │         │          │
    │  ┌──────▼───────┐  │     │  ┌──────▼───────┐  │
    │  │ ECS Fargate  │  │     │  │  Cloud Run   │  │
    │  │  (2-10 tasks)│  │     │  │ (1-10 inst.) │  │
    │  └──────────────┘  │     │  └──────────────┘  │
    │                    │     │                     │
    │  Auto-Scaling:     │     │  Auto-Scaling:     │
    │  - CPU: 70%        │     │  - Automatic       │
    │  - Memory: 80%     │     │  - Request-based   │
    └────────────────────┘     └─────────────────────┘
```

## AWS Fargate Architecture (Primary)

```
┌──────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │         Availability Zone 1     │  Availability Zone 2    │
│  │                                │                     │    │
│  │  ┌──────────────┐  ┌──────────────┐               │    │
│  │  │ Public Subnet│  │ Public Subnet│               │    │
│  │  │  10.0.0.0/24 │  │  10.0.1.0/24 │               │    │
│  │  │              │  │              │               │    │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  ┌─────────┐ │    │
│  │  │ │   ALB    │ │  │ │   ALB    │ │  │Internet │ │    │
│  │  │ └────┬─────┘ │  │ └────┬─────┘ │  │ Gateway │ │    │
│  │  │      │       │  │      │       │  └─────────┘ │    │
│  │  └──────┼───────┘  └──────┼───────┘               │    │
│  │         │                 │                        │    │
│  │  ┌──────▼───────┐  ┌──────▼───────┐               │    │
│  │  │Private Subnet│  │Private Subnet│               │    │
│  │  │ 10.0.10.0/24 │  │ 10.0.11.0/24 │               │    │
│  │  │              │  │              │               │    │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │               │    │
│  │  │ │  Fargate │ │  │ │  Fargate │ │               │    │
│  │  │ │   Tasks  │ │  │ │   Tasks  │ │               │    │
│  │  │ └──────────┘ │  │ └──────────┘ │               │    │
│  │  │              │  │              │               │    │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │               │    │
│  │  │ │    NAT   │ │  │ │    NAT   │ │               │    │
│  │  │ │  Gateway │ │  │ │  Gateway │ │               │    │
│  │  │ └──────────┘ │  │ └──────────┘ │               │    │
│  │  └──────────────┘  └──────────────┘               │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────┐  ┌──────────────┐                     │
│  │   CloudWatch    │  │  Auto Scaling│                     │
│  │     Logs        │  │    Groups    │                     │
│  └─────────────────┘  └──────────────┘                     │
└──────────────────────────────────────────────────────────────┘
```

## GCP Cloud Run Architecture (Fallback)

```
┌──────────────────────────────────────────────────────────┐
│                  Google Cloud Platform                   │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │         Global Load Balancer                   │     │
│  │  ┌──────────────────────────────────────┐      │     │
│  │  │   Global External HTTP(S) LB         │      │     │
│  │  │   - Health Checks                    │      │     │
│  │  │   - URL Mapping                      │      │     │
│  │  └──────────────┬───────────────────────┘      │     │
│  └─────────────────┼────────────────────────────────┘     │
│                    │                                      │
│  ┌─────────────────▼────────────────────────────────┐     │
│  │         Backend Service                         │     │
│  │  ┌───────────────────────────────────────┐      │     │
│  │  │  Network Endpoint Group (NEG)         │      │     │
│  │  │  - Serverless NEG for Cloud Run       │      │     │
│  │  └───────────────────────────────────────┘      │     │
│  └──────────────────────────────────────────────────┘     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐     │
│  │         Cloud Run Service                       │     │
│  │                                                  │     │
│  │  Instances: 1-10 (Auto-scaling)                 │     │
│  │  CPU: 2 vCPU per instance                       │     │
│  │  Memory: 2 GiB per instance                     │     │
│  │  Concurrency: 80 requests/instance              │     │
│  │                                                  │     │
│  │  Container: prebid-server:latest                │     │
│  │  Port: 8080                                     │     │
│  │  Health: /status endpoint                       │     │
│  └──────────────────────────────────────────────────┘     │
│                                                          │
│  ┌─────────────────┐  ┌──────────────┐                  │
│  │  Cloud Logging  │  │   Cloud      │                  │
│  │                 │  │  Monitoring  │                  │
│  └─────────────────┘  └──────────────┘                  │
└──────────────────────────────────────────────────────────┘
```

## Failover Strategy

### Automatic DNS Failover

1. **Normal Operation**: Route 53 directs all traffic to AWS ALB
2. **Health Check Failure**: If AWS health check fails 3 consecutive times
3. **Failover Triggered**: Route 53 automatically routes traffic to GCP Cloud Run
4. **Recovery**: When AWS health checks pass, traffic gradually returns to AWS

### Health Check Configuration

- **Protocol**: HTTP
- **Port**: 80
- **Path**: /status
- **Interval**: 30 seconds
- **Failure Threshold**: 3 attempts
- **Timeout**: 5 seconds per check

### Expected Failover Time

- **Detection**: ~90 seconds (3 failures × 30 second interval)
- **DNS Propagation**: 60-120 seconds (based on TTL)
- **Total Failover Time**: ~2-4 minutes

## Scaling Behavior

### AWS Fargate

**Scale-Out Triggers**:
- CPU utilization > 70% for 60 seconds
- Memory utilization > 80% for 60 seconds

**Scale-In Triggers**:
- CPU utilization < 70% for 300 seconds
- Memory utilization < 80% for 300 seconds

**Scaling Range**: 2-10 tasks

### GCP Cloud Run

**Scale-Out Triggers**:
- Automatic based on request volume
- Scales when existing instances at capacity

**Scale-In Triggers**:
- Automatic when request volume decreases
- Scales to min instances when idle

**Scaling Range**: 1-10 instances

## Network Flow

### Request Path (Normal Operation)

```
User → Route 53 → AWS ALB → ECS Fargate Tasks → Application
```

### Request Path (AWS Outage)

```
User → Route 53 → GCP Global LB → Cloud Run Service → Application
```

## Security

### AWS

- **Network Isolation**: Tasks run in private subnets
- **Security Groups**: Restrict traffic to ALB → Tasks
- **IAM Roles**: Least privilege for ECS tasks
- **Encryption**: In-transit via HTTPS, at-rest via EBS

### GCP

- **Service Account**: Dedicated SA with minimal permissions
- **VPC Connector**: Optional private networking
- **IAM**: Cloud Run invoker permissions
- **Encryption**: Automatic encryption at rest and in transit

## Monitoring

### Key Metrics to Monitor

**AWS**:
- ECS Service CPU/Memory Utilization
- ALB Request Count and Latency
- Target Group Health Status
- Auto Scaling Activities

**GCP**:
- Cloud Run Request Count and Latency
- Instance Count
- Container CPU/Memory Usage
- Cold Start Count

### Alerting

Set up alerts for:
- Health check failures
- High error rates (5xx responses)
- Auto-scaling limits reached
- Container restart loops
- High latency (p95 > threshold)

## Cost Optimization

### AWS Fargate

**Cost Factors**:
- vCPU-hours: $0.04048 per vCPU per hour
- GB-hours: $0.004445 per GB per hour
- Data Transfer: Varies by region
- NAT Gateway: $0.045 per hour + data processing

**Estimated Monthly Cost** (2 tasks, 24/7):
- vCPU: 2 tasks × 1 vCPU × 730 hours × $0.04048 = $59.10
- Memory: 2 tasks × 2 GB × 730 hours × $0.004445 = $12.97
- NAT Gateway: 2 × $0.045 × 730 = $65.70
- **Total**: ~$137.77/month (baseline)

### GCP Cloud Run

**Cost Factors**:
- CPU: $0.00002400 per vCPU-second
- Memory: $0.00000250 per GiB-second
- Requests: $0.40 per million requests
- Free Tier: 2 million requests/month

**Estimated Monthly Cost** (1 instance minimum):
- With free tier: $0-50/month (depending on traffic)
- Without free tier: ~$30-100/month (fallback usage)

## Disaster Recovery

### Scenarios

1. **AWS Region Outage**: Route 53 automatically fails over to GCP
2. **Application Bug**: Deploy fix to both platforms independently
3. **DDoS Attack**: Both platforms have built-in DDoS protection
4. **Data Corruption**: Application-level backup and recovery needed

### RTO/RPO

- **Recovery Time Objective (RTO)**: 2-4 minutes (automatic failover)
- **Recovery Point Objective (RPO)**: 0 (stateless application)
