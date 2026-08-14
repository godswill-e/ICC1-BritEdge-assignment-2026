resource "azurerm_cosmosdb_account" "cdb_acc" {
  name                       = "webapp-cosmosdb-account"
  location                   = azurerm_resource_group.web_app_rg.location
  resource_group_name        = azurerm_resource_group.web_app_rg.name
  offer_type                 = "Standard"
  kind                       = "GlobalDocumentDB"
  # automatic_failover_enabled = false
  backup {
    type               = "Periodic"
    storage_redundancy = "Geo"
  }
  consistency_policy {
    consistency_level = "Session"
  }
  capabilities {
    name = "EnableServerless"
  }
  geo_location {
    location          = azurerm_resource_group.web_app_rg.location
    failover_priority = 0
  }

  tags = {
    "Environment" = "Dev"
    "Service"     = "Web App Cosmos DB"
  }
}

resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = "cosmos-key"
  value        = azurerm_cosmosdb_account.cdb_acc.primary_key
  key_vault_id = azurerm_key_vault.britedge_kv.id
  tags = {
    "Environment" = "Dev"
    "Service"     = "BritEdge Key-Vault"
    "Type"        = "Secret"
  }
}

resource "azurerm_key_vault_secret" "cosmos_enpoint" {
  name         = "cosmos-endpoint"
  value        = azurerm_cosmosdb_account.cdb_acc.endpoint
  key_vault_id = azurerm_key_vault.britedge_kv.id
  tags = {
    "Environment" = "Dev"
    "Service"     = "BritEdge Key-Vault"
    "Type"        = "Secret"
  }
}

