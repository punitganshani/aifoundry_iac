variable "primary_project_name" {
  type = string
}

variable "secondary_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_machine_learning_workspace" "dr_standby" {
  name                    = "${var.primary_project_name}-dr"
  location                = var.secondary_location
  resource_group_name     = var.resource_group_name
  application_insights_id = var.application_insights_id
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  container_registry_id   = var.container_registry_id

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false
  description                   = "DR Standby for ${var.primary_project_name}"
  friendly_name                 = "${var.primary_project_name} (DR)"

  # Enforce DR tag
  tags = merge(var.tags, {
    "DR-Type" = "WarmStandby"
  })
}

# Variables for dependencies (simplified)
variable "application_insights_id" { type = string }
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }
variable "container_registry_id" { type = string }
