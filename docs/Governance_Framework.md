# AI Foundry Governance Framework

**Context:** This document defines the governance principles, operating model, and cost control policies for the Azure AI Foundry environment. It serves as the "Rule Book" for how AI services are consumed, secured, and managed.

---

## 1. Core Principles

### Invariants
1.  **Subscription Hierarchy**: Subscriptions exist **only under Tier management groups**.
2.  **Control Plane**: Foundry is the **AI control plane**, not a new platform.
3.  **Project Mapping**: Foundry Projects map to **apps / use cases**.
4.  **Tier Consistency**: Tiers do **not** change how projects are defined.
5.  **Environment Separation**: Prod and Non-Prod are always separated.
6.  **Disaster Recovery**: DR is **opt-in and explicit**.

### Governance Scope
- **Prod**: Strict governance, safety default-on.
- **Non-Prod**: Relaxed content safety, but infrastructure safety remains.

### Mandatory Tags
All resources must have the following tags for tracking and compliance:
- `AppId`
- `CostCenter`
- `Environment`
- `Tier`
- `DataClassification`
- `DR-Approved`

---

## 2. Roles & Responsibilities

### AI Platform Team
**Role:** Owns Azure AI Foundry governance, shared AI services, and platform-wide standards.
*   **Owns:** Model allow-lists, Responsible AI policies (Security Baseline), Architecture standards (Golden Paths).
*   **Manages:** Shared Hub, Model Router, Centralized Cost Controls, Azure OpenAI Service.
*   **Accountability:** Platform compliance posture, safe operation of shared AI services, and controlled evolution of policies.

### Model Ops Team
**Role:** Responsible for the operational health and cost efficiency of AI models.
*   **Responsibilities:** Receives cost alerts (80% warning, 100% critical), manages TPM allocations, optimizes router configurations.
*   **Accountability:** Model performance, latency, and token efficiency.

### AI App Team
**Role:** Owners of specific AI projects/applications.
*   **Responsibilities:** Builds apps using approved models, manages RAG data/indices, ensures use-case compliance (Prompt intent, data usage).
*   **Managed Services:** AI Foundry Projects, Azure AI Search, Agent Tools, Prompt Flow.
*   **Accountability:** Business outcomes, application reliability, and cost control within project allocations.

### Cloud Platform Team
**Role:** Provides and secures the foundational Azure infrastructure.
*   **Responsibilities:** Networking (VNETs, Private DNS), Identity (Entra ID, RBAC), Infrastructure Resilience (DR).
*   **Managed Services:** Key Vault, Storage Account, Container Registry, Azure Networking, Azure Policy.
*   **Accountability:** Infrastructure security, availability, and policy compliance.

---

## 3. Cost Governance Policy

Cost control is built-in via Terraform and Azure Policy.

### Budgeting
*   **Scope:** Resource Group level (`rg-ai-foundry-prod`).
*   **Budget:** Monthly fixed amount (Default: $1000 USD).
*   **Reset:** Calendar Month.

### Alerting Matrix
| Threshold | Severity | Audience | Intent |
| :--- | :--- | :--- | :--- |
| **80%** | Warning | **AI App Team**, **Model Ops Team** | "Check inference rates." |
| **100%** | Critical | **Platform Team**, **AI App Team**, **Model Ops Team** | "Budget exhausted. Scaling restricted." |

### Service-Specific Strategies
| Service | Control Strategy | Status |
| :--- | :--- | :--- |
| **AI Compute Instances** | **Nightly Shutdown Logic App** (19:00 UTC). | **Active** |
| **Azure OpenAI** | APIM Rate Limits & Quotas. | **Active** |
| **Azure AI Search** | Scale down to 1 replica off-hours (Script). | Planned |

---

## 4. Responsible AI & Safety

*   **Security Baseline Policy (`security-baseline`)**: High-severity thresholds for Hate, Sexual, Violence, and Self-Harm.
*   **Prompt Shields**: Jailbreak and indirect attack protection enabled.
*   **Blocklists**: Centralized "Financial Fraud Terms" blocklist.
*   **Protected Material**: Detection enabled for copyrighted text/code.

---

## 5. Decision Rights

- **Model approval & routing rules**: AI Platform Team
- **Use-case approval & business risk**: App Teams
- **Infrastructure enforcement**: Cloud Platform Team
- **Exceptions**: AI Platform Team (Time-bound and auditable)

---

## 6. Cross-Cutting Governance Principles

- **Production traffic must flow through the Model Router by default.**
- **Platform compliance ≠ use-case compliance**:
  - Platform Team owns policy design and enforcement.
  - App Teams own business intent and usage compliance.
- **All exceptions are time-bound and auditable.**
- **Breaking changes require advance notice and defined transition windows.**
