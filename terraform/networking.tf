resource "azurerm_virtual_network" "container_vnet" {
  name = "britedge-container-vnet"
  address_space = ["10.0.0.0/16"]
  location = var.location-2
  resource_group_name = azurerm_resource_group.web_app_rg.name
  tags = {
    "Environment" = "Dev"
    "Service"     = "Container App Virtual Network"
  }
}

resource "azurerm_subnet" "container_subnet"{
  name = "britedge-container-subnet"
  resource_group_name = azurerm_resource_group.web_app_rg.name
  virtual_network_name = azurerm_virtual_network.container_vnet.name
  address_prefixes = ["10.0.0.0/21"]

  delegation {
    name = "container-apps-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}