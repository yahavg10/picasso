# Deep Dive: The Deterministic + AI Hybrid Architecture

## 1. The Pitfalls of "Pure LLM" Security Tools

A major mistake in modern AI engineering is treating Large Language Models as all-knowing computational engines. In security, this leads to fatal flaws:

| Problem | What Happens in Pure LLM Tools | Real-World Impact |
| :--- | :--- | :--- |
| **Hallucination** | The LLM invents CVE IDs or non-existent IAM permissions. | Security teams waste hours chasing phantom vulnerabilities. |
| **Context Window Bloat** | Passing 10,000 raw AWS JSON records exceeds context limits and causes needle-in-a-haystack recall failures. | High token costs; critical misconfigurations in line 8,432 are ignored. |
| **Non-Determinism** | Running the scan twice produces two different security scores on the exact same infrastructure. | Violates compliance audit standards and breaks CI/CD pass/fail gates. |
| **Inability to Compute Graphs** | LLMs struggle with multi-hop reachability and shortest-path graph calculations. | Multi-tier attack paths (e.g. Internet $\rightarrow$ SG $\rightarrow$ EC2 $\rightarrow$ Role $\rightarrow$ S3) go undetected. |

---

## 2. Picasso's Hybrid Architectural Pattern

Picasso solves this by establishing a strict boundary between **Deterministic Verification** and **Generative Reasoning**:

```
                       ┌────────────────────────────────────────────────────────┐
                       │           Normalized AWS Topology Graph                │
                       │           (Ingested by Go Scanner)                     │
                       └──────────────────────────┬─────────────────────────────┘
                                                  │
                                                  ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ DETERMINISTIC REASONING ENGINE (Go + NetworkX / Graph Algorithms)                      │
│                                                                                        │
│  - Fact 1: Route Table directs 0.0.0.0/0 to igw-01                                     │
│  - Fact 2: Security Group sg-01 allows Ingress 0.0.0.0/0:22                            │
│  - Fact 3: Instance i-01 has InstanceProfile attached to Role-Admin                    │
│  - Fact 4: Shortest Attack Path mathematically proven: [Internet -> i-01 -> Role-Admin]│
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ Proven Graph Facts + Attack Paths
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ GENERATIVE AI REASONING AGENT (Gemini 1.5 Pro / Flash via LangGraph)                   │
│                                                                                        │
│  - Contextual Analysis: What does this workload actually do? (Tags, naming, config)    │
│  - Threat Narration: Explains the attack vector in clear executive & technical terms   │
│  - IaC Diff Synthesis: Generates precise Terraform/CloudFormation code fixes           │
│  - Visual Element Generation: Formats Excalidraw / Draw.io diagram geometry & labels   │
└─────────────────────────────────────────────┬──────────────────────────────────────────┘
                                              │ Structured Output (Pydantic Schema)
                                              ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ OUTPUT ARTIFACTS: topology.drawio | topology.excalidraw | report.md | remediations.tf   │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Division of Labor

### What the Deterministic Engine Owns (100% Code):
- **Graph Traversal**: Finding shortest paths from public subnets to crown-jewel assets.
- **Set Theory & Logic Evaluation**: Evaluating whether an IAM policy statement contains `Action: "*"` on `Resource: "*"`.
- **IP & CIDR Parsing**: Checking whether `198.51.100.0/24` falls inside `10.0.0.0/16`.
- **CIS Benchmark Thresholds**: Checking whether CloudTrail logging is active or MFA is enabled.

### What the AI Agent Owns (LLM Strength):
- **Threat Actor Emulation**: Simulating how an adversary might weaponize the discovered graph chain.
- **Context Synthesis**: Understanding that `OrderProcessor-Prod` is mission-critical while `Sandbox-Temp` is low-priority, adjusting urgency accordingly.
- **Code Synthesis**: Generating syntactically valid Terraform HCL patches that preserve existing tags and resource dependencies.
- **Diagram Narration**: Crafting human-friendly diagram callouts and threat descriptions suitable for presentation to engineering leaders and CISOs.

---

## 4. Structured Output Guardrails

To prevent the LLM from drifting, Picasso uses **schema-constrained generation**:

```python
class ProvenAttackPath(BaseModel):
    source_arn: str
    target_arn: str
    hops: List[str]
    proven_by_engine: bool = True

class AgentEnrichedFinding(BaseModel):
    finding_id: str
    attack_path: ProvenAttackPath
    executive_summary: str = Field(description="2-sentence summary for CISO")
    technical_exploit_narrative: str = Field(description="Step-by-step ATT&CK simulation")
    terraform_remediation_diff: str = Field(description="Syntactically valid HCL diff")
```

The LLM is provided the `ProvenAttackPath` generated by NetworkX and is strictly forbidden from altering the nodes or edges. Its sole task is enrichment and remediation synthesis.

---

## 5. Interview Talking Points

When asked: *"Why did you use AI in this project instead of just traditional linters like tfsec or Checkov?"*

**The Winning Answer:**
> *"Linters check static code, but real attacks exploit dynamic cloud relationships—like an EC2 instance in one VPC assuming a role that accesses an S3 bucket in another account. Traditional tools produce hundreds of disconnected alerts. We use deterministic graph algorithms to mathematically prove the attack path, and then use AI agents to contextualize the business impact and generate exact, non-breaking remediation code."*
