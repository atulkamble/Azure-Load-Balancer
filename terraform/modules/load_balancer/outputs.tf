output "lb_id" {
  value = azurerm_lb.lb.id
}

output "lb_name" {
  value = azurerm_lb.lb.name
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}

output "health_probe_id" {
  value = azurerm_lb_probe.health_probe.id
}
