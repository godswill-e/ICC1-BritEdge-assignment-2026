resource "azurerm_log_analytics_workspace" "log_aw" {
  name                = "log-analytics-workspace-1"
  location            = azurerm_resource_group.web_app_rg.location
  resource_group_name = azurerm_resource_group.web_app_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    "Environment" = "Dev"
    "Service"     = "Web App Log Analytics Workspace"
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  name                       = "cosmosdb-to-log-aw"
  target_resource_id         = azurerm_cosmosdb_account.cdb_acc.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_aw.id

  enabled_log { category_group = "allLogs" }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "keyvault-to-log-aw"
  target_resource_id         = azurerm_key_vault.britedge_kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_aw.id

  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "container_reg" {
  name                       = "container-reg-to-log-aw"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_aw.id

  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "container_env" {
  name                       = "container-env-to-log-aw"
  target_resource_id         = azurerm_container_app_environment.container_env.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_aw.id

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_action_group" "monitor_action" {
  name                = "MainAlertsAction"
  resource_group_name = azurerm_resource_group.web_app_rg.name
  short_name          = "ma01action"
  email_receiver {
    name          = "ada_email_reciever"
    email_address = var.user_email
  }
  tags = {
    "Environment" = "Dev"
    "Service"     = "Azure Monitor Action Group"
  }
}

resource "azurerm_monitor_metric_alert" "container_app_cpu_allert" {
  name                 = "ContainerAppMetricAlert"
  resource_group_name  = azurerm_resource_group.web_app_rg.name
  scopes               = ["${azurerm_resource_group.web_app_rg.id}/providers/Microsoft.App/containerApps/jobschedule-app-britedge"] #
  description          = "Action will be triggered when container app CPU usage goes above 80%"
  target_resource_type = "Microsoft.App/containerApps"
  frequency            = "PT5M"
  window_size          = "PT5M"
  severity             = "3"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 200000000 # around 80% cpu usage
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor_action.id
  }

  tags = {
    "Environment" = "Dev"
    "Service"     = "Azure Monitor Alert"
  }
}
