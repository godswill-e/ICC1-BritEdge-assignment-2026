terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
  }
  # backend "azurerm" {
  #   resource_group_name = var.wa_resource_group_name
  #   storage_account_name = var.wa_storage_account_name
  # }
}

provider "azurerm" {
  features {}
}

