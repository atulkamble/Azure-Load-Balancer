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

# Frontend Subnet
resource "azurerm_subnet" "frontend" {
  name                 = "${var.environment}-frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Backend Subnet
resource "azurerm_subnet" "backend" {
  name                 = "${var.environment}-backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# NSG for Backend
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  # Allow from load balancer
  security_rule {
    name                       = "AllowLBProbe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  # Allow SSH from frontend
  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
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

# Network Interfaces
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.environment}-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Backend VMs
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.environment}-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  size                = var.vm_size

  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

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

# VM Password
resource "random_password" "vm_password" {
  length      = 16
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Internal Load Balancer
resource "azurerm_lb" "internal_lb" {
  name                = "${var.environment}-internal-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "${var.environment}-frontend-ip"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "${var.environment}-backend-pool"
}

# Add VMs to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_assoc" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# Health Probe
resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id     = azurerm_lb.internal_lb.id
  name                = "${var.environment}-health-probe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "${var.environment}-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.environment}-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
  idle_timeout_in_minutes        = 4
  load_distribution              = "SourceIPProtocol"
}
