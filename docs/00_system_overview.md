# 00 - Picasso System Overview & Tech Split Architecture

## 1. Executive Summary

**Picasso** is an AI-augmented cloud security and infrastructure visualization platform. It addresses the complexity of modern multi-region, multi-account AWS environments by:
1. Concurrently scanning cloud configurations at wire speed.
2. Building a unified resource and topology dependency graph.
3. Engaging specialized AI reasoning agents to evaluate control plane, network perimeter, firewall, and IAM threat models.
4. Dynamically generating an interactive, live visual architectural drawing of the environment complete with attack paths and actionable remediation diffs.

---

## 2. Technology Split: Golang vs. Python Rationale

Picasso employs a **polyglot microservices architecture** that plays directly to the strengths of both Go and Python:

```
                                 ┌─────────────────────────┐
                                 │   Target AWS Account(s) │
                                 └────────────┬────────────┘
                                              │ (AWS SDK v2)
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ GOLANG SUBSYSTEM (High-Concurrency Scanner & Core Engine)                              │
│                                                                                        │
│  - Multi-region / Multi-account discovery workers (goroutines + worker pools)          │
│  - Token-bucket rate limiting (AWS API throttling avoidance)                           │
│  - Raw resource normalization & in-memory graph cache                                  │
│  - High-throughput gRPC / WebSocket streaming server                                   │
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ gRPC / Protobuf Stream
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ PYTHON SUBSYSTEM (Agent Intelligence & Security Reasoner)                               │
│                                                                                        │
│  - Agent Orchestrator (LangGraph / PydanticAI / LiteLLM / Gemini API)                  │
│  - Specialized Agents: Control Plane, Network/VPC, Firewall, IAM Blast Radius          │
│  - IAM Policy Simulation & Privilege Escalation Graph Traversal                        │
│  - Countermeasure Synthesizer (IaC Diff generator: Terraform/CloudFormation)          │
│  - Visual Layout Synthesizer (Transforms graph to React Flow / Excalidraw formats)     │
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ WebSockets / SSE / REST
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ FRONTEND PRESENTATION LAYER (Live Canvas & Security Dashboard)                         │
│                                                                                        │
│  - React / Next.js + React Flow (Infinite canvas with interactive nodes)              │
│  - Real-time vulnerability heatmaps and blast-radius highlights                        │
│  - One-click countermeasure inspection & remediation export                            │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Why Golang for the Scanner & Core Engine?
- **Extreme Concurrency**: AWS has hundreds of API endpoints per region across dozens of services. Goroutines and channels allow scanning dozens of regions and multiple accounts concurrently with minimal RAM usage.
- **Predictable Latency & Low Memory Footprint**: Crucial for running as a lightweight CLI, containerized worker, or serverless lambda function without JVM or Python runtime overhead.
- **Strict Typing & Strong AWS SDK (v2)**: Go's `aws-sdk-go-v2` provides strong typing, automatic pagination helpers, and native retry backoff mechanisms.
- **Fast Inter-Process Communication**: Serves as the high-speed gRPC server streaming normalized graph states to downstream consumers.

### Why Python for the Agent Intelligence Layer?
- **AI Ecosystem Leadership**: Direct native integration with modern LLM orchestration frameworks (LangGraph, Google GenAI SDK, Pydantic, Instructor).
- **Graph & Heuristic Analysis**: Deep integration with graph libraries (NetworkX, Pyvis) and constraint solvers for computing IAM privilege escalation chains and network reachability.
- **Rapid Prompt Engineering & Tool Calling**: Python's dynamic nature allows rapid iteration on agent prompts, multi-turn reasoning loops, and structured output parsing.
- **Synthesis of Complex Text & Code**: Ideal for parsing, validating, and generating AST-based Terraform/CloudFormation remediation patches.

---

## 3. Subsystem Breakdown

| Subsystem | Language | Key Libraries / Frameworks | Primary Responsibility |
| :--- | :--- | :--- | :--- |
| `picasso-scanner` | **Go** | `aws-sdk-go-v2`, `golang.org/x/sync`, `grpc-go`, `zap` | High-speed concurrent AWS resource extraction and rate-limit management. |
| `picasso-core` | **Go** | `gin` or `connect-go`, `protobuf`, `pebble` / `sqlite` | Normalized topology graph management and streaming service. |
| `picasso-agent-core` | **Python** | `google-genai`, `langgraph`, `pydantic-v2`, `networkx` | Agent orchestration, security posture reasoning, and attack path detection. |
| `picasso-remediator` | **Python** | `tree-sitter`, `hcl2`, `boto3` | Generating actionable IaC diffs and auto-quarantine actions. |
| `picasso-web` | **TypeScript** | `Next.js`, `React Flow`, `TailwindCSS`, `Zustand` | Interactive live drawing canvas and security control dashboard. |

---

## 4. Communication Protocol

1. **Scanner $\rightarrow$ Agent Layer**: 
   - Uses **gRPC** with Protobuf definitions (`picasso.proto`).
   - Binary serialization ensures zero serialization lag even when passing large JSON-like cloud inventories with thousands of resources.
2. **Agent Layer $\rightarrow$ Visualization Engine**:
   - Structured JSON schemas (`CanvasGraph`, `Node`, `Edge`, `SecurityBadge`, `RiskPath`).
3. **Core $\rightarrow$ Frontend**:
   - **WebSockets / Server-Sent Events (SSE)** for live rendering progress as each AWS region/service scan completes.
