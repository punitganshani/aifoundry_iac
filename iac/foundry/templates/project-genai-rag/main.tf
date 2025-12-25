data "azurerm_client_config" "current" {}

resource "azapi_resource" "project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  name      = var.project_name
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = merge(var.tags, {
    CostCenter = var.cost_center
  })

  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    kind = "Project"
    sku = {
      name = "Standard"
      tier = "Standard"
    }
    properties = {
      friendlyName = var.project_name
      description  = "Foundry Project - Governed"
      hubResourceId = var.hub_id
      publicNetworkAccess = "Enabled"
    }
  })
}

resource "azurerm_monitor_diagnostic_setting" "project_diagnostics" {
  name                       = "${var.project_name}-diagnostics"
  target_resource_id         = azapi_resource.project.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ---------------------------------------------------------
# Role Assignment: Current User -> Project (Azure AI Developer)
# ---------------------------------------------------------
resource "azurerm_role_assignment" "user_project_developer" {
  scope                = azapi_resource.project.id
  role_definition_name = "Azure AI Developer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------
# Role Assignment: Project Identity -> Search Service
# ---------------------------------------------------------
resource "azurerm_role_assignment" "project_search_data_contributor" {
  scope                = azurerm_search_service.project_search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.project.identity[0].principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "project_search_service_contributor" {
  scope                = azurerm_search_service.project_search.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azapi_resource.project.identity[0].principal_id
  skip_service_principal_aad_check = true
}

# ---------------------------------------------------------
# Role Assignment: Project Identity -> Storage Account
# ---------------------------------------------------------
resource "azurerm_role_assignment" "project_storage_blob_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.project.identity[0].principal_id
  skip_service_principal_aad_check = true
}



