output "resource_group_name" {
  value = azurerm_resource_group.web_app_rg.name
}

output "azurerm_container_app" {
  value = azurerm_container_app.container_app.name
}