variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "subscription_id" {
  type = string
}

variable "openai_resource_id" {
  type = string
}

variable "budget_amount" {
  type        = number
  description = "The monthly budget amount for the resource group."
  default     = 1000
}

variable "emails_platform_team" {
  type        = list(string)
  description = "List of email addresses for the Platform Team."
  default     = ["platform-admins@example.com"]
}

variable "emails_ai_app_team" {
  type        = list(string)
  description = "List of email addresses for the AI App Team."
  default     = ["app-owners@example.com"]
}

variable "emails_model_ops_team" {
  type        = list(string)
  description = "List of email addresses for the Model Ops Team."
  default     = ["model-ops@example.com"]
}
