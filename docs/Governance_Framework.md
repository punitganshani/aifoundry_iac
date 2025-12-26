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

> **Note on Policy Enforcement:** The `deny-public-endpoints` policy (in `iac/platform/mg-policy`) conflicts with the default deployment scripts which enable public access for ease of setup. This policy should be assigned **after** initial deployment or with an exemption for the deployment agent.

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
    *   **Allowed Models:** `gpt-4o`, `gpt-4`, `gpt-35-turbo`, `text-embedding-ada-002` (Enforced via Azure Policy).
*   **Manages:** Shared Hub, Model Router, Centralized Cost Controls, Azure OpenAI Service.
*   **Accountability:** Platform compliance posture, safe operation of shared AI services, and controlled evolution of policies.

### Model Ops Team
**Role:** Responsible for the operational health and cost efficiency of AI models.
*   **Responsibilities:** Receives cost alerts (80% warning, 100% critical), manages Tokens Per Minute (TPM) allocations, optimizes router configurations.
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

## 5. Scaling Strategy: Multi-Project Architecture

To support scaling from one to dozens of AI applications, the platform uses a **Hub-and-Spoke** topology. While the default is a shared Hub, specific requirements for **Data Sensitivity** or **Workload Criticality** may dictate dedicated resources.

### 5.1. Project Archetypes
We define standard archetypes to simplify onboarding and resource allocation:

| Archetype | Use Case | Criticality | Sensitivity | Architecture Pattern |
| :--- | :--- | :--- | :--- | :--- |
| **Standard RAG** | Internal Chatbots, Q&A, Summarization | Low/Medium | Internal | **Shared Hub**: Uses shared Tokens Per Minute (TPM) quota and standard safety policies. |
| **Mission Critical** | Customer-facing Bots, Real-time Agents | **High** (SLA Required) | Internal | **Dedicated Throughput**: Uses shared Hub but with **Provisioned Throughput Units (PTU)** or a dedicated Model Deployment to guarantee latency/capacity. |
| **Sensitive / Regulated** | HR Data, PII, IP Generation | Medium/High | **High** (Confidential) | **Dedicated Hub**: Deploys a separate Hub and OpenAI instance to ensure complete data isolation and custom safety policies (e.g., zero data retention). |

### 5.2. Resource Sharing vs. Isolation Matrix

| Component | Standard Strategy | Critical Strategy | Sensitive Strategy |
| :--- | :--- | :--- | :--- |
| **Models (LLMs)** | Shared Standard Deployment | **Dedicated PTU Deployment** | Dedicated OpenAI Account |
| **Vector Search** | Dedicated Service (Standard SKU) | Dedicated Service (High Performance) | Dedicated Service (CMK Encryption) |
| **Safety Policies** | Inherited from Hub | Inherited from Hub | **Custom Policy** (Stricter/Specific) |
| **Network** | Shared VNET | Shared VNET | **Isolated VNET** (Peered) |

### 5.3. Quota Management & Capacity Planning

#### Assignment Process
Tokens Per Minute (TPM) are assigned via the **Terraform configuration** in the Hub.

1.  **Initial Allocation**: New deployments receive a standard baseline (e.g., 10k TPM) defined in `iac/foundry/templates/foundry-hub/ai-services.tf`.
2.  **Monitoring**: The **Model Ops Team** monitors utilization via Azure Monitor.
3.  **Scaling Request**: If a project requires more capacity:
    *   **Step 1**: Check subscription-level quota availability in the [Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_CognitiveServices/CognitiveServicesMenuBlade/~/Quota).
    *   **Step 2**: Update the `capacity` parameter in the Terraform `azurerm_cognitive_deployment` resource.
    *   **Step 3**: Apply the Terraform change to update the deployment in-place.

#### Reference Documentation
*   **[Manage Azure OpenAI Service Quota](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/quota)**: Official guide on understanding and requesting quota increases.
*   **[Azure OpenAI Service Models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)**: Availability of models per region.
*   **[Terraform: azurerm_cognitive_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_deployment)**: Documentation for the IaC resource used to set TPM.

*   **Baseline:** All Standard projects share the Hub's default Tokens Per Minute (TPM) pool.
*   **Trigger for Dedication:** If a project consistently consumes >30% of the shared pool or requires <200ms latency guarantees, it is migrated to a **Mission Critical** archetype.
*   **Chargeback:** Costs are tagged at the **Project Resource Group** level. Shared Hub costs are allocated based on token usage telemetry.

---

## 6. Decision Rights

- **Model approval & routing rules**: AI Platform Team
- **Use-case approval & business risk**: App Teams
- **Infrastructure enforcement**: Cloud Platform Team
- **Exceptions**: AI Platform Team (Time-bound and auditable)

---

## 7. Cross-Cutting Governance Principles

- **Production traffic must flow through the Model Router by default.**
- **Platform compliance ≠ use-case compliance**:
  - Platform Team owns policy design and enforcement.
  - App Teams own business intent and usage compliance.
- **All exceptions are time-bound and auditable.**
- **Breaking changes require advance notice and defined transition windows.**
