import {
  to = azurerm_resource_group.web_app_rg
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG"
}

import {
  to = azurerm_container_app.container_app
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.App/containerApps/container-app-britedge"
}

import {
  to = azurerm_container_app_environment.container_env
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.App/managedEnvironments/container-app-env-britedge"
}

import {
  to = azurerm_container_registry.acr
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.ContainerRegistry/registries/britedgejobapp1"
}

import {
  to = azurerm_log_analytics_workspace.log_aw
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.OperationalInsights/workspaces/log-aw-aca-britedge"
}

import{
  to = azurerm_cosmosdb_account.cdb_acc
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.DocumentDB/databaseAccounts/webapp-cosmosdb-account"
}