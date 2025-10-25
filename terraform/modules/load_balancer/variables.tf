variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "lb_type" {
  description = "Type of load balancer (Public or Internal)"
  type        = string
  default     = "Public"
}

variable "lb_sku" {
  description = "Load Balancer SKU"
  type        = string
  default     = "Standard"
}

variable "frontend_public_ip_id" {
  description = "ID of public IP for frontend (for Public LB)"
  type        = string
  default     = null
}

variable "frontend_subnet_id" {
  description = "ID of subnet for frontend (for Internal LB)"
  type        = string
  default     = null
}

variable "frontend_private_ip" {
  description = "Private IP for frontend (for Internal LB)"
  type        = string
  default     = null
}

variable "backend_pool_name" {
  description = "Name of backend address pool"
  type        = string
}

variable "health_probe_name" {
  description = "Name of health probe"
  type        = string
}

variable "health_probe_protocol" {
  description = "Health probe protocol (Http, Https, Tcp)"
  type        = string
  default     = "Http"
}

variable "health_probe_port" {
  description = "Health probe port"
  type        = number
  default     = 80
}

variable "health_probe_path" {
  description = "Health probe path (for Http/Https)"
  type        = string
  default     = "/"
}

variable "lb_rule_name" {
  description = "Name of load balancing rule"
  type        = string
}

variable "lb_frontend_port" {
  description = "Frontend port"
  type        = number
  default     = 80
}

variable "lb_backend_port" {
  description = "Backend port"
  type        = number
  default     = 80
}

variable "lb_protocol" {
  description = "Protocol (Tcp, Udp)"
  type        = string
  default     = "Tcp"
}

variable "idle_timeout_minutes" {
  description = "Idle timeout in minutes"
  type        = number
  default     = 4
}

variable "session_persistence" {
  description = "Session persistence (None, ClientIP, ClientIPProtocol)"
  type        = string
  default     = "None"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
