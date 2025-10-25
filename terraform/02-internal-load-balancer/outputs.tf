output "internal_lb_ip" {
  description = "Private IP of internal load balancer"
  value       = azurerm_lb.internal_lb.private_ip_address
}

output "internal_lb_id" {
  description = "ID of internal load balancer"
  value       = azurerm_lb.internal_lb.id
}

output "backend_pool_id" {
  description = "ID of backend pool"
  value       = azurerm_lb_backend_address_pool.backend_pool.id
}

output "vm_private_ips" {
  description = "Private IPs of VMs"
  value       = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}

output "vm_ids" {
  description = "IDs of VMs"
  value       = [for vm in azurerm_linux_virtual_machine.vm : vm.id]
}
