variable "location-1" {
  description = "The Azure region for the BritEdge resources, specifically germanywestcentral"
  type        = string
}

variable "location-2" {
  description = "The Azure region for the BritEdge resources, specifically italynorth"
  type        = string
}

variable "wa_resource_group_name" {
  description = "The name of the Resource Group"
  type        = string
}

variable "user_email"{
  description = "Email for the user to recieve alerts"
  type = string
}