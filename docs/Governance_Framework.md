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

## 4. Responsible AI Standard

The platform enforces a "Safety First" approach using Azure AI Content Safety. These controls are applied at the **Hub level** and inherited by all deployments.

### 4.1. Safety Baseline (`security-baseline`)
The following content filters are enforced on all models (GPT-4o, etc.).

| Filter Category | Severity Threshold | Action | Source |
| :--- | :--- | :--- | :--- |
| **Hate** | **Medium** | Block | Prompt & Completion |
| **Sexual** | **Medium** | Block | Prompt & Completion |
| **Violence** | **Medium** | Block | Prompt & Completion |
| **Self-Harm** | **Medium** | Block | Prompt & Completion |
| **Profanity** | N/A | Block | Prompt |

> **Note:** "Medium" threshold means content classified as Medium or High severity is blocked. Only Low severity content is allowed. This is a strict baseline.

### 4.2. Adversarial Protection
To protect against manipulation and IP theft, the following shields are active:

*   **Jailbreak Detection**: Blocks attempts to bypass safety rules (e.g., DAN, hypothetical scenarios).
*   **Indirect Prompt Injection**: Blocks attacks embedded in documents/data processed by the model.
*   **Protected Material**:
    *   **Text**: Blocks known copyrighted text (e.g., song lyrics, book excerpts).
    *   **Code**: Blocks known public source code to prevent license contamination.

### 4.3. Custom Blocklists
The platform supports domain-specific blocklists.
*   **Financial Fraud**: Blocks terms related to "Ponzi schemes", "Guaranteed Returns", and known scam patterns.
*   **Implementation**: Managed via `azapi_resource` in Terraform.

### 4.4. Operational Gaps & Future Considerations
The current implementation provides *technical* guardrails. The following *process* gaps must be addressed:

1.  **Human Review Workflow**: Currently, blocked requests are logged but not reviewed.
    *   *Action:* Establish a "Safety Review Board" to analyze false positives/negatives.
2.  **Red Teaming**: No automated adversarial testing pipeline exists.
    *   *Action:* Integrate **PyRIT** (Python Risk Identification Tool) into the CI/CD pipeline.
3.  **Custom Classifiers**: The default filters may not catch business-specific risks (e.g., unapproved financial advice).
    *   *Action:* Train and deploy custom Azure AI Content Safety classifiers.
4.  **Groundedness Detection**: Hallucination detection is not currently enforced.
    *   *Action:* Enable "Groundedness" checks in Content Safety once the feature is generally available in the region.

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
