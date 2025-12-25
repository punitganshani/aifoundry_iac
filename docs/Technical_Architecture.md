# AI Foundry Technical Architecture

**Context:** This document details the technical implementation of the Azure AI Foundry environment, including networking, RAG patterns, and automation logic.

---

## 1. Architecture Overview

The solution implements a **Hub-and-Spoke** model for AI services.
*   **Hub**: Centralized, shared resources (OpenAI, Storage, Key Vault, ACR) managed by the Platform Team.
*   **Spoke (Project)**: Application-specific resources (Search, Agent Tools) managed by App Teams.

### Architecture Diagram

```mermaid
graph TD
    User[User / CI/CD] -->|Run Script| DeployScript[deploy_governance.ps1]
    
    subgraph "Azure Subscription"
        direction TB
        
        subgraph "Governance Layer"
            Policy[Azure Policy]
            Tags[Tag Enforcement]
            RBAC[RBAC Roles]
        end
        
        DeployScript -->|Apply| Policy
        
        subgraph "AI Foundry Hub (Shared)"
            Hub[AI Foundry Hub]
            OpenAI[Azure OpenAI]
            Embed[Embedding Model]
            Phi4[Phi-4 Serverless]
            RAI[RAI Safety Policy (Security Baseline)]
            Blocklist[Custom Blocklist]
            Router[Model Router]
            Storage[Storage Account]
            KV[Key Vault]
            ACR[Container Registry]
            
            OpenAI -->|Enforces| RAI
            OpenAI -->|Enforces| Blocklist
            Hub -->|Uses| Storage
            Hub -->|Uses| KV
            Hub -->|Uses| ACR
            Hub -->|Uses| OpenAI
            Hub -->|Uses| Embed
            Hub -->|Uses| Phi4
            Router -->|Proxies| OpenAI
            Router -->|Proxies| Phi4
        end
        
        subgraph "AI Foundry Project (Workload)"
            Project[AI Project]
            Search[Azure AI Search]
            AgentTools[Agent Tools Project]
            Project -->|Links to| Hub
            Project -->|Owns| Search
            AgentTools -->|Links to| Hub
        end
        
        DeployScript -->|Terraform Apply| Hub
        DeployScript -->|Terraform Apply| Project
    end
    
    Policy -.->|Blocks Non-Compliant| Hub
    Policy -.->|Blocks Non-Compliant| Project
```

---

## 2. Networking & Security

**Status:** Implemented (Single VNET Hub-Spoke)

### Topology
*   **VNET:** `vnet-ai-foundry` (East US) - `10.0.0.0/16`
*   **Subnets:**
    *   `snet-private-endpoints` (`10.0.1.0/24`): Dedicated for PaaS Private Endpoints.
    *   `snet-compute` (`10.0.2.0/24`): Hosting subnet for AI Compute Instances.

### Connectivity
All critical PaaS services have **Public Network Access disabled** (or restricted) and are accessed via **Private Endpoints**.

| Service | Private Endpoint | DNS Zone |
| :--- | :--- | :--- |
| **Azure OpenAI** | `{hub}-openai-pe` | `privatelink.openai.azure.com` |
| **Foundry Hub** | `{hub}-ws-pe` | `privatelink.api.azureml.ms` |
| **Storage (Blob)** | `{hub}-st-blob-pe` | `privatelink.blob.core.windows.net` |
| **Storage (File)** | `{hub}-st-file-pe` | `privatelink.file.core.windows.net` |
| **Key Vault** | `{hub}-kv-pe` | `privatelink.vaultcore.azure.net` |
| **AI Search** | `{project}-search-pe` | `privatelink.search.windows.net` |
| **Container Registry** | `{hub}-acr-pe` | `privatelink.azurecr.io` |
| **Notebooks** | N/A (via Hub) | `privatelink.notebooks.azure.net` |

### Traffic Flow
1.  **User -> Hub:** Users access the Foundry Portal. The Portal communicates with the Hub API via the public control plane (secured by Entra ID), but data plane operations (e.g., accessing storage, running flows) originate from the user's client or the Compute Instance.
2.  **Compute -> Storage/KeyVault:** Traffic originates from `snet-compute`, resolves the private IP via Private DNS, and travels over the Microsoft Backbone to the Private Endpoint in `snet-private-endpoints`.
3.  **RAG Ingestion:** Compute Instance reads raw files from Storage (Private), chunks them, sends to OpenAI for Embedding (Private), and writes to AI Search (Private).

### Public Access & Deployment Agents
*   **Current State:** `public_network_access_enabled = true` for core resources to facilitate deployment via standard runners.
*   **Production Recommendation:** Set to `false` and deploy **Self-Hosted Agents** inside the VNET.

---

## 3. GenAI RAG Pattern

The standard pattern for "Chat with your Data" workloads:

### Data Flow

#### Phase 1: Ingestion (Indexing)
1.  **Upload:** Data files are uploaded to the Project's Blob Storage.
2.  **Chunking:** Prompt Flow / Indexing Job splits documents into manageable chunks.
3.  **Embedding:** Chunks are sent to the Hub's `text-embedding-ada-002` model.
4.  **Storage:** Vectors and metadata are stored in the Project's Azure AI Search index.

#### Phase 2: Retrieval (Inference)
1.  **Query:** User submits a question via the App/Agent.
2.  **Intent:** (Optional) LLM rewrites the query for better search.
3.  **Vector Search:** Query is embedded and sent to Azure AI Search.
4.  **Ranking:** Top K results are retrieved (optionally re-ranked using Semantic Ranker).
5.  **Generation:** Retrieved context + Original Query are sent to `gpt-4o`.
6.  **Response:** Answer is generated and returned to the user.

### Implementation Details
*   **Hub Infrastructure**: Deploys shared `text-embedding-ada-002` and `gpt-4o`.
*   **Project Infrastructure**: Deploys isolated Azure AI Search service (Standard SKU) with Private Endpoint.
*   **Orchestration**: `deploy_governance.ps1` passes network context (Subnet ID, DNS Zone ID) from Hub to Project.

---

## 4. Automation & Observability

### Cost Automation
*   **Resource:** `ai-governance-logic-stop-computes` (Logic App).
*   **Trigger:** Nightly at 19:00 UTC.
*   **Action:** Queries Azure Resource Graph for running Compute Instances and stops them via Managed Identity.

### Observability
*   **Dashboard:** `ai-governance-dashboard`
*   **Metrics:** Cost (Daily), Safety Events (Blocklist hits), Latency.

---

## 5. Implementation Gaps & Roadmap

| Area | Requirement | Current State | Gap/Action |
| :--- | :--- | :--- | :--- |
| **Resilience** | Regional Redundancy | Single Region (East US), LRS Storage. | **Gap:** Need secondary region & GRS. |
| **Security** | Fully Private | Public Access enabled for deployment ease. | **Gap:** Need Self-Hosted Agents. |
| **ACR** | Network Rules | No explicit firewall rules. | **Gap:** Add `network_rules` to Terraform. |
