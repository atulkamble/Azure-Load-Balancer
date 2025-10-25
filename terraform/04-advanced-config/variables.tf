variable "location" {
  type    = string
  default = "East US"
}

variable "resource_group_name" {
  type    = string
  default = "rg-lb-advanced"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "availability_zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "vm_per_zone" {
  type    = number
  default = 1
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "enable_diagnostics" {
  type    = bool
  default = true
}

variable "enable_alerts" {
  type    = bool
  default = true
}

variable "idle_timeout" {
  type    = number
  default = 15
}

variable "session_persistence" {
  type    = string
  default = "ClientIP"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "prod"
    Configuration = "advanced"
  }
}
