# Picasso 🎨
### AI-Powered AWS Infrastructure Scanner & Live Security Topology Engine

**Picasso** is an intelligent cloud discovery, threat modeling, and visualization tool. It combines a **high-concurrency Go scanning engine** with a **Python multi-agent AI reasoning layer** to analyze an AWS environment—evaluating control plane risks, VPC network isolation, firewall misconfigurations, and IAM blast radii—and **directly generates native `.excalidraw` and `.drawio` diagram files** alongside actionable remediation diffs.

> [!NOTE]
> **Zero-Frontend Required**: Picasso is a headless CLI pipeline. Visualizations are saved directly as `.excalidraw` and `.drawio` files, which open natively in [Excalidraw](https://excalidraw.com), [Draw.io / diagrams.net](https://app.diagrams.net), or your favorite VS Code diagramming extensions.

---

## 📚 Architectural Design Specifications

The project architecture is fully documented within the [`docs/`](./docs) directory:

| Document | Focus | Core Technologies |
| :--- | :--- | :--- |
| [**00 - System Overview & Polyglot Architecture**](./docs/00_system_overview.md) | High-level system design, Go vs. Python role split, zero-frontend pipeline | Go, Python, gRPC/Pipes |
| [**01 - Scanner Engine (Golang)**](./docs/01_scanner_engine_golang.md) | High-throughput, token-bucket rate-limited concurrent AWS discovery | Go 1.23+, `aws-sdk-go-v2`, Goroutines |
| [**02 - Agent Intelligence Layer (Python)**](./docs/02_agent_intelligence_python.md) | Multi-agent orchestration, LangGraph state machine, specialized agents | Python 3.12+, LangGraph, Gemini API |
| [**03 - Security Threat Models & Rules**](./docs/03_security_threat_model_and_rules.md) | Control plane, VPC, Firewall, and IAM privilege escalation heuristics | CIS AWS Benchmark, MITRE ATT&CK Cloud |
| [**04 - Excalidraw & Draw.io Synthesis**](./docs/04_live_drawing_and_visualization.md) | `.excalidraw` JSON and `.drawio` XML engines with hierarchical container nesting | Excalidraw JSON, Draw.io mxGraph XML |
| [**05 - Countermeasures & Remediation**](./docs/05_countermeasures_and_remediation.md) | Automated IaC diffs, least-privilege IAM policy compiler, quarantine actions | Terraform HCL, CloudFormation, HITL |
| [**06 - API Contracts & Schemas**](./docs/06_api_and_data_schemas.md) | Protobuf/gRPC specs, JSON REST payloads, Excalidraw & Draw.io schemas | Protocol Buffers, Pydantic, JSON Schema |
| [**07 - Roadmap & Tech Stack**](./docs/07_development_roadmap_and_tech_stack.md) | Monorepo layout, local testing with LocalStack, milestone plan | Docker Compose, LocalStack, Makefile |

---

## ⚡ The Headless Pipeline: Go + Python

```
[Target AWS Account]
         │ (aws-sdk-go-v2)
         ▼
[Go Scanner Engine] ────(gRPC / JSON Stream)────► [Python AI Agent Orchestrator]
                                                            │
                                  ┌─────────────────────────┴────────────────────────┐
                                  ▼                                                  ▼
                     [topology.excalidraw]                               [architecture.drawio]
                    (Excalidraw / VS Code)                             (Draw.io / diagrams.net)
```

- **Golang (`picasso-scanner`)**: High-throughput asynchronous AWS API crawling with goroutines and low memory consumption, rate-limit avoidance, and streaming normalized cloud topology graphs.
- **Python (`picasso-agent-core`)**: LLM orchestration (LangGraph, Gemini API), complex IAM privilege escalation graph traversal (NetworkX), security reasoning, and generation of `.excalidraw` and `.drawio` files + Terraform diffs.

---

## 🔍 Core Security Pillars

1. **Control Plane & Governance**: Evaluates AWS Organizations, SCP enforcement, multi-region CloudTrail immutability, and GuardDuty detection.
2. **VPC & Network Segmentation**: Analyzes public vs. private subnets, NAT gateways, route tables, and cross-environment VPC peering bleed.
3. **Firewalls & Perimeter**: Flags unrestricted Security Group ingress (`0.0.0.0/0` on sensitive ports), default SG usage, and WAF associations.
4. **IAM Risks & Blast Radius**: Discovers privilege escalation chains (e.g., `iam:PassRole`, policy tampering), wildcard policies, and cross-account trust boundaries.
