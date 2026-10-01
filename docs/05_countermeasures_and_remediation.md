# 05 - Countermeasures, Automated Remediation & IaC Diffing

## 1. Overview & Philosophy

Finding vulnerabilities without offering actionable remediations creates alert fatigue. Picasso's **Remediation Engine** translates detected risks into production-ready, testable countermeasure packages with **Human-in-the-Loop (HITL)** guardrails.

---

## 2. Remediation Modalities

Picasso supports three distinct modes of countermeasure deployment:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Picasso Remediation Modes                       │
├──────────────────────────┬──────────────────────┬──────────────────────┤
│ 1. IaC Diff Synthesis    │ 2. Automated Hotfix  │ 3. Policy Compiler   │
│ (Preventative / GitOps)  │ (Active Quarantine)  │ (Least-Privilege)    │
│                          │                      │                      │
│ - Terraform HCL Diffs    │ - Revoke SG Ingress  │ - Synthesizes narrow │
│ - CloudFormation YAML    │ - Inactivate API Key │   IAM policies from  │
│ - Submitted as GitHub PR │ - Detach Wildcard    │   CloudTrail logs    │
└──────────────────────────┴──────────────────────┴──────────────────────┘
```

---

## 3. IaC Diff Synthesis (Terraform Example)

When the Python reasoning agent flags a security misconfiguration (e.g. `FW-001: Unrestricted SSH Ingress`), it synthesizes an exact `git diff` against the infrastructure code:

### Example: Security Group Ingress Fix
```diff
 resource "aws_security_group" "web_sg" {
   name        = "web-server-sg"
   description = "Allow inbound HTTP and management traffic"
   vpc_id      = aws_vpc.main.id
 
-  # VULNERABLE: Open to entire world
-  ingress {
-    description = "SSH from anywhere"
-    from_port   = 22
-    to_port     = 22
-    protocol    = "tcp"
-    cidr_blocks = ["0.0.0.0/0"]
-  }
+  # REMEDIATED: Replaced direct SSH with AWS Systems Manager (SSM)
+  # Alternatively restricted to bastion / corporate VPN CIDR:
+  ingress {
+    description = "SSH from Corporate VPN"
+    from_port   = 22
+    to_port     = 22
+    protocol    = "tcp"
+    cidr_blocks = ["198.51.100.0/24"]
+  }
 }
```

---

## 4. Least-Privilege IAM Policy Generation

For overly permissive roles (e.g., wildcard `Action: "*"`), Picasso uses the Python agent to:
1. Cross-reference the role's ARN with CloudTrail event history (if available) or resource dependencies.
2. Compile a tight, least-privilege policy document.

### Example: Overly Broad Lambda Execution Role Fix
```json
// BEFORE: Dangerous Wildcard Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}

// AFTER: Synthesized Least-Privilege Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBTableAccessOnly",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/Orders"
    },
    {
      "Sid": "CloudWatchLogStreamsOnly",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/OrderProcessor:*"
    }
  ]
}
```

---

## 5. Emergency Auto-Quarantine (Runtime Hotfixes)

For critical emergencies (e.g., active root access key leaked, or database port open to internet during active threat), Picasso can optionally trigger targeted AWS SDK mutations through an authorized IAM role:

### Quarantine Actions Supported:
1. `iam:UpdateAccessKey(Status='Inactive')` - Instantly disables a compromised credential.
2. `ec2:RevokeSecurityGroupIngress(...)` - Tears down open `0.0.0.0/0` ingress rules without terminating instances.
3. `iam:AttachRolePolicy(PolicyArn="arn:aws:iam::aws:policy/AWSSenyAll")` - Imposes immediate temporary quarantine on a compromised IAM role.

---

## 6. Safety & Human-in-the-Loop (HITL) Controls

- **No Blind Deletions**: Picasso never automatically terminates compute resources, deletes databases, or deletes S3 buckets.
- **Dry-Run Validation**: Every AWS API remediation supports `--dry-run` to test permission and impact before applying.
- **Rollback Snapshots**: Prior to modifying any Security Group or IAM Policy, Picasso records the pre-change state in local state storage to allow one-click rollback.
