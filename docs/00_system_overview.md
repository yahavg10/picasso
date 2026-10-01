# 00 - Picasso System Overview & Tech Split Architecture

## 1. Executive Summary

**Picasso** is an AI-augmented cloud security and infrastructure visualization platform. It addresses the complexity of modern multi-region, multi-account AWS environments by:
1. Concurrently scanning cloud configurations at wire speed using a high-performance Go scanner.
2. Building a unified resource and topology dependency graph.
3. Engaging specialized AI reasoning agents (Python) to evaluate control plane, network perimeter, firewall, and IAM threat models.
4. **Directly generating native `.excalidraw` and `.drawio` diagram files** complete with hierarchical nesting, visual risk heatmaps, attack paths, and actionable remediation diffs—**requiring no custom web frontend**.

---

## 2. Headless Architecture: Golang vs. Python Rationale

Picasso employs a streamlined, file-driven pipeline that produces rich visual assets directly consumable in **Excalidraw** and **Draw.io (diagrams.net)**:

```
                                 ┌─────────────────────────┐
                                 │   Target AWS Account(s) │
                                 └────────────┬────────────┘
                                              │ (AWS SDK v2)
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ GOLANG SUBSYSTEM (High-Concurrency Scanner Core)                                       │
│                                                                                        │
│  - Multi-region / Multi-account discovery workers (goroutines + worker pools)          │
│  - Token-bucket rate limiting (AWS API throttling avoidance)                           │
│  - Raw resource normalization & in-memory graph cache                                  │
│  - Direct gRPC / IPC streaming or normalized JSON graph emission                      │
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ Normalized Graph Stream (gRPC / JSON)
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ PYTHON SUBSYSTEM (Agent Intelligence, Security Reasoner & Diagram Synthesizer)         │
│                                                                                        │
│  - Agent Orchestrator (LangGraph / PydanticAI / Gemini API)                           │
│  - Specialized Agents: Control Plane, Network/VPC, Firewall, IAM Blast Radius          │
│  - IAM Policy Simulation & Privilege Escalation Graph Traversal                        │
│  - Countermeasure Synthesizer (IaC Diff generator: Terraform/CloudFormation)          │
│  - Diagram Exporters:                                                                  │
│      * .excalidraw Engine (JSON AST generator with shapes, colors & groups)            │
│      * .drawio Engine (mxGraph XML generator with styled containers & connectors)     │
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ Direct File Outputs
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ ARTIFACT OUTPUTS (Zero-Frontend Consumption)                                           │
│                                                                                        │
│  ├── network_topology.excalidraw  (Open directly in Excalidraw / VS Code extension)    │
│  ├── security_map.drawio          (Open in Draw.io / diagrams.net / VS Code plugin)   │
│  ├── security_audit_report.md     (Executive summary, findings & risk scores)          │
│  └── remediation_diffs.tf         (Ready-to-apply Terraform HCL patches)               │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Subsystem Breakdown

| Subsystem | Language | Key Libraries | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| `picasso-scanner` | **Go** | `aws-sdk-go-v2`, `golang.org/x/sync`, `zap` | High-speed concurrent AWS resource extraction and rate-limit management. |
| `picasso-agent-core` | **Python** | `google-genai`, `langgraph`, `pydantic-v2`, `networkx` | Security reasoning, attack path detection, and risk scoring. |
| `picasso-diagrams` | **Python** | `pydantic`, `lxml` / `xml.etree` | Generates valid `.excalidraw` JSON and `.drawio` mxGraph XML files. |
| `picasso-remediator`| **Python** | `tree-sitter`, `hcl2` | Synthesizes Terraform and CloudFormation countermeasure diffs. |

---

## 4. Why This Zero-Frontend Design Is Superior

1. **Frictionless Integration**: No web server, Node.js dependencies, port management, or frontend maintenance.
2. **Native Tooling Power**: Users get the full editing, zooming, exporting (PNG/SVG/PDF), and collaboration capabilities of **Excalidraw** and **Draw.io** out of the box.
3. **IDE-First Workflow**: Both `.excalidraw` and `.drawio` files open natively inside VS Code / IDE extensions or web browsers without any hosting infrastructure.
4. **GitOps Friendly**: Output diagram files and Markdown reports can be checked directly into source control for security architecture history and pull request audits.
