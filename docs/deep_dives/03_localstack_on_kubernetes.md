# Deep Dive: Running LocalStack on Local Kubernetes (Zero-Cloud AWS Architecture)

## 1. Why Run LocalStack on Kubernetes?

In DevSecOps and enterprise engineering, having a **100% offline, zero-cost, and reproducible cloud environment** is critical:
- **No AWS Bill**: You can test destructive security scenarios without paying a single cent to Amazon.
- **No Production Risk**: Zero chance of accidentally touching real cloud infrastructure or exposing corporate assets.
- **Air-Gapped & Offline CI/CD**: Tests run inside ephemeral Kubernetes clusters in GitHub Actions, GitLab CI, or on a local Mac.
- **Extreme Speed**: LocalStack API calls respond in single-digit milliseconds compared to hundreds of milliseconds over public AWS endpoints.

---

## 2. LocalStack Kubernetes Deployment Architecture

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ LOCAL KUBERNETES CLUSTER (Kind / Minikube / K3s)                                       │
│                                                                                        │
│  ┌───────────────────────┐           ┌──────────────────────────────────────────────┐  │
│  │ Picasso Scanner (Job) │           │ LocalStack Pod (Namespace: localstack)       │  │
│  │                       │           │                                              │  │
│  │  - Go Scanner CLI     │           │  - Core Services: EC2, IAM, S3, STS, Logs    │  │
│  │  - Python Reasoner    │           │  - Ports: 4566 (Edge Gateway)                │  │
│  │  - Excalidraw /       │           │  - Persistent Volume Claim (state cache)     │  │
│  │    Draw.io Exporter   │           │                                              │  │
│  └───────────┬───────────┘           └──────────────────────▲───────────────────────┘  │
│              │                                              │                          │
│              └────────────(http://localstack:4566)──────────┘                          │
│                                   (Kubernetes ClusterIP Service)                       │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Kubernetes Deployment Manifests

### 1. LocalStack Deployment & Service (`deploy/k8s/localstack.yaml`)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: localstack
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: localstack
  namespace: localstack
  labels:
    app: localstack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: localstack
  template:
    metadata:
      labels:
        app: localstack
    spec:
      containers:
      - name: localstack
        image: localstack/localstack:latest
        ports:
        - containerPort: 4566
          name: edge
        env:
        - name: SERVICES
          value: "ec2,iam,s3,sts,cloudtrail,guardduty,route53"
        - name: PERSISTENCE
          value: "0" # Ephemeral for clean tests
        - name: DOCKER_HOST
          value: "unix:///var/run/docker.sock"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
---
apiVersion: v1
kind: Service
metadata:
  name: localstack
  namespace: localstack
spec:
  type: ClusterIP
  selector:
    app: localstack
  ports:
  - port: 4566
    targetPort: 4566
    name: edge
```

---

## 4. Seeding the "Damn Vulnerable Cloud Architecture" (DVCA)

To test Picasso's scanner and reasoning agents, we seed LocalStack with intentional security misconfigurations using a Terraform manifest (`deploy/dvca/main.tf`):

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2        = "http://localhost:4566"
    iam        = "http://localhost:4566"
    s3         = "http://localhost:4566"
    sts        = "http://localhost:4566"
    cloudtrail = "http://localhost:4566"
  }
}

# 1. Vulnerable Production VPC
resource "aws_vpc" "prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Production-VPC" }
}

# 2. Public Subnet with Internet Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id
}

# 3. CRITICAL FLAW: Security Group open to the world on SSH & MySQL
resource "aws_security_group" "vulnerable_sg" {
  name        = "vulnerable-web-sg"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "SSH open to world"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Database port exposed directly"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. CRITICAL FLAW: IAM Role with Wildcard AdministratorAccess
resource "aws_iam_role" "admin_role" {
  name = "VulnerableInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

---

## 5. Configuring the Go Scanner for LocalStack

The Go AWS SDK v2 allows custom endpoint resolvers. Picasso intercepts standard AWS endpoint resolution and redirects requests to LocalStack when the `--localstack` flag or `LOCALSTACK_URL` environment variable is detected:

```go
package config

import (
    "context"
    "os"
    "github.com/aws/aws-sdk-go-v2/aws"
    awsconfig "github.com/aws/aws-sdk-go-v2/config"
)

func LoadAWSConfig(ctx context.Context, region string) (aws.Config, error) {
    localstackURL := os.Getenv("LOCALSTACK_URL") // e.g. "http://localhost:4566"
    
    if localstackURL != "" {
        customResolver := aws.EndpointResolverWithOptionsFunc(
            func(service, reg string, options ...interface{}) (aws.Endpoint, error) {
                return aws.Endpoint{
                    PartitionID:       "aws",
                    URL:               localstackURL,
                    SigningRegion:     region,
                    HostnameImmutable: true,
                }, nil
            },
        )
        return awsconfig.LoadDefaultConfig(ctx,
            awsconfig.WithRegion(region),
            awsconfig.WithEndpointResolverWithOptions(customResolver),
            awsconfig.WithCredentialsProvider(aws.AnonymousCredentials{}),
        )
    }
    
    // Normal AWS Cloud Resolution
    return awsconfig.LoadDefaultConfig(ctx, awsconfig.WithRegion(region))
}
```

---

## 6. The 1-Command Local Kubernetes Workflow

With this setup, the entire lifecycle is automated in a single command:

```bash
# 1. Create local cluster & deploy LocalStack
make k8s-up

# 2. Seed vulnerable AWS resources via Terraform
make seed-dvca

# 3. Run Picasso scan against Kubernetes LocalStack & generate diagrams
make scan-local

# 4. Tear down
make k8s-down
```
This guarantees an interviewer or hiring manager can clone your repository and see the full system running in 60 seconds without an AWS account.
