# 01 - High-Concurrency AWS Scanner Engine (Golang)

## 1. Role & Objectives

The `picasso-scanner` is written in **Go** to maximize scanning throughput across multiple AWS regions and accounts. It discovers cloud assets, normalizes configuration states, and extracts relationship edges without triggering AWS API throttling.

---

## 2. Concurrency & Rate Limiting Architecture

AWS APIs enforce token-bucket rate limits per account/region (e.g. `ec2:DescribeInstances` has different limits from `iam:ListRoles`).

```
                    ┌──────────────────────────────────────────────┐
                    │            Scan Manager Orchestrator         │
                    └──────┬──────────────────────┬─────────────┬──┘
                           │                      │             │
              [Region: us-east-1]       [Region: eu-west-1]   [Global / IAM]
                           │                      │             │
              ┌────────────▼──────────┐ ┌─────────▼───────────┐ │
              │ Worker Pool (N=16)    │ │ Worker Pool (N=16)   │ │
              │ Token Bucket Limiter  │ │ Token Bucket Limiter │ │
              └────────────┬──────────┘ └─────────┬───────────┘ │
                           │                      │             │
                           └──────────────┬───────┴─────────────┘
                                          ▼
                             Unified Graph Buffer (Channel)
                                          │
                                          ▼
                                gRPC Streaming Server
```

### Key Concurrency Patterns
- **Targeted Worker Pools (`errgroup` / `semaphore`)**: Separate worker pools per AWS service category to avoid global locks.
- **Adaptive Rate Limiting**: Uses `golang.org/x/time/rate` alongside AWS SDK v2's default exponential backoff retryer (`aws.Retryer`).
- **Parallel Region Fan-out**: Independent goroutines scan enabled regions concurrently; global services (IAM, Organizations, CloudFront, Route53) run in a dedicated global worker.

---

## 3. Discovered Resource Domains

### Domain 1: Control Plane & Governance
- **AWS Organizations**: OU tree hierarchy, parent-child linkages, attached Service Control Policies (SCPs).
- **CloudTrail**: Multi-region trail status, S3 delivery bucket, KMS key encryption, CloudWatch log group integration.
- **AWS GuardDuty & Security Hub**: Detection status, master-member account linkage, active high-severity findings.
- **AWS Config**: Recording status, delivery channel health, compliance rule status.

### Domain 2: Networking & VPC Topology
- **VPCs & CIDRs**: VPC IDs, IPv4/IPv6 CIDR allocations, tenancy, VPC peering connections.
- **Subnets**: Public vs. private classification (calculated by route table inspection), AZ assignment, available IP counts.
- **Routing & Gateways**: Route Tables, Internet Gateways (IGWs), NAT Gateways, Transit Gateway attachments, Virtual Private Gateways (VGWs), and VPC Endpoints (Interface & Gateway types).

### Domain 3: Firewalls & Traffic Filtering
- **Security Groups**: Ingress & egress rules, CIDRs, referenced security groups, and attached network interfaces (ENIs).
- **NACLs (Network Access Control Lists)**: Subnet association, rule numbers, allow/deny actions, protocol ranges.
- **AWS Network Firewall & WAF**: WAF WebACL associations with ALBs, API Gateways, and CloudFront.

### Domain 4: IAM & Identity Infrastructure
- **Principals**: IAM Users, Groups, Roles, and Identity Providers (OIDC / SAML).
- **Policies**: Inline policies, Customer Managed Policies, AWS Managed Policies, and Permissions Boundaries.
- **Trust Relationships**: `AssumeRolePolicyDocument` structures, conditions (e.g. `sts:ExternalId`, `aws:PrincipalArn`).
- **Instance Profiles**: EC2 instance profile to IAM Role linkages.

---

## 4. Go Code Architecture & Struct Definitions

### Directory Structure
```
picasso-scanner/
├── cmd/
│   └── scanner/
│       └── main.go
├── internal/
│   ├── config/             # AWS authentication & CLI flags
│   ├── engine/             # Concurrency manager & worker dispatcher
│   ├── collectors/         # Service-specific collectors
│   │   ├── controlplane/   # Organizations, CloudTrail, Config
│   │   ├── vpc/            # VPC, Subnets, Routes, IGW, NAT
│   │   ├── firewall/       # SGs, NACLs, WAF
│   │   └── iam/            # Users, Roles, Policies, Trust docs
│   ├── graph/              # Normalized Graph builder
│   └── grpcserver/         # gRPC streaming server implementation
└── proto/
    └── picasso.proto       # Protocol buffer definition
```

### Core Data Models (Go)
```go
package model

import "time"

type ResourceType string

const (
    TypeVPC           ResourceType = "AWS::EC2::VPC"
    TypeSubnet        ResourceType = "AWS::EC2::Subnet"
    TypeSecurityGroup ResourceType = "AWS::EC2::SecurityGroup"
    TypeIAMRole       ResourceType = "AWS::IAM::Role"
    TypeIAMPolicy     ResourceType = "AWS::IAM::Policy"
    TypeIGW           ResourceType = "AWS::EC2::InternetGateway"
    TypeNATGateway    ResourceType = "AWS::EC2::NatGateway"
    TypeRouteTable    ResourceType = "AWS::EC2::RouteTable"
)

// ResourceNode represents any discovered AWS entity normalized for graph analysis
type ResourceNode struct {
    ARN           string                 `json:"arn"`
    ID            string                 `json:"id"`
    Name          string                 `json:"name"`
    Type          ResourceType           `json:"type"`
    AccountID     string                 `json:"account_id"`
    Region        string                 `json:"region"`
    Tags          map[string]string      `json:"tags"`
    Configuration map[string]interface{} `json:"configuration"`
    DiscoveredAt  time.Time              `json:"discovered_at"`
}

// RelationshipEdge connects two entities with relationship context
type RelationshipEdge struct {
    SourceARN    string `json:"source_arn"`
    TargetARN    string `json:"target_arn"`
    Relationship string `json:"relationship"` // e.g., "CONTAINS", "ROUTES_TO", "ALLOWS_TRAFFIC", "ASSUMES_ROLE"
}

// TopologyGraph holds the complete snapshot from a scan
type TopologyGraph struct {
    AccountID string             `json:"account_id"`
    Nodes     []ResourceNode     `json:"nodes"`
    Edges     []RelationshipEdge `json:"edges"`
}
```

---

## 5. Failure Handling & Resilience

1. **Permission Denied (`AccessDeniedException`)**:
   - The scanner does not crash when encountering restricted APIs.
   - It captures access-denied events into a `ScanCoverageReport` so users know what was missed due to IAM constraints.
2. **Exponential Backoff**:
   - Built-in jittered backoff ensures compliant execution within AWS API request ceilings.
3. **Graceful Shutdown**:
   - Context cancellation (`context.WithCancel`) handles SIGTERM/SIGINT, flushing partially collected assets.
