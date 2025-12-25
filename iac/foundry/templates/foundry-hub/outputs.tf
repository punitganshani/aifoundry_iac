# Outputs to feed into the Project Template
output "storage_account_id" { value = azurerm_storage_account.hub_storage.id }
output "key_vault_id" { value = azurerm_key_vault.hub_kv.id }
output "application_insights_id" { value = azurerm_application_insights.hub_appinsights.id }
output "log_analytics_workspace_id" { value = azurerm_log_analytics_workspace.hub_law.id }
output "container_registry_id" { value = azurerm_container_registry.hub_acr.id }
output "apim_name" { value = azurerm_api_management.hub_apim.name }

output "openai_endpoint" { value = azurerm_cognitive_account.hub_openai.endpoint }
output "openai_id" { value = azurerm_cognitive_account.hub_openai.id }
output "hub_id" { value = azapi_resource.hub.id }

output "vnet_id" { value = module.network.vnet_id }
output "compute_subnet_id" { value = module.network.compute_subnet_id }
output "private_endpoints_subnet_id" { value = module.network.private_endpoints_subnet_id }
output "search_dns_zone_id" { value = module.network.private_dns_zone_ids["privatelink.search.windows.net"] }


