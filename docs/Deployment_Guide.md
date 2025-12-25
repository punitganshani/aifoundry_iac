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

**Hub Configuration (`iac/foundry/templates/foundry-hub/`)**
- **Models (`ai-services.tf`)**: Configure deployed models (e.g., GPT-4o, Phi-4 Serverless).
- **Safety (`safety.tf`)**: Adjust Content Safety policies and RAI blocklists.
- **Networking (`apim.tf`)**: Modify the APIM Model Router configuration.
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
    capacity = 20 # 20k TPM
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
