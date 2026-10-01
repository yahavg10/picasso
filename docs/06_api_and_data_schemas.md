# 06 - API Contracts, Protocols & Data Schemas

## 1. Overview

This document specifies the data models, Protobuf definitions, and diagram serialization schemas connecting the **Golang Scanner** and the **Python Agent & Exporter Layer**.

---

## 2. Protobuf / gRPC Interface (`picasso.proto`)

The Go scanner can either run as a standalone CLI outputting a normalized JSON topology, or as a persistent gRPC service streaming directly to the Python reasoner:

```protobuf
syntax = "proto3";

package picasso.v1;

option go_package = "github.com/yahavg10/picasso/pkg/api/v1;picassov1";

service PicassoScannerService {
  // Streams discovered resources as they are discovered
  rpc StreamScan(ScanRequest) returns (stream ResourceEvent);

  // Runs full scan and returns the complete graph snapshot
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
  string relationship = 3; // e.g. "CONTAINS", "ROUTES_TO", "ATTACHED_TO", "ASSUMES_ROLE"
}

message ScanResponse {
  string account_id = 1;
  int64 scan_duration_ms = 2;
  repeated ResourceNode nodes = 3;
  repeated RelationshipEdge edges = 4;
}
```

---

## 3. Excalidraw Element Schema (Python Model)

```python
from typing import List, Optional, Literal
from pydantic import BaseModel, Field

class ExcalidrawElement(BaseModel):
    id: str
    type: Literal["rectangle", "text", "arrow", "line", "ellipse"]
    x: float
    y: float
    width: float
    height: float
    angle: float = 0.0
    strokeColor: str = "#000000"
    backgroundColor: str = "transparent"
    fillStyle: Literal["solid", "hachure", "cross-hatch"] = "solid"
    strokeWidth: int = 1
    strokeStyle: Literal["solid", "dashed", "dotted"] = "solid"
    roughness: int = 1
    opacity: int = 100
    groupIds: List[str] = Field(default_factory=list)
    roundness: Optional[dict] = None
    text: Optional[str] = None
    fontSize: Optional[int] = 16
    fontFamily: int = 1

class ExcalidrawDocument(BaseModel):
    type: str = "excalidraw"
    version: int = 2
    source: str = "picasso"
    elements: List[ExcalidrawElement]
    appState: dict = Field(default_factory=lambda: {
        "viewBackgroundColor": "#1e1e1e",
        "gridSize": 20
    })
```

---

## 4. Draw.io mxGraph Cell Schema

```python
from typing import Optional
from pydantic import BaseModel

class DrawioCell(BaseModel):
    id: str
    value: str
    style: str
    parent: str = "1"
    vertex: Optional[str] = "1"
    edge: Optional[str] = None
    source: Optional[str] = None
    target: Optional[str] = None
    x: Optional[float] = 0.0
    y: Optional[float] = 0.0
    width: Optional[float] = 100.0
    height: Optional[float] = 50.0
```

---

## 5. Security Finding Schema (`findings.json`)

```json
{
  "finding_id": "FW-001",
  "category": "FIREWALL",
  "severity": "CRITICAL",
  "title": "Unrestricted SSH Ingress",
  "resource_arn": "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0123456789abcdef0",
  "remediation": "Restrict port 22 ingress to corporate CIDRs or enable AWS Systems Manager Session Manager.",
  "visual_cue": {
    "target_element_id": "sg-0123456789abcdef0",
    "highlight_color": "#dc2626",
    "badge_text": "CRITICAL: Port 22 Open"
  }
}
```
