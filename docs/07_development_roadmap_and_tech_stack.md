# 07 - Development Roadmap, Monorepo Layout & Tech Stack

## 1. Streamlined Polyglot Monorepo Structure

Without the complexity of a frontend, Picasso is a lightweight, high-performance CLI pipeline:

```
picasso/
├── docs/                           # Architectural specs & design documents
│   ├── 00_system_overview.md
│   ├── 01_scanner_engine_golang.md
│   ├── 02_agent_intelligence_python.md
│   ├── 03_security_threat_model_and_rules.md
│   ├── 04_live_drawing_and_visualization.md
│   ├── 05_countermeasures_and_remediation.md
│   ├── 06_api_and_data_schemas.md
│   └── 07_development_roadmap_and_tech_stack.md
│
├── services/
│   ├── scanner-go/                 # GOLANG: High-concurrency AWS scanner CLI
│   │   ├── cmd/scanner/
│   │   ├── internal/collectors/
│   │   ├── go.mod
│   │   └── go.sum
│   │
│   └── agent-py/                   # PYTHON: Multi-agent reasoner & diagram generator
│       ├── src/
│       │   ├── agents/
│       │   ├── exporters/          # Excalidraw JSON & Draw.io XML generators
│       │   │   ├── excalidraw.py
│       │   │   └── drawio.py
│       │   ├── orchestrator/
│       │   └── schemas/
│       ├── pyproject.toml
│       └── requirements.txt
│
├── proto/                          # SHARED: Protocol Buffer definitions
│   └── picasso.proto
│
├── deploy/                         # Local development & mock AWS
│   ├── docker-compose.yml
│   └── localstack-init/
│
├── output/                         # Output artifacts directory
│   ├── topology.excalidraw         # Visual canvas for Excalidraw
│   ├── architecture.drawio         # Visual diagram for Draw.io
│   ├── security_report.md          # Markdown executive security report
│   └── remediations.tf             # Generated Terraform patches
│
├── .gitignore
├── Makefile                        # Unified build, test, and run CLI targets
└── README.md
```

---

## 2. Technology Stack Matrix

| Layer | Component | Choice | Rationale |
| :--- | :--- | :--- | :--- |
| **Scanner Core** | Language | **Go (Golang 1.23+)** | Maximum goroutine concurrency, zero runtime bloat, fast AWS API querying. |
| **AWS SDK** | Cloud Library | `aws-sdk-go-v2` | Official Go SDK with pagination helpers & exponential backoff. |
| **Inter-Service** | IPC Protocol | **gRPC or JSON Pipe** | Direct binary or stream piping from Go to Python. |
| **AI / Reasoning** | Language | **Python 3.12+** | LangGraph, Gemini API, Pydantic data modeling. |
| **AI Framework** | Orchestrator | **LangGraph / PydanticAI** | Deterministic multi-agent state machines and tool calling. |
| **Diagram Generation**| Excalidraw Exporter | `pydantic` JSON builder | Produces standard `.excalidraw` schema files. |
| **Diagram Generation**| Draw.io Exporter | `lxml` / `xml.etree` | Generates mxGraph XML with native collapsible containers. |
| **Local Mocking** | AWS Emulation | **LocalStack** | Offline testing without AWS costs or permission risks. |

---

## 3. Implementation Roadmap

```mermaid
gantt
    title Picasso Engineering Milestones
    dateFormat  YYYY-MM-DD
    section Phase 1: Go Scanner
    AWS SDK v2 Client & Rate Limiter :active, p1_1, 2026-10-05, 7d
    VPC, IAM & SG Discovery Workers  :p1_2, after p1_1, 10d
    JSON Graph & gRPC Streaming Out  :p1_3, after p1_2, 5d

    section Phase 2: Python Reasoning
    LangGraph State Machine Setup    :p2_1, after p1_2, 7d
    Specialized Security Agents      :p2_2, after p2_1, 10d
    Attack Path Traversal (NetworkX) :p2_3, after p2_2, 7d

    section Phase 3: Diagram Exporters
    Excalidraw JSON AST Generator    :p3_1, after p2_1, 7d
    Draw.io mxGraph XML Generator    :p3_2, after p3_1, 7d
    Hierarchical Container Layout    :p3_3, after p3_2, 5d

    section Phase 4: Remediation
    Terraform IaC Diff Synthesis     :p4_1, after p2_3, 7d
    Audit Report Generator (Markdown):p4_2, after p4_1, 5d
```
