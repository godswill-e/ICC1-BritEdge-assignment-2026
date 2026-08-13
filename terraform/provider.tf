terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.81.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "BritEdge_TFSTATE_RG"
    storage_account_name = "tfstate01britedge"
    container_name       = "tfstate-dev01"
    key                  = "britedge.tfstate-dev01"
  }
}

provider "azurerm" {
  features {}
}

