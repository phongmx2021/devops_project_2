# Configure the Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-rg"
  location = var.location
}


resource "azurerm_availability_set" "this" {
  name                         = "${var.prefix}-aset"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  tags = {
    environment = var.environment
  }
}


resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = {
    environment = var.environment
  }

  security_rule {
    name                       = "AllowVnetInBound"
    description                = "Allow access to other VMs on the subnet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInBound"
    description                = "Deny all inbound traffic outside of the vnet from the Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-publicIp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"

  tags = {
    environment = var.environment
  }
}

resource "azurerm_lb" "this" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = {
    environment = var.environment
  }

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "BackEndAddressPool"
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet" "this" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "this" {
  count = var.vm_count

  name                = "${var.prefix}-${var.server_names[count.index]}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = {
    environment = var.environment
  }

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count = var.vm_count

  network_interface_id    = azurerm_network_interface.this[count.index].id
  ip_configuration_name   = "testConfiguration"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.vm_count

  name                            = "${var.server_names[count.index]}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.this[count.index].id]
  availability_set_id = azurerm_availability_set.this.id
  source_image_id     = var.packerImageId

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment = var.environment
    name        = var.server_names[count.index]
  }
}

resource "azurerm_managed_disk" "this" {
  name                 = "${var.prefix}-md"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = var.environment
  }
}
