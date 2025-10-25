variable "location" {
  type    = string
  default = "East US"
}

variable "resource_group_name" {
  type    = string
  default = "rg-lb-multitier"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "web_tier_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "api_tier_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "db_tier_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "web_vm_count" {
  type    = number
  default = 2
}

variable "api_vm_count" {
  type    = number
  default = 2
}

variable "db_vm_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "prod"
    Architecture = "multi-tier"
  }
}
