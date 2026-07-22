resource "azurerm_resource_group" "cloud_rg" {
    name     = "BritEdge_DEV_RG"
    location = "germanywestcentral"
    tags = {
        "Environment" = "Dev",
        "Service" = "Web App"
    }
}