# Azure AI Foundry Governance

> **Note:** This governance approach is an **example** designed for a scenario where an organization has separate Platform, AI App, and Model Ops teams. This model should be evaluated and tailored to your specific organizational structure and requirements before adoption.

This repository contains the reference implementation for a governed, secure, and scalable **Azure AI Foundry** environment. It provides an infrastructure setup for AI Landing Zone with safety, cost management, and operational recommended practices.

## 📚 Documentation

*   **[Governance Framework](docs/Governance_Framework.md)**: The "Rule Book". Defines the core principles, team roles, responsibilities, and cost policies.
*   **[Technical Architecture](docs/Technical_Architecture.md)**: The "Blueprints". Details the network topology, RAG patterns, and component diagrams.
*   **[Deployment Guide](docs/Deployment_Guide.md)**: Instructions on how to deploy and configure the environment using the provided scripts and Terraform modules.

## 🎯 Project Philosophy

> *“We build guardrails first, then intelligence, then scale.”*

This project implements a phased approach to AI governance, moving from strict "hard rails" to flexible "golden paths".

### Governance Phases

1.  **Phase 0 — Alignment & Invariants**: Establishing the immovable rules and operating model.
2.  **Phase 1 — Guard Rails**: Infrastructure safety via Policy-as-Code, mandatory tagging, and RBAC.
3.  **Phase 2 — Control Plane Governance**: Centralizing AI-specific controls (RAI policies, blocklists) in the Hub.
4.  **Phase 3 — Golden Paths**: Providing reusable, pre-secured IaC modules for app teams.
5.  **Phase 4 — Disaster Recovery**: Making DR a repeatable, opt-in capability.
6.  **Phase 5 — Feedback Loops**: Implementing dashboards, alerts, and cost automation.
7.  **Phase 6 — Scale**: Automating model upgrades and routing.

## 🚀 Key Features

*   **Hub-and-Spoke Architecture**: Centralized management of expensive/sensitive resources (OpenAI, Key Vault) with isolated project workspaces.
*   **Security First**: Private Endpoints for all PaaS services, strict network isolation, and RBAC least privilege.
*   **Responsible AI (RAI)**: Centralized content safety policies and custom blocklists enforced at the Hub level.
*   **Cost Control**: Automated nightly shutdown of compute instances and budget alerts.
*   **Infrastructure as Code**: Fully defined in Terraform with a PowerShell orchestration wrapper.

## 📂 Repository Structure

*   `docs/`: Documentation for architecture, governance, and deployment.
*   `iac/foundry/templates/`: Reusable Terraform modules for Hub and Projects.
*   `iac/platform/`: Platform-level infrastructure (Policy, Monitoring, RBAC).
*   `deploy_governance.ps1`: Main deployment orchestration script.

---
*For detailed deployment instructions, please refer to the [Deployment Guide](docs/Deployment_Guide.md).*
