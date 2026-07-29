output "resource_group_name" {
  value = azurerm_resource_group.web_app_rg.name
}

output "container_env_id" {
  value = azurerm_container_app_environment.container_env.id
}
