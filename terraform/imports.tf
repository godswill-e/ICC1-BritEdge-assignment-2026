# One-off import blocks for resources that already existed in Azure before being
# brought under Terraform state. Safe to delete once `terraform state list` confirms
# every resource below is already tracked (state is local-only, not shared across
# machines/CI runs, so this file lets a fresh checkout re-adopt existing Azure
# resources instead of failing on "already exists" during `terraform apply`).

import {
  to = azurerm_resource_group.web_app_rg
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG"
}

import {
  to = azurerm_log_analytics_workspace.log_aw
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.OperationalInsights/workspaces/log-aw-aca-britedge"
}

import {
  to = azurerm_container_app_environment.container_env
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.App/managedEnvironments/container-app-env-britedge"
}

import {
  to = azurerm_container_registry.acr
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.ContainerRegistry/registries/BritEdgeRegistry"
}

import {
  to = azurerm_cosmosdb_account.cdb_acc
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.DocumentDB/databaseAccounts/webapp-cosmosdb-account"
}

import {
  to = azurerm_user_assigned_identity.container_identity
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/container-user-identity"
}

import {
  to = azurerm_key_vault.britedge_kv
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.KeyVault/vaults/britedge-keyvault-gg"
}

import {
  to = azurerm_key_vault_access_policy.container_identity
  id = "/subscriptions/1d7f1b24-3cc5-453c-a65e-967a617536b9/resourceGroups/BritEdge_DEV_RG/providers/Microsoft.KeyVault/vaults/britedge-keyvault-gg/objectId/ae3d9580-e058-4d78-8fa9-639964dfae7d"
}

import {
  to = azurerm_key_vault_secret.cosmos_key
  id = "https://britedge-keyvault-gg.vault.azure.net/secrets/cosmos-key/5ef361b12f1b4deb930d5389e8673093"
}

import {
  to = azurerm_key_vault_secret.cosmos_enpoint
  id = "https://britedge-keyvault-gg.vault.azure.net/secrets/cosmos-endpoint/939cc0f3d2874b8f87c92e43d3f26620"
}

import {
  to = azurerm_key_vault_secret.registry_username
  id = "https://britedge-keyvault-gg.vault.azure.net/secrets/acr-username/3ab504547df943aaaa4aded133761dc8"
}

import {
  to = azurerm_key_vault_secret.registry_password
  id = "https://britedge-keyvault-gg.vault.azure.net/secrets/acr-password/75dcc224650440a9b9c588800fcb2e50"
}
