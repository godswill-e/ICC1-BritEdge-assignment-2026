data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "britedge_kv" {
  name                = "britedge-keyvault-gg"
  resource_group_name = azurerm_resource_group.web_app_rg.name
  location            = azurerm_resource_group.web_app_rg.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "Create",
      "List"
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List"
    ]

    storage_permissions = [
      "Get",
      "Delete",
      "List",
      "Update"
    ]
  }

  tags = {
    "Environment" = "Dev"
    "Resource"    = "Web App Key Vault"
  }
}
