resource "azurerm_api_management" "hub_apim" {
  name                = "${var.hub_name}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "AI Foundry"
  publisher_email     = "admin@example.com"
  sku_name            = "Developer_1" # Use Developer for cost/testing, Premium for Prod
  tags                = var.tags
  
  # Prevent Terraform from trying to delete the default "starter" and "unlimited" products
  # which can cause 401 errors if the deployment principal lacks specific permissions
  # or if the APIM instance is in a transitional state.
  lifecycle {
    ignore_changes = [
      hostname_configuration
    ]
  }
}
