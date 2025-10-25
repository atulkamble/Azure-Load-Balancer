# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-vnet"
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

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Allow SSH
  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound traffic
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

# Network Interface for backend VMs
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.environment}-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with network interfaces
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Backend Virtual Machines
resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.environment}-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result
  size                = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# VM Password
resource "random_password" "vm_password" {
  length      = 16
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.environment}-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Load Balancer
resource "azurerm_lb" "lb" {
  name                = "${var.environment}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "${var.environment}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.environment}-backend-pool"
}

# Backend Pool Association for NICs
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Health Probe
resource "azurerm_lb_probe" "health_probe" {
  count           = var.enable_health_probe ? 1 : 0
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.environment}-health-probe"
  protocol        = "Http"
  request_path    = var.health_probe_path
  port            = var.health_probe_port
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${var.environment}-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = "${var.environment}-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = var.enable_health_probe ? azurerm_lb_probe.health_probe[0].id : null
  idle_timeout_in_minutes        = var.idle_timeout_in_minutes
}

# Outbound Rule (Required for Standard SKU)
resource "azurerm_lb_outbound_rule" "outbound_rule" {
  count                   = var.lb_sku == "Standard" ? 1 : 0
  loadbalancer_id         = azurerm_lb.lb.id
  name                    = "${var.environment}-outbound-rule"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "${var.environment}-frontend-ip"
  }
}
