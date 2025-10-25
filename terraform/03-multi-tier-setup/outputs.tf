output "web_lb_public_ip" {
  value = azurerm_public_ip.web_lb_pip.ip_address
}

output "api_lb_private_ip" {
  value = azurerm_lb.api_lb.private_ip_address
}

output "db_lb_private_ip" {
  value = azurerm_lb.db_lb.private_ip_address
}

output "web_vm_ips" {
  value = [for nic in azurerm_network_interface.web_nic : nic.private_ip_address]
}

output "api_vm_ips" {
  value = [for nic in azurerm_network_interface.api_nic : nic.private_ip_address]
}

output "db_vm_ips" {
  value = [for nic in azurerm_network_interface.db_nic : nic.private_ip_address]
}
