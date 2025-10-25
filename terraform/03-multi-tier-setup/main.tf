# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Web Tier Subnet
resource "azurerm_subnet" "web" {
  name                 = "${var.environment}-web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_tier_cidr]
}

# API Tier Subnet
resource "azurerm_subnet" "api" {
  name                 = "${var.environment}-api-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.api_tier_cidr]
}

# Database Tier Subnet
resource "azurerm_subnet" "db" {
  name                 = "${var.environment}-db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_tier_cidr]
}

# ===== Network Security Groups =====

# Web Tier NSG
resource "azurerm_network_security_group" "web_nsg" {
  name                = "${var.environment}-web-nsg"
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
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAll"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# API Tier NSG
resource "azurerm_network_security_group" "api_nsg" {
  name                = "${var.environment}-api-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowFromWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.web_tier_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAll"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Database Tier NSG
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.environment}-db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "AllowFromAPI"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = var.api_tier_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAll"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ===== Public Load Balancer (Web Tier) =====

resource "azurerm_public_ip" "web_lb_pip" {
  name                = "${var.environment}-web-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "web_lb" {
  name                = "${var.environment}-web-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "web-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-backend-pool"
}

# ===== Internal Load Balancer (API Tier) =====

resource "azurerm_lb" "api_lb" {
  name                = "${var.environment}-api-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "api-frontend-ip"
    subnet_id                     = azurerm_subnet.api.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.10"
  }
}

resource "azurerm_lb_backend_address_pool" "api_backend_pool" {
  loadbalancer_id = azurerm_lb.api_lb.id
  name            = "api-backend-pool"
}

# ===== Internal Load Balancer (Database Tier) =====

resource "azurerm_lb" "db_lb" {
  name                = "${var.environment}-db-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                          = "db-frontend-ip"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.10"
  }
}

resource "azurerm_lb_backend_address_pool" "db_backend_pool" {
  loadbalancer_id = azurerm_lb.db_lb.id
  name            = "db-backend-pool"
}

# ===== Virtual Machines and Network Interfaces =====

# Web Tier NICs
resource "azurerm_network_interface" "web_nic" {
  count               = var.web_vm_count
  name                = "${var.environment}-web-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "web_nsg_assoc" {
  count                     = var.web_vm_count
  network_interface_id      = azurerm_network_interface.web_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "web_backend_assoc" {
  count                   = var.web_vm_count
  network_interface_id    = azurerm_network_interface.web_nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_backend_pool.id
}

# API Tier NICs
resource "azurerm_network_interface" "api_nic" {
  count               = var.api_vm_count
  name                = "${var.environment}-api-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.api.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "api_nsg_assoc" {
  count                     = var.api_vm_count
  network_interface_id      = azurerm_network_interface.api_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.api_nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "api_backend_assoc" {
  count                   = var.api_vm_count
  network_interface_id    = azurerm_network_interface.api_nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api_backend_pool.id
}

# DB Tier NICs
resource "azurerm_network_interface" "db_nic" {
  count               = var.db_vm_count
  name                = "${var.environment}-db-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.db.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "db_nsg_assoc" {
  count                     = var.db_vm_count
  network_interface_id      = azurerm_network_interface.db_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

resource "azurerm_network_interface_backend_address_pool_association" "db_backend_assoc" {
  count                   = var.db_vm_count
  network_interface_id    = azurerm_network_interface.db_nic[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.db_backend_pool.id
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

# Web Tier VMs
resource "azurerm_linux_virtual_machine" "web_vm" {
  count               = var.web_vm_count
  name                = "${var.environment}-web-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  size                = var.vm_size

  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.web_nic[count.index].id,
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

# API Tier VMs
resource "azurerm_linux_virtual_machine" "api_vm" {
  count               = var.api_vm_count
  name                = "${var.environment}-api-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  size                = var.vm_size

  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.api_nic[count.index].id,
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

# Database Tier VMs
resource "azurerm_linux_virtual_machine" "db_vm" {
  count               = var.db_vm_count
  name                = "${var.environment}-db-vm-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  admin_username      = var.admin_username
  size                = var.vm_size

  disable_password_authentication = false
  admin_password                  = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.db_nic[count.index].id,
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
