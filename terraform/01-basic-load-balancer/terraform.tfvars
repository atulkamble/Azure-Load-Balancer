# Basic Load Balancer Configuration
# Copy this file and update values as needed

# Azure region
location = "East US"

# Resource group name
resource_group_name = "rg-lb-basic"

# Environment name
environment = "dev"

# Number of backend VMs
vm_count = 3

# VM size (options: Standard_B1s, Standard_B2s, Standard_B2ms, etc.)
vm_size = "Standard_B2s"

# Admin username for VMs
admin_username = "azureuser"

# Load Balancer SKU (Basic or Standard - Standard recommended)
lb_sku = "Standard"

# Enable health probe
enable_health_probe = true

# Health probe port (typically same as backend port)
health_probe_port = 80

# Health probe path (for HTTP probes)
health_probe_path = "/"

# Frontend port (port exposed to internet)
lb_frontend_port = 80

# Backend port (port on VMs)
lb_backend_port = 80

# Enable floating IP (for SQL, NLB scenarios)
enable_floating_ip = false

# Idle timeout in minutes (4-30)
idle_timeout_in_minutes = 4

# Tags for resources
tags = {
  Environment = "dev"
  Project     = "azure-lb"
  ManagedBy   = "Terraform"
  CreatedDate = "2025-10-25"
}
