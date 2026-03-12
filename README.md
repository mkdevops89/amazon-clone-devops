# Phase 16: Platform Operations, Streaming, & Maintenance (SRE)

## Overview
Phase 16 elevates the architectural maturity of the platform from "Builder" to "Enterprise Operator". It introduces Event-Driven Architecture (EDA) via message streaming, formalizes operational runbooks, automates zero-downtime maintenance modes, and implements a rigorous process for auditing and decommissioning technical debt.

## Architecture Highlights
- **Event-Driven Streaming (Redpanda):** Deployed a lightweight, FinOps-optimized C++ Kafka alternative (`Redpanda`) for handling asynchronous event streams (`audit-events`, `product-updates`).
- **Zero-Downtime Maintenance:** Implemented ArgoCD-aware scaling scripts to gracefully drain traffic and halt backend pods without tripping CI/CD self-healing mechanisms.
- **Technical Debt Management:** Formalized a deprecation cycle for legacy ClickOps scripts and unused Helm charts.

## Key Files & Directories
- `ops/kafka/helm/values.yaml`: FinOps-tuned Helm values for single-node Redpanda.
- `ops/scripts/maintenance/`: Shell scripts (`enter-maintenance.sh`, `exit-maintenance.sh`) for safe cluster scaling.
- `docs/runbooks/`: Professional SRE playbooks for Kafka operations and cluster maintenance.
- `docs/platform-review/`: Documentation for technical debt and cost optimization.
- `phase_16_walkthrough.md`: Step-by-step commands to deploy Redpanda and test the maintenance automation.
