output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.snet_pe.id
}

output "compute_subnet_id" {
  value = azurerm_subnet.snet_compute.id
}

output "private_dns_zone_ids" {
  value = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}
