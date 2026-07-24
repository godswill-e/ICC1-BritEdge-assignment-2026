resource "azurerm_cosmosdb_account" "cdb_acc" {
  name                       = "webapp-cosmosdb-account"
  location                   = azurerm_resource_group.web_app_rg.location
  resource_group_name        = azurerm_resource_group.web_app_rg.name
  offer_type                 = "Standard"
  kind                       = "MongoDB"
  automatic_failover_enabled = true
  backup {
    type               = "Periodic"
    storage_redundancy = "Local"
  }
  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location-1
    failover_priority = 0
  }


  tags = {
    "Environment" = "Dev"
    "Service"     = "Web App Cosmos DB"
  }
}