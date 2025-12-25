variable "subscription_id" {
  type        = string
  description = "The Subscription ID for the provider context"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_subscription_policy_assignment" "deny_public_endpoints" {
  name                 = "deny-public-endpoints"
  policy_definition_id = azurerm_policy_definition.deny_public_endpoints.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Deny Public Endpoints"
  enforce              = true
}

resource "azurerm_subscription_policy_assignment" "mandatory_tags" {
  name                 = "enforce-mandatory-tags"
  policy_definition_id = azurerm_policy_set_definition.mandatory_tags.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Enforce Mandatory Tags"
  enforce              = true
}

resource "azurerm_subscription_policy_assignment" "allowed_models" {
  name                 = "allowed-models"
  policy_definition_id = azurerm_policy_definition.allowed_models.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
  display_name         = "Allowed OpenAI Models"
  enforce              = true
  parameters = <<PARAMETERS
    {
      "allowedModelNames": {
        "value": ["gpt-4o", "gpt-4", "gpt-35-turbo", "text-embedding-ada-002"]
      }
    }
  PARAMETERS
}
