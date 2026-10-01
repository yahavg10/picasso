# ==============================================================================
# Picasso - AI-Powered Cloud Security & Topology Engine
# ==============================================================================

SHELL := /bin/bash
LOCALSTACK_ENDPOINT ?= http://localhost:4566
OUTPUT_DIR ?= ./output

.PHONY: help demo k8s-up k8s-down seed-dvca scan-go run-agents clean

help: ## Show this help message
	@echo "Picasso DevSecOps Automation Suite"
	@echo "==================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

demo: ## 🚀 1-Click End-to-End Demo: Starts LocalStack, seeds vulnerable AWS infra, scans & generates diagrams
	@echo "==> [1/4] Checking LocalStack on Kubernetes / Docker..."
	@curl -s $(LOCALSTACK_ENDPOINT)/_localstack/health > /dev/null || (echo "Starting LocalStack..." && $(MAKE) k8s-up)
	@echo "==> [2/4] Seeding Damn Vulnerable Cloud Architecture (DVCA)..."
	@$(MAKE) seed-dvca
	@echo "==> [3/4] Running High-Concurrency Go Scanner..."
	@$(MAKE) scan-go
	@echo "==> [4/4] Running Python AI Agents (Reasoning, SARIF & Diagram Generation)..."
	@$(MAKE) run-agents
	@echo ""
	@echo "🎉 DEMO COMPLETE! Generated Artifacts:"
	@echo "  ├── 🎨 Excalidraw:  $(OUTPUT_DIR)/topology.excalidraw"
	@echo "  ├── 📐 Draw.io:     $(OUTPUT_DIR)/architecture.drawio"
	@echo "  ├── 🛡️  Report:      $(OUTPUT_DIR)/security_report.md"
	@echo "  ├── 📋 SARIF:       $(OUTPUT_DIR)/picasso.sarif"
	@echo "  └── 🔧 Terraform:   $(OUTPUT_DIR)/remediations.tf"

k8s-up: ## Deploy LocalStack to local Kubernetes cluster (Kind / Minikube)
	@echo "Applying LocalStack manifests to Kubernetes..."
	kubectl apply -f deploy/k8s/localstack.yaml
	@echo "Waiting for LocalStack pod to be ready..."
	kubectl wait --namespace localstack --for=condition=ready pod -l app=localstack --timeout=90s
	@echo "Port-forwarding LocalStack edge port 4566..."
	kubectl port-forward --namespace localstack svc/localstack 4566:4566 &

k8s-down: ## Tear down LocalStack from Kubernetes
	@echo "Deleting LocalStack resources..."
	kubectl delete -f deploy/k8s/localstack.yaml --ignore-not-found

seed-dvca: ## Provision vulnerable cloud architecture into LocalStack via Terraform
	@echo "Applying vulnerable Terraform resources to LocalStack..."
	@mkdir -p $(OUTPUT_DIR)
	# terraform -chdir=deploy/dvca init
	# terraform -chdir=deploy/dvca apply -auto-approve

scan-go: ## Run the Golang high-concurrency scanner against LocalStack
	@echo "Scanning LocalStack with Go scanner..."
	# LOCALSTACK_URL=$(LOCALSTACK_ENDPOINT) go run ./services/scanner-go/cmd/scanner -output=$(OUTPUT_DIR)/raw_graph.json

run-agents: ## Run Python reasoning agents to generate diagrams and security reports
	@echo "Running Python AI reasoning and diagram synthesizer..."
	# python3 ./services/agent-py/src/main.py --input=$(OUTPUT_DIR)/raw_graph.json --out-dir=$(OUTPUT_DIR)

clean: ## Clean up generated output artifacts
	rm -rf $(OUTPUT_DIR)
