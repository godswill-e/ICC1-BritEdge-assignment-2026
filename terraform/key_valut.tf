data "azurerm_client_config" "current" {}
resource "azurerm_user_assigned_identity" "container_identity" {
  name = "container-user-identity"
  location = var.location-2
  resource_group_name = azurerm_resource_group.web_app_rg.name
}

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

resource "azurerm_key_vault_access_policy" "container_identity" {
  key_vault_id = azurerm_key_vault.britedge_kv.id

  tenant_id = azurerm_user_assigned_identity.container_identity.tenant_id
  object_id = azurerm_user_assigned_identity.container_identity.principal_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
}
