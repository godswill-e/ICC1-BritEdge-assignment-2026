resource "azurerm_resource_group" "web_app_rg" {
  name     = var.wa_resource_group_name
  location = var.location-1
  tags = {
    "Environment" = "Dev",
    "Service"     = "Web App RG"
  }
}