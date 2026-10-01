# Picasso 🎨
### AI-Augmented Cloud Security Engine & Live Architecture Visualizer

**Picasso** is a zero-cloud-cost, production-grade cloud security platform designed for modern **DevSecOps** and **Security Software Engineering** workflows. It couples a **high-concurrency Go scanning engine** with a **deterministic graph solver and Python AI agent layer** to detect critical multi-hop attack paths across AWS architectures—running entirely offline against **LocalStack on local Kubernetes**.

Instead of requiring a web UI, Picasso generates native **`.excalidraw`** and **`.drawio`** files, accompanied by **SARIF** reports (for GitHub's Security tab), **ASFF** findings (for AWS Security Hub), and actionable **Terraform remediation diffs**.

---

## ⚡ The 1-Click Offline Demo

Picasso runs **100% offline** with zero AWS bill by orchestrating LocalStack on local Kubernetes (`Kind` / `Minikube`):

```bash
# 🚀 Starts LocalStack on K8s, provisions a vulnerable AWS architecture,
# scans it with Go, reasons with Python AI agents, and outputs diagrams:
make demo
```

### Generated Artifacts:
- 🎨 **`output/topology.excalidraw`**: Hand-drawn visual architecture with threat badges and attack paths.
- 📐 **`output/architecture.drawio`**: Interactive diagram with collapsible VPC/subnet swimlanes for [Draw.io / diagrams.net](https://app.diagrams.net).
- 📋 **`output/picasso.sarif`**: Industry-standard SARIF report for GitHub Code Scanning / Security alerts.
- 🛡️ **`output/security_report.md`**: Executive risk summary with MITRE ATT&CK for Cloud mappings.
- 🔧 **`output/remediations.tf`**: Automated Terraform HCL patches fixing detected misconfigurations.

---

## 📚 Architectural Design Specifications

| Document | Focus | Core Technologies |
| :--- | :--- | :--- |
| [**00 - System Overview & Architecture**](./docs/00_system_overview.md) | High-level system design, Go vs. Python role split, zero-cloud LocalStack | Go, Python, LocalStack, Kubernetes |
| [**01 - Scanner Engine (Golang)**](./docs/01_scanner_engine_golang.md) | High-throughput, token-bucket rate-limited concurrent AWS discovery | Go 1.23+, `aws-sdk-go-v2`, Goroutines |
| [**02 - Agent Intelligence Layer (Python)**](./docs/02_agent_intelligence_python.md) | Multi-agent orchestration, LangGraph state machine, specialized agents | Python 3.12+, LangGraph, Gemini API |
| [**03 - Security Threat Models & Rules**](./docs/03_security_threat_model_and_rules.md) | Control plane, VPC, Firewall, and IAM privilege escalation heuristics | CIS AWS Benchmark, MITRE ATT&CK Cloud |
| [**04 - Excalidraw & Draw.io Synthesis**](./docs/04_live_drawing_and_visualization.md) | `.excalidraw` JSON and `.drawio` XML engines with hierarchical container nesting | Excalidraw JSON, Draw.io mxGraph XML |
| [**05 - Countermeasures & Remediation**](./docs/05_countermeasures_and_remediation.md) | Automated IaC diffs, least-privilege IAM policy compiler, quarantine actions | Terraform HCL, CloudFormation, HITL |
| [**06 - API Contracts & Schemas**](./docs/06_api_and_data_schemas.md) | Protobuf/gRPC specs, JSON REST payloads, Excalidraw & Draw.io schemas | Protocol Buffers, Pydantic, JSON Schema |
| [**07 - Roadmap & Tech Stack**](./docs/07_development_roadmap_and_tech_stack.md) | Monorepo layout, local testing with LocalStack, milestone plan | Docker Compose, LocalStack, Makefile |

---

## 🧠 Deep-Dive Engineering Guides (Concepts Hard to Catch)

These sub-documents break down the complex computer science, graph theory, and security concepts behind Picasso:

- 🔑 [**01 - IAM Privilege Escalation & Graph Theory**](./docs/deep_dives/01_iam_privilege_escalation_and_graph_theory.md): The 6-layer AWS policy evaluation model, Rhino Security Labs escalation vectors, and using **Dijkstra/BFS** to mathematically prove attack paths.
- 🌐 [**02 - Network Reachability & Firewall Matrices**](./docs/deep_dives/02_network_reachability_and_firewall_matrices.md): Stateful Security Groups vs. Stateless NACLs, route table propagation, and Boolean constraint solving for internet exposure.
- ☸️ [**03 - Running LocalStack on Local Kubernetes**](./docs/deep_dives/03_localstack_on_kubernetes.md): Zero-cloud development architecture using `Kind`/`Minikube`, Kubernetes manifests, and Terraform seeding.
- 🤖 [**04 - The Deterministic + AI Hybrid Pattern**](./docs/deep_dives/04_deterministic_ai_hybrid_pattern.md): Why pure LLM scanners fail (hallucinations, context explosion) and how deterministic graph engines pair with LLM agents.
- 📊 [**05 - Enterprise Security Standards (SARIF, ASFF & MITRE)**](./docs/deep_dives/05_enterprise_reporting_sarif_asff_mitre.md): Emitting SARIF for GitHub Security tab, ASFF for AWS Security Hub, and taxonomy mapping to MITRE ATT&CK for Cloud.

---

## 🏗 Polyglot Engine Architecture

```
[LocalStack on Kubernetes (Pod: 4566)]
                  │ (aws-sdk-go-v2 via custom endpoint resolver)
                  ▼
[Go Scanner CLI: Worker Pools + Goroutines]
                  │ (Normalized Graph JSON Stream)
                  ▼
[Deterministic Graph Solver (NetworkX / BFS)] ──► Proven Attack Paths
                  │
                  ▼
[Python AI Reasoning Agent (Gemini / LangGraph)]
                  │
  ┌───────────────┼───────────────┬────────────────┐
  ▼               ▼               ▼                ▼
[topology.      [architecture.  [picasso.        [remediations.
 excalidraw]     drawio]         sarif]           tf]
```
