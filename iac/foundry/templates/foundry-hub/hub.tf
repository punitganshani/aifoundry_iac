resource "azurerm_storage_account" "hub_storage" {
  name                     = replace("${var.hub_name}st", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
  shared_access_key_enabled = false
  tags                     = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_key_vault" "hub_kv" {
  name                        = "${var.hub_name}-kv"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  public_network_access_enabled = true
  tags                        = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

resource "azurerm_log_analytics_workspace" "hub_law" {
  name                = "${var.hub_name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "hub_appinsights" {
  name                = "${var.hub_name}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.hub_law.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_container_registry" "hub_acr" {
  name                = replace("${var.hub_name}acr", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = true
  public_network_access_enabled = true # Enabled for deployment.
  tags                = var.tags
}

# ---------------------------------------------------------
# AI Foundry Hub Resource (The "Brain")
# ---------------------------------------------------------
resource "azapi_resource" "hub" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  name      = var.hub_name
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    kind = "Hub"
    sku = {
      name = "Standard"
      tier = "Standard"
    }
    properties = {
      friendlyName = var.hub_name
      storageAccount = azurerm_storage_account.hub_storage.id
      keyVault = azurerm_key_vault.hub_kv.id
      applicationInsights = azurerm_application_insights.hub_appinsights.id
      containerRegistry = azurerm_container_registry.hub_acr.id
      publicNetworkAccess = "Enabled"
    }
  })
}
