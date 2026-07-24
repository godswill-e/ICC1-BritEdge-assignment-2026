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
  name                = "britedgejobapp1"
  resource_group_name = azurerm_resource_group.web_app_rg.name
  location            = azurerm_resource_group.web_app_rg.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    "Environment" = "Dev"
    "Service"     = "Container Registry"
  }
}

resource "azurerm_container_app" "container_app" {
  name                         = "container-app-britedge"
  container_app_environment_id = azurerm_container_app_environment.container_env.id
  resource_group_name          = azurerm_resource_group.web_app_rg.name
  revision_mode                = "Single"

  tags = {
    "Environment" = "Dev"
    "Service"     = "Container App"
  }
  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = "System"
  }

  identity { type = "SystemAssigned" }

  template {
    container {
      name   = "jobshcedule-webapp-container"
      image  = "${azurerm_container_registry.acr.login_server}/britedgejobapp1:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name        = "COSMOS_KEY"
        secret_name = "cosmos-key"
      }
      env {
        name        = "COSMOS_ENDPOINT"
        secret_name = "cosmos-endpoint"
      }

    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # ADD COSMOS VARIABLES HERE
  secret {
    name  = "cosmos-key"
    value = azurerm_cosmosdb_account.cdb_acc.primary_key
  }
  secret {
    name  = "cosmos-endpoint"
    value = azurerm_cosmosdb_account.cdb_acc.endpoint
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_container_app.container_app.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}