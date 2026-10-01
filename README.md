# Picasso 🎨
### AI-Powered AWS Infrastructure Scanner & Live Security Topology Engine

**Picasso** is an intelligent cloud discovery, threat modeling, and visualization platform. It combines a **high-concurrency Go scanning engine** with a **Python multi-agent AI reasoning layer** to dynamically render a live, interactive diagram of an AWS environment—highlighting control plane risks, VPC network isolation, firewall misconfigurations, and IAM blast radii with actionable countermeasures.

---

## 📚 Architectural Design Specifications

The project architecture has been fully decomposed into dedicated design specifications within the [`docs/`](./docs) directory:

| Document | Focus | Core Technologies |
| :--- | :--- | :--- |
| [**00 - System Overview & Polyglot Architecture**](./docs/00_system_overview.md) | High-level system design, Go vs. Python role split, IPC protocols | Go, Python, gRPC, WebSockets |
| [**01 - Scanner Engine (Golang)**](./docs/01_scanner_engine_golang.md) | High-throughput, token-bucket rate-limited concurrent AWS discovery | Go 1.23+, `aws-sdk-go-v2`, Goroutines |
| [**02 - Agent Intelligence Layer (Python)**](./docs/02_agent_intelligence_python.md) | Multi-agent orchestration, LangGraph state machine, specialized agents | Python 3.12+, LangGraph, Gemini API |
| [**03 - Security Threat Models & Rules**](./docs/03_security_threat_model_and_rules.md) | Control plane, VPC, Firewall, and IAM privilege escalation heuristics | CIS AWS Benchmark, MITRE ATT&CK Cloud |
| [**04 - Live Drawing & Visualization**](./docs/04_live_drawing_and_visualization.md) | Hierarchical box-in-box canvas layout, glowing threat states, blast radius | React Flow, Next.js, WebSockets |
| [**05 - Countermeasures & Remediation**](./docs/05_countermeasures_and_remediation.md) | Automated IaC diffs, least-privilege IAM policy compiler, quarantine actions | Terraform HCL, CloudFormation, HITL |
| [**06 - API Contracts & Schemas**](./docs/06_api_and_data_schemas.md) | Protobuf/gRPC specs, JSON REST payloads, and Canvas schemas | Protocol Buffers, Pydantic, JSON Schema |
| [**07 - Roadmap & Tech Stack**](./docs/07_development_roadmap_and_tech_stack.md) | Monorepo layout, local testing with LocalStack, milestone plan | Docker Compose, LocalStack, Makefile |

---

## ⚡ Why Go + Python?

Picasso leverages a polyglot microservice pattern tailored for cloud security tooling:

- **Golang (`picasso-scanner`)**: Handles wire-speed, multi-region AWS API querying with worker pools, avoiding rate limits, and streaming normalized cloud topology graphs over gRPC.
- **Python (`picasso-agent-core`)**: Handles LLM orchestration, structured tool-calling, graph traversal (IAM privilege escalation chains), and generation of Terraform/CloudFormation remediation diffs.
- **TypeScript / React Flow (`picasso-web`)**: Implements the interactive live drawing canvas with real-time WebSocket streaming.

```
[Target AWS Account]
         │ (aws-sdk-go-v2)
         ▼
[Go Scanner Engine] ────(gRPC Stream)────► [Python AI Agent Orchestrator]
                                                    │
                                                    ▼ (WebSockets / SSE)
                                        [Interactive React Flow Canvas]
```

---

## 🔍 Core Security Pillars

1. **Control Plane & Governance**: Evaluates AWS Organizations, SCP enforcement, multi-region CloudTrail immutability, and GuardDuty detection.
2. **VPC & Network Segmentation**: Analyzes public vs. private subnets, NAT gateways, route tables, and cross-environment VPC peering bleed.
3. **Firewalls & Perimeter**: Flags unrestricted Security Group ingress (`0.0.0.0/0` on sensitive ports), default SG usage, and WAF associations.
4. **IAM Risks & Blast Radius**: Discovers privilege escalation chains (e.g., `iam:PassRole`, policy tampering), wildcard policies, and cross-account trust boundaries.
