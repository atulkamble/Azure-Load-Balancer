location              = "East US"
resource_group_name   = "rg-lb-advanced"
environment           = "prod"
availability_zones    = ["1", "2", "3"]
vm_per_zone           = 1
vm_size               = "Standard_B2s"
admin_username        = "azureuser"
enable_diagnostics    = true
enable_alerts         = true
idle_timeout          = 15
session_persistence   = "ClientIP"

tags = {
  Environment   = "prod"
  Configuration = "advanced"
  CreatedDate   = "2025-10-25"
  HA            = "zone-redundant"
}
