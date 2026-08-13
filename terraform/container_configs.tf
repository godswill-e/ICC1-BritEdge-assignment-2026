

resource "azurerm_container_app_environment" "container_env" {
  name                       = "container-app-env-britedge"
  location                   = var.location-2
  resource_group_name        = azurerm_resource_group.web_app_rg.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_aw.id
  tags = {
    "Environment" = "Dev"
    "Service"     = "Web App Container Environment"
  }
}

# Georeplication required?
resource "azurerm_container_registry" "acr" {
  name                = "BritEdgeRegistry"
  resource_group_name = azurerm_resource_group.web_app_rg.name
  location            = azurerm_resource_group.web_app_rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    "Environment" = "Dev"
    "Service"     = "Container Registry"
  }
}

resource "azurerm_key_vault_secret" "registry_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.acr.admin_username
  key_vault_id = azurerm_key_vault.britedge_kv.id
  tags = {
    "Environmenr" = "Dev"
    "Service"     = "BritEdge Key-Vault"
    "Type"        = "Secret"
  }
}

resource "azurerm_key_vault_secret" "registry_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.acr.admin_password
  key_vault_id = azurerm_key_vault.britedge_kv.id
  tags = {
    "Environmenr" = "Dev"
    "Service"     = "BritEdge Key-Vault"
    "Type"        = "Secret"
  }
}