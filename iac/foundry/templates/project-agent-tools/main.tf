provider "azurerm" {
  features {}
}



data "azurerm_client_config" "current" {}

resource "azapi_resource" "agent_project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  name      = var.project_name
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = merge(var.tags, {
    "WorkloadType" = "Agentic"
    "SafetyProfile" = "Standard"
  })

  body = jsonencode({
    kind = "Project"
    sku = {
      name = "Standard"
      tier = "Standard"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      friendlyName = var.project_name
      description  = "Foundry Agent Project"
      hubResourceId = var.hub_id
      publicNetworkAccess = "Enabled"
    }
  })
}

# Placeholder for Agent Pool / Compute
resource "azurerm_machine_learning_compute_instance" "agent_compute" {
  name                          = "${var.project_name}-vm"
  machine_learning_workspace_id = azapi_resource.agent_project.id
  virtual_machine_size          = "STANDARD_DS11_V2"
  subnet_resource_id            = var.subnet_id
  
  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------------------------------------
# Role Assignment: Current User -> Project (Azure AI Developer)
# Fixes "Unable to access your agents" (403)
# ---------------------------------------------------------
resource "azurerm_role_assignment" "user_project_developer" {
  scope                = azapi_resource.agent_project.id
  role_definition_name = "Azure AI Developer"
  principal_id         = data.azurerm_client_config.current.object_id
}
