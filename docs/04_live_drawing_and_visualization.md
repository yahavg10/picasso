# 04 - Live Drawing, Visual Synthesis & Interactive Canvas Engine

## 1. Objectives & User Experience

The visualization layer translates complex, multidimensional AWS topologies into an intuitive, live interactive canvas. Rather than static diagrams, Picasso renders a **dynamic living map** that updates in real time as the Go scanner processes accounts and regions.

---

## 2. Visual Layout Architecture

```
                    ┌──────────────────────────────────────────────┐
                    │               Account Boundary               │
  ┌─────────────────┴──────────────────────────────────────────────┴──────────────────┐
  │ Region: us-east-1                                                                 │
  │                                                                                   │
  │  ┌──────────────────────── VPC (10.0.0.0/16) ──────────────────────────────────┐  │
  │  │                                                                             │  │
  │  │   [Internet Gateway]                                                        │  │
  │  │            │                                                                │  │
  │  │   ┌────────▼────────────────────────┐ ┌───────────────────────────────────┐ │  │
  │  │   │ Public Subnet (10.0.1.0/24)     │ │ Private Subnet (10.0.2.0/24)     │ │  │
  │  │   │                                 │ │                                   │ │  │
  │  │   │  [ALB: Internet-Facing]         │ │  [RDS: MySQL Instance]            │ │  │
  │  │   │     ▲                           │ │     ▲                             │ │  │
  │  │   │     │ (Port 80/443)             │ │     │ (Port 3306)                 │ │  │
  │  │   │     │                           │ │     │                             │ │  │
  │  │   │  [EC2: Web Server] ─────────────┼─┼─────┘ (App Traffic)               │ │  │
  │  │   │   ⚠ Ingress 0.0.0.0/0:22 (SSH)  │ │                                   │ │  │
  │  │   └─────────────────────────────────┘ └───────────────────────────────────┘ │  │
  │  └─────────────────────────────────────────────────────────────────────────────┘  │
  └───────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Hierarchical Nesting & Layout Algorithm

To prevent the visual chaos common in cloud diagrams ("spaghetti graphs"), Picasso uses a **hierarchical box-in-box nesting algorithm** paired with **Dagre / Elk layout engines**:

### Nesting Levels:
1. **Level 0 (Root)**: AWS Organization / Cloud Provider
2. **Level 1 (Accounts)**: AWS Account boundary (`123456789012`)
3. **Level 2 (Regions)**: Regional boundaries (`us-east-1`, `eu-central-1`)
4. **Level 3 (VPCs)**: Virtual Private Clouds (`vpc-xxxx`)
5. **Level 4 (Availability Zones & Subnets)**:
   - Tiered vertically: Public Subnets (top) $\rightarrow$ Private App Subnets (middle) $\rightarrow$ Isolated DB Subnets (bottom).
6. **Level 5 (Workloads & Endpoints)**:
   - EC2, ECS, Lambda, RDS, S3 Gateway Endpoints, ENIs.

---

## 4. Visual Threat Modeling Cues

Picasso uses explicit visual cues to communicate risk instantly without reading long audit reports:

| Visual Element | Representation | Meaning |
| :--- | :--- | :--- |
| **Node Border Color** | 🔴 Red Glowing Border | **Critical Risk**: Direct internet exposure, root key, or active privilege escalation. |
| **Node Border Color** | 🟠 Orange Border | **High Risk**: Missing encryption, open management port, or disabled logs. |
| **Node Border Color** | 🟢 Green Border | **Healthy**: Configured according to CIS AWS benchmarks. |
| **Edge Styling** | ─── Solid Blue Arrow | Normal authorized network/trust relationship. |
| **Edge Styling** | ╌╌╌ Animated Pulsing Red | **Active Attack Path**: Traversible vector from internet to internal asset. |
| **Badges** | Floating Pill Icon `[ ⚠ 3 Risks ]` | Number of security findings on the given node. |

---

## 5. Frontend Canvas Implementation (React Flow)

The canvas is implemented in **React Flow** (or **Excalidraw**) with custom node types:

### Node Types
- `AccountNode`: Parent boundary container with account metadata.
- `VpcContainerNode`: Sub-canvas container showing VPC CIDR and attached IGWs.
- `SubnetContainerNode`: Styled container (tinted green for private, tinted yellow/red for public).
- `ComputeNode`: Custom component for EC2/ECS/Lambda with OS icon, attached IAM role badge, and IP tags.
- `DatabaseNode`: Custom component for RDS/DynamoDB with encryption status and engine logo.
- `SecurityGroupOverlay`: Semi-transparent perimeter boundary around instances sharing the same SG.

### Interactive Features
- **Real-Time Streaming**: As the Go scanner discovers a VPC or subnet, the node animates into view via WebSocket events.
- **Node Drill-Down Drawer**: Clicking any node opens a right-side drawer showing:
  - Raw AWS JSON configuration.
  - Active Security Findings from the Python reasoning agents.
  - Blast Radius Map (what this node can access).
  - Remediation Action Button ("Generate Terraform Diff").
- **Threat Filter Toggle**: Users can toggle between "Full Architecture View" and "Attack Surface Only View" (hides safe internal nodes).
