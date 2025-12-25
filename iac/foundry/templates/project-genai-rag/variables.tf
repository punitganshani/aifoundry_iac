variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "application_insights_id" {
  type = string
}

variable "hub_id" {
  type        = string
  description = "The ID of the AI Foundry Hub to link this project to."
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Subnet ID for Private Endpoints"
}

variable "search_dns_zone_id" {
  type        = string
  description = "Private DNS Zone ID for Azure AI Search"
}

variable "key_vault_id" {
  type = string
}

variable "storage_account_id" {
  type = string
}

variable "container_registry_id" {
  type = string
}

variable "cost_center" {
  type        = string
  description = "Cost Center ID for chargeback/showback"
}

variable "tags" {
  type = map(string)
  default = {}
}
