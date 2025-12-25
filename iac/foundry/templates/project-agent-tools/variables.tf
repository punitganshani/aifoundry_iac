variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "application_insights_id" { type = string }
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }
variable "container_registry_id" { type = string }
variable "hub_id" { type = string }
variable "subnet_id" { type = string }

