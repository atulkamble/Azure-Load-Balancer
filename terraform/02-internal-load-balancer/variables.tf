variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-lb-internal"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vm_count" {
  description = "Number of backend VMs"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureuser"
}

variable "lb_sku" {
  description = "Load Balancer SKU"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default = {
    Environment = "prod"
    Type        = "Internal-LB"
  }
}
