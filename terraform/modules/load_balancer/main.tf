resource "azurerm_lb" "lb" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "${var.environment}-frontend"
    public_ip_address_id = var.lb_type == "Public" ? var.frontend_public_ip_id : null
    subnet_id            = var.lb_type == "Internal" ? var.frontend_subnet_id : null
    private_ip_address   = var.lb_type == "Internal" ? var.frontend_private_ip : null
    private_ip_address_allocation = var.lb_type == "Internal" ? "Static" : null
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = var.backend_pool_name
}

resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = var.health_probe_name
  protocol            = var.health_probe_protocol
  port                = var.health_probe_port
  request_path        = var.health_probe_protocol != "Tcp" ? var.health_probe_path : null
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = var.lb_rule_name
  protocol                       = var.lb_protocol
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = "${var.environment}-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
  idle_timeout_in_minutes        = var.idle_timeout_minutes
  load_distribution              = var.session_persistence
}

resource "azurerm_lb_outbound_rule" "outbound" {
  count                   = var.lb_sku == "Standard" ? 1 : 0
  loadbalancer_id         = azurerm_lb.lb.id
  name                    = "${var.environment}-outbound"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "${var.environment}-frontend"
  }
}
