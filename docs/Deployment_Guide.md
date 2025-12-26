# Deployment Guide

This repository uses a PowerShell orchestration script to deploy the entire governance and infrastructure stack.

## Prerequisites
- **Azure CLI** (`az login`)
- **Terraform** (v1.0+)
- **PowerShell** (Core or Windows PowerShell)

## Quick Start

Run the deployment script from the root of the repository:

```powershell
.\deploy_governance.ps1 -SubscriptionId "<your-subscription-id>" -ProjectName "my-ai-project"
```

To speed up deployment (skip state refresh and increase parallelism):
```powershell
.\deploy_governance.ps1 -SubscriptionId "<your-subscription-id>" -FastDeploy
```

## Configuration Options

### 1. Deployment Script Parameters (`deploy_governance.ps1`)

You can customize the deployment using the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `SubscriptionId` | The Azure Subscription ID to deploy into. | (Interactive selection) |
| `ResourceGroupName` | Name of the resource group to create/update. | `rg-ai-foundry-prod` |
| `Location` | Azure region for resources. | `eastus` |
| `ProjectName` | Name of the AI Project (and prefix for resources). | `my-genai-app03` |

### 2. Infrastructure Customization

The infrastructure is defined in Terraform modules located in `iac/foundry/templates/`.

> **Security Note:** The provided Terraform templates default to `public_network_access_enabled = true` for the Hub, Key Vault, and Storage to facilitate easy deployment from GitHub Actions or local machines. **For Production environments, you must set this to `false`** and use Self-Hosted Agents within the VNET.

**Hub Configuration (`iac/foundry/templates/foundry-hub/`)**
- **Models (`ai-services.tf`)**: Configure deployed models (e.g., GPT-4o, Phi-4 Serverless).
- **Safety (`safety.tf`)**: Adjust Content Safety policies and RAI blocklists.
- **Networking (`main.tf` / `variables.tf`)**: Update `vnet_address_space` and subnet prefixes to match your Enterprise IPAM plan. **Ensure `snet-apim` is at least `/27`.**
- **Access (`rbac.tf`)**: Update role assignments for the Hub.

**Project Configuration (`iac/foundry/templates/project-genai-rag/`)**
- Customize the specific resources required for your GenAI application (Key Vault, Storage, etc.).

## Extending the Setup

Since this repository uses Terraform, most customizations involve modifying the `.tf` files in `iac/foundry/templates/foundry-hub/`.

### 1. Adding a New Model (Azure OpenAI)
To deploy another model (e.g., `gpt-35-turbo`) to the Azure OpenAI instance:

1. Open `iac/foundry/templates/foundry-hub/ai-services.tf`.
2. Add a new `azurerm_cognitive_deployment` block:

```hcl
resource "azurerm_cognitive_deployment" "gpt35" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.hub_openai.id
  rai_policy_name      = azurerm_cognitive_account_rai_policy.fsi_policy.name

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0125"
  }

  sku {
    name     = "Standard"
    capacity = 20 # 20k Tokens Per Minute
  }
}
```

### 2. Adding a Serverless Model (MaaS)
To add a "Model as a Service" endpoint (e.g., Llama-3, Phi-3):

1. Open `iac/foundry/templates/foundry-hub/ai-services.tf`.
2. Add a new `azapi_resource` block:

```hcl
resource "azapi_resource" "llama3_serverless" {
  type      = "Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2024-04-01-preview"
  name      = "${var.hub_name}-llama-3-8b"
  parent_id = azapi_resource.hub.id
  location  = var.location
  tags      = var.tags
  
  body = jsonencode({
    properties = {
      modelSettings = {
        modelId = "azureml://registries/azureml/models/Llama-3-8b-chat/versions/1"
      }
    }
  })
}
```

#### Advanced Configuration (Marketplace Offers)
For models that require specific Marketplace offers (e.g., specific SKUs or terms), you can include the `offer` and `sku` blocks:

```hcl
resource "azapi_resource" "phi4_serverless" {
  type      = "Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2024-04-01-preview"
  name      = "${var.hub_name}-phi-4"
  parent_id = azapi_resource.hub.id
  location  = var.location
  tags      = var.tags

  body = jsonencode({
    properties = {
      authMode = "Key"
      modelSettings = {
        modelId = "azureml://registries/azureml/models/Phi-4/versions/3"
      }
      # Optional: Required for some Marketplace models
      # offer = {
      #   offerName = "Phi-4"
      #   publisher = "Microsoft"
      # }
    }
    # sku = {
    #   name = "Consumption"
    # }
  })
}
```

### 3. Modifying Safety Filters
To change the content safety thresholds (e.g., from "High" to "Medium"):

1. Open `iac/foundry/templates/foundry-hub/safety.tf`.
2. Locate the `azurerm_cognitive_account_rai_policy` resource.
3. Adjust the `severity_threshold` in the `content_filter` blocks:

```hcl
  content_filter {
    name              = "Hate"
    filter_enabled    = true
    block_enabled     = true
    severity_threshold = "Medium" # Changed from High
    source            = "Prompt"
  }
```

## Troubleshooting

### Common Issues

#### 1. "Quota Exceeded" Error
*   **Symptom**: Deployment fails with `Code="QuotaExceeded"`.
*   **Cause**: The subscription does not have enough TPM quota for the requested model (e.g., GPT-4o) in the target region.
*   **Fix**:
    1.  Check quota in [Azure Portal](https://portal.azure.com/#view/Microsoft_Azure_CognitiveServices/CognitiveServicesMenuBlade/~/Quota).
    2.  Request a quota increase.
    3.  Or, reduce the `capacity` in `ai-services.tf`.

#### 2. "PrincipalNotFound" Error
*   **Symptom**: Role assignment fails with `PrincipalNotFound`.
*   **Cause**: The Managed Identity for the Hub was just created, and Entra ID replication hasn't finished.
*   **Fix**: Wait 1-2 minutes and re-run the deployment script.

#### 3. "Public Network Access Denied"
*   **Symptom**: Terraform cannot read/write to the Storage Account or Key Vault.
*   **Cause**: The deployment machine is not on the allowed IP list, or public access is disabled.
*   **Fix**: Ensure the deployment script is running from an agent with network line-of-sight, or temporarily enable `public_network_access_enabled = true` in the Terraform variables.
