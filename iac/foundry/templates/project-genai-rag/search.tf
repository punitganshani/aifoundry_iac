# ---------------------------------------------------------
# Azure AI Search Service (Project Level)
# ---------------------------------------------------------
resource "azurerm_search_service" "project_search" {
  name                = "${var.project_name}-search"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard" # Required for Semantic Ranker
  tags                = var.tags

  local_authentication_enabled = false # Enforce RBAC
  public_network_access_enabled = false
  semantic_search_sku = "standard"
}

# ---------------------------------------------------------
# Private Endpoint for Search
# ---------------------------------------------------------
resource "azurerm_private_endpoint" "search" {
  name                = "${var.project_name}-search-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.project_name}-search-psc"
    private_connection_resource_id = azurerm_search_service.project_search.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.search_dns_zone_id]
  }
}

# ---------------------------------------------------------
# Connection: Link AI Search to the Project
# ---------------------------------------------------------
resource "azapi_resource" "project_connection_search" {
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name      = "search-connection"
  parent_id = azapi_resource.project.id
  
  body = jsonencode({
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${azurerm_search_service.project_search.name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = false
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.project_search.id
      }
    }
  })
}


## ---------------------------------------------------------
## Connection: Link AI Search to the Hub
## ---------------------------------------------------------
#resource "azapi_resource" "hub_connection_search" {
#  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
#  name      = "search-connection-${var.project_name}"
#  parent_id = var.hub_id
#  
#  body = jsonencode({
#    properties = {
#      category      = "CognitiveSearch"
#      target        = "https://${azurerm_search_service.project_search.name}.search.windows.net"
#      authType      = "AAD"
#      isSharedToAll = true # Or false if we want it project-specific, but Hub connections are usually shared or specific. 
#                           # If it's project specific, we might not need to add it to Hub connections, 
#                           # but Foundry projects use Hub connections.
#      metadata = {
#        ApiType    = "Azure"
#        ResourceId = azurerm_search_service.project_search.id
#      }
#    }
#  })
#}
