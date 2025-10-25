variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of virtual network"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for vnet"
  type        = string
}

variable "subnets" {
  description = "Subnets configuration"
  type = map(object({
    cidr = string
  }))
}

variable "nsg_rules" {
  description = "NSG rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
