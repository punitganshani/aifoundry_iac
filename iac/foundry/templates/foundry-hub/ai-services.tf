resource "azurerm_cognitive_account" "hub_openai" {
  name                = "${var.hub_name}-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags
  
  custom_subdomain_name = "${var.hub_name}-openai"
  public_network_access_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# ---------------------------------------------------------
# Model Deployment: GPT-4o
# ---------------------------------------------------------
resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.hub_openai.id
  rai_policy_name      = azurerm_cognitive_account_rai_policy.security_policy.name

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-05-13"
  }

  sku {
    name     = "Standard"
    capacity = 10 # TPM (Tokens Per Minute) / 1000. 10 = 10k TPM. Adjust as needed.
  }
}

# ---------------------------------------------------------
# Model Deployment: Text Embedding Ada 002
# ---------------------------------------------------------
resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.hub_openai.id
  rai_policy_name      = azurerm_cognitive_account_rai_policy.security_policy.name

  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  sku {
    name     = "Standard"
    capacity = 30 # 30k TPM for ingestion
  }
}

# ---------------------------------------------------------
# Connection: Link OpenAI to the Hub
# ---------------------------------------------------------
resource "azapi_resource" "hub_connection_openai" {
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name      = "aoai-connection" # Shortened to meet length requirements (max 32 chars)
  parent_id = azapi_resource.hub.id
  
  body = jsonencode({
    properties = {
      category      = "AzureOpenAI"
      target        = azurerm_cognitive_account.hub_openai.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cognitive_account.hub_openai.id
      }
    }
  })
}
