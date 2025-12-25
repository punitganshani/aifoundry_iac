# ---------------------------------------------------------
# Role Assignment: Current User -> OpenAI (Contributor)
# Fixes "You do not have permission to access the resource"
# ---------------------------------------------------------
resource "azurerm_role_assignment" "user_openai_contributor" {
  scope                = azurerm_cognitive_account.hub_openai.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------
# Role Assignment: Current User -> Hub (Azure AI Developer)
# Fixes "User is not able to create Prompt Flow"
# ---------------------------------------------------------
resource "azurerm_role_assignment" "user_hub_developer" {
  scope                = azapi_resource.hub.id
  role_definition_name = "Azure AI Developer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------
# Role Assignment: Hub MSI -> OpenAI (Contributor)
# ---------------------------------------------------------
resource "azurerm_role_assignment" "hub_openai_contributor" {
  scope                = azurerm_cognitive_account.hub_openai.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = azapi_resource.hub.identity[0].principal_id
}
