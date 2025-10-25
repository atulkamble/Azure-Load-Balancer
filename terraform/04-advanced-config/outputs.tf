output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "load_balancer_id" {
  value = azurerm_lb.lb.id
}

output "vm_zone_mapping" {
  value = {
    for zone, vm in azurerm_linux_virtual_machine.vm :
    zone => vm.id
  }
}

output "log_analytics_workspace_id" {
  value = var.enable_diagnostics ? azurerm_log_analytics_workspace.workspace[0].id : null
}

output "storage_account_name" {
  value = var.enable_diagnostics ? azurerm_storage_account.diag_storage[0].name : null
}
