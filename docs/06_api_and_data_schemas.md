# 06 - API Contracts, Protocols & Data Schemas

## 1. Overview

This document specifies the inter-service communication contracts connecting the **Golang Scanner**, **Python Agent Layer**, and the **Web Visualizer Canvas**.

---

## 2. Protobuf / gRPC Interface (`picasso.proto`)

The Go scanner exposes a gRPC streaming service used by the Python agent layer:

```protobuf
syntax = "proto3";

package picasso.v1;

option go_package = "github.com/yahavg10/picasso/pkg/api/v1;picassov1";

service PicassoScannerService {
  // Streams discovered resources as they are fetched from AWS
  rpc StreamScan(ScanRequest) returns (stream ResourceEvent);

  // Initiates a full scan and returns the complete topology graph
  rpc RunFullScan(ScanRequest) returns (ScanResponse);
}

message ScanRequest {
  string account_id = 1;
  repeated string regions = 2;
  repeated string service_filters = 3;
}

message ResourceEvent {
  string event_id = 1;
  enum EventType {
    DISCOVERED = 0;
    RELATIONSHIP_FOUND = 1;
    SCAN_COMPLETED = 2;
    SCAN_ERROR = 3;
  }
  EventType type = 2;
  ResourceNode resource = 3;
  RelationshipEdge edge = 4;
  string message = 5;
}

message ResourceNode {
  string arn = 1;
  string id = 2;
  string name = 3;
  string resource_type = 4;
  string account_id = 5;
  string region = 6;
  map<string, string> tags = 7;
  string configuration_json = 8;
  int64 discovered_timestamp = 9;
}

message RelationshipEdge {
  string source_arn = 1;
  string target_arn = 2;
  string relationship = 3; // e.g. "CONTAINS", "ROUTES_TO", "ATTACHED_TO"
}

message ScanResponse {
  string account_id = 1;
  int64 scan_duration_ms = 2;
  repeated ResourceNode nodes = 3;
  repeated RelationshipEdge edges = 4;
}
```

---

## 3. Python Agent REST & WebSocket API

The Python orchestrator (`picasso-agent-core`) exposes endpoints for the frontend:

### REST Endpoints
- `POST /api/v1/scan/start`
  - Body: `{ "account_id": "...", "regions": ["us-east-1", "eu-west-1"] }`
  - Response: `{ "scan_id": "scan_abc123", "status": "RUNNING" }`
- `GET /api/v1/scan/:scan_id/report`
  - Response: Returns full `AnalysisReport` with risk scores and findings.
- `POST /api/v1/remediate/generate-diff`
  - Body: `{ "finding_id": "FW-001", "format": "terraform" }`
  - Response: `{ "diff": "...", "target_file": "security_groups.tf" }`

### WebSocket Live Stream
- `WS /api/v1/scan/:scan_id/live`
  - Streams canvas graph mutations directly to the frontend.
  - Payloads:
    ```json
    {
      "type": "NODE_ADDED",
      "node": {
        "id": "arn:aws:ec2:us-east-1:123456789012:instance/i-0a1b2c3d4e",
        "type": "compute",
        "data": {
          "label": "Web-Server-01",
          "ip": "54.210.12.34",
          "severity": "CRITICAL",
          "findings_count": 2
        },
        "parentNode": "subnet-0123456789abcdef0"
      }
    }
    ```

---

## 4. Visual Canvas Schema (React Flow Format)

```json
{
  "canvas": {
    "nodes": [
      {
        "id": "vpc-0123456789",
        "type": "vpcContainer",
        "position": { "x": 100, "y": 100 },
        "data": {
          "label": "Production VPC",
          "cidr": "10.0.0.0/16"
        },
        "style": { "width": 800, "height": 600 }
      },
      {
        "id": "subnet-public-1",
        "type": "subnetContainer",
        "parentNode": "vpc-0123456789",
        "position": { "x": 50, "y": 80 },
        "data": {
          "label": "Public Subnet us-east-1a",
          "tier": "PUBLIC",
          "cidr": "10.0.1.0/24"
        }
      }
    ],
    "edges": [
      {
        "id": "edge-igw-to-subnet",
        "source": "igw-0123456789",
        "target": "subnet-public-1",
        "animated": true,
        "style": { "stroke": "#ef4444", "strokeWidth": 2 },
        "data": { "threat": "Internet Ingress Route" }
      }
    ]
  }
}
```
