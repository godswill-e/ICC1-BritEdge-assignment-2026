resource "azurerm_log_analytics_workspace" "log_aw" {
  name                = "log-aw-aca-britedge"
  location            = azurerm_resource_group.web_app_rg.location
  resource_group_name = azurerm_resource_group.web_app_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    "Environment" = "Dev"
    "Service"     = "Web App LAW"
  }
}

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

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id          = azurerm_user_assigned_identity.container_identity.principal_id
}