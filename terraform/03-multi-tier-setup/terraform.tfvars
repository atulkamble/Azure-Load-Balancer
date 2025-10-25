location            = "East US"
resource_group_name = "rg-lb-multitier"
environment         = "prod"
vnet_cidr           = "10.0.0.0/16"
web_tier_cidr       = "10.0.1.0/24"
api_tier_cidr       = "10.0.2.0/24"
db_tier_cidr        = "10.0.3.0/24"
web_vm_count        = 2
api_vm_count        = 2
db_vm_count         = 2
vm_size             = "Standard_B2s"
admin_username      = "azureuser"

tags = {
  Environment  = "prod"
  Architecture = "multi-tier"
  CreatedDate  = "2025-10-25"
}
