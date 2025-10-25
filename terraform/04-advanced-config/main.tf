# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-advanced-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IPs for Load Balancer (zone redundant)
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.environment}-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

# Additional Public IPs for outbound NAT
resource "azurerm_public_ip" "outbound_pip" {
  count               = 2
  name                = "${var.environment}-outbound-pip-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = var.tags
}

# Load Balancer with zone redundancy
resource "azurerm_lb" "lb" {
  name                = "${var.environment}-advanced-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
    zones                = var.availability_zones
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "backend-pool"
}

# Health Probe with advanced settings
resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rules with session persistence
resource "azurerm_lb_rule" "lb_rule_http" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
  idle_timeout_in_minutes        = var.idle_timeout
  load_distribution              = var.session_persistence
}

# Outbound Rules with multiple public IPs
resource "azurerm_lb_outbound_rule" "outbound" {
  loadbalancer_id         = azurerm_lb.lb.id
  name                    = "outbound-rule"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "frontend-ip"
  }

  frontend_ip_configuration {
    name = azurerm_lb_outbound_rule.outbound_alt[0].frontend_ip_configuration[0].name
  }
}

resource "azurerm_lb_outbound_rule" "outbound_alt" {
  count                   = 1
  loadbalancer_id         = azurerm_lb.lb.id
  name                    = "outbound-rule-alt"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "outbound-frontend-ip-1"
  }
}

# Separate outbound IPs configuration
resource "azurerm_lb" "outbound_lb" {
  name                = "${var.environment}-outbound-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "outbound-frontend-ip-1"
    public_ip_address_id = azurerm_public_ip.outbound_pip[0].id
    zones                = var.availability_zones
  }

  frontend_ip_configuration {
    name                 = "outbound-frontend-ip-2"
    public_ip_address_id = azurerm_public_ip.outbound_pip[1].id
    zones                = var.availability_zones
  }
}

resource "azurerm_lb_backend_address_pool" "outbound_pool" {
  loadbalancer_id = azurerm_lb.outbound_lb.id
  name            = "outbound-backend-pool"
}

# Network Interfaces with zone assignment
resource "azurerm_network_interface" "nic" {
  for_each = {
    for i, zone in var.availability_zones : zone => i
  }

  name                = "${var.environment}-nic-zone-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  for_each = azurerm_network_interface.nic

  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "backend_assoc" {
  for_each = azurerm_network_interface.nic

  network_interface_id    = each.value.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Virtual Machines with zone redundancy
resource "random_password" "vm_password" {
  length      = 16
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = azurerm_network_interface.nic

  name                = "${var.environment}-vm-zone-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  size                = var.vm_size
  zone                = each.key

  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [each.value.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = var.tags
}

# Storage Account for Diagnostics
resource "azurerm_storage_account" "diag_storage" {
  count                    = var.enable_diagnostics ? 1 : 0
  name                     = "diag${replace(var.environment, "-", "")}${substr(azurerm_resource_group.rg.id, -8, 8)}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Log Analytics Workspace for Monitoring
resource "azurerm_log_analytics_workspace" "workspace" {
  count               = var.enable_diagnostics ? 1 : 0
  name                = "${var.environment}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Diagnostic Setting for Load Balancer
resource "azurerm_monitor_diagnostic_setting" "lb_diags" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "${var.environment}-lb-diags"
  target_resource_id         = azurerm_lb.lb.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace[0].id

  enabled_log {
    category = "LoadBalancerAlertEvent"
  }

  enabled_log {
    category = "LoadBalancerProbeHealthStatus"
  }
}

# Alert Rule for Unhealthy Backend Count
resource "azurerm_monitor_metric_alert" "unhealthy_backend" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.environment}-unhealthy-backend-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_lb.lb.id]
  description         = "Alert when unhealthy backend count > 0"
  severity            = 2

  criteria {
    metric_name      = "UnHealthyBackendCount"
    metric_namespace = "Microsoft.Network/loadBalancers"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "LoadBalancerName"
      operator = "Include"
      values   = [azurerm_lb.lb.name]
    }
  }
}

# Alert Rule for High DIP Availability
resource "azurerm_monitor_metric_alert" "low_dip_availability" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.environment}-low-dip-availability-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_lb.lb.id]
  description         = "Alert when DIP availability < 100%"
  severity            = 1

  criteria {
    metric_name      = "DipAvailability"
    metric_namespace = "Microsoft.Network/loadBalancers"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100

    dimension {
      name     = "LoadBalancerName"
      operator = "Include"
      values   = [azurerm_lb.lb.name]
    }
  }
}
