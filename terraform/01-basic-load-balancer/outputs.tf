output "load_balancer_id" {
  description = "ID of the Azure Load Balancer"
  value       = azurerm_lb.lb.id
}

output "load_balancer_name" {
  description = "Name of the Azure Load Balancer"
  value       = azurerm_lb.lb.name
}

output "load_balancer_private_ip_address" {
  description = "Private IP address of the Load Balancer"
  value       = azurerm_lb.lb.private_ip_address
  sensitive   = false
}

output "load_balancer_public_ip" {
  description = "Public IP address of the Load Balancer"
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "load_balancer_fqdn" {
  description = "FQDN of the Load Balancer Public IP"
  value       = azurerm_public_ip.lb_pip.fqdn
}

output "backend_pool_id" {
  description = "ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.backend_pool.id
}

output "health_probe_id" {
  description = "ID of the health probe"
  value       = var.enable_health_probe ? azurerm_lb_probe.health_probe[0].id : null
}

output "vm_private_ips" {
  description = "Private IP addresses of backend VMs"
  value       = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}

output "vm_ids" {
  description = "IDs of backend VMs"
  value       = [for vm in azurerm_windows_virtual_machine.vm : vm.id]
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.rg.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.subnet.id
}

output "access_url" {
  description = "URL to access the load balancer"
  value       = "http://${azurerm_public_ip.lb_pip.ip_address}"
}

output "vm_admin_username" {
  description = "Admin username for VMs"
  value       = var.admin_username
}

output "vm_admin_password" {
  description = "Admin password for VMs (stored in state file)"
  value       = random_password.vm_password.result
  sensitive   = true
}
