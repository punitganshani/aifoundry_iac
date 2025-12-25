data "azurerm_client_config" "current" {}

# ---------------------------------------------------------
# Network Module
# ---------------------------------------------------------
module "network" {
  source              = "../../../platform/network"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# ---------------------------------------------------------
# Private Endpoints
# ---------------------------------------------------------

# Storage Account (Blob)
resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${var.hub_name}-st-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-st-blob-psc"
    private_connection_resource_id = azurerm_storage_account.hub_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.blob.core.windows.net"]]
  }
}

# Storage Account (File)
resource "azurerm_private_endpoint" "storage_file" {
  name                = "${var.hub_name}-st-file-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-st-file-psc"
    private_connection_resource_id = azurerm_storage_account.hub_storage.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.file.core.windows.net"]]
  }
}

# Key Vault
resource "azurerm_private_endpoint" "kv" {
  name                = "${var.hub_name}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.hub_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.vaultcore.azure.net"]]
  }
}

# OpenAI
resource "azurerm_private_endpoint" "openai" {
  name                = "${var.hub_name}-openai-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-openai-psc"
    private_connection_resource_id = azurerm_cognitive_account.hub_openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.openai.azure.com"]]
  }
}

# Container Registry
resource "azurerm_private_endpoint" "acr" {
  name                = "${var.hub_name}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.hub_acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.azurecr.io"]]
  }
}

# Hub Workspace
resource "azurerm_private_endpoint" "hub" {
  name                = "${var.hub_name}-ws-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.network.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.hub_name}-ws-psc"
    private_connection_resource_id = azapi_resource.hub.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [module.network.private_dns_zone_ids["privatelink.api.azureml.ms"]]
  }
}



