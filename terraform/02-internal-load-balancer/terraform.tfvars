location            = "East US"
resource_group_name = "rg-lb-internal"
environment         = "prod"
vm_count            = 2
vm_size             = "Standard_B2s"
admin_username      = "azureuser"
lb_sku              = "Standard"

tags = {
  Environment = "prod"
  Type        = "Internal-LB"
  CreatedDate = "2025-10-25"
}
