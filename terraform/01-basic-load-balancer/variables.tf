variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-lb-basic"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vm_count" {
  description = "Number of backend virtual machines"
  type        = number
  default     = 3
  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 10
    error_message = "VM count must be between 1 and 10."
  }
}

variable "vm_size" {
  description = "Size of virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Administrator username for VMs"
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "azure-lb"
    ManagedBy   = "Terraform"
  }
}

variable "lb_sku" {
  description = "Load Balancer SKU (Basic or Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.lb_sku)
    error_message = "Load Balancer SKU must be Basic or Standard."
  }
}

variable "enable_health_probe" {
  description = "Enable health probe for backend pools"
  type        = bool
  default     = true
}

variable "health_probe_port" {
  description = "Port for health probe"
  type        = number
  default     = 80
}

variable "health_probe_path" {
  description = "Path for HTTP health probe"
  type        = string
  default     = "/"
}

variable "lb_frontend_port" {
  description = "Frontend port for load balancer"
  type        = number
  default     = 80
}

variable "lb_backend_port" {
  description = "Backend port for load balancer"
  type        = number
  default     = 80
}

variable "enable_floating_ip" {
  description = "Enable floating IP for load balancing rule"
  type        = bool
  default     = false
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for load balancing rule"
  type        = number
  default     = 4
  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 30
    error_message = "Idle timeout must be between 4 and 30 minutes."
  }
}
