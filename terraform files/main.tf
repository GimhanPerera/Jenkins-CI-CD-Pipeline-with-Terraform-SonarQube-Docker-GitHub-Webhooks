provider "azurerm" {
  features {}
}

data "local_file" "jenkins_init" {
  filename = "${path.module}/cloud-init-jenkins.sh"
}

# SonarQube
data "local_file" "sonarqube_init" {
  filename = "${path.module}/cloud-init-sonarqube.sh"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# SonarQube Public IP
resource "azurerm_public_ip" "sonarqube_ip" {
  name                = "sonarqube-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# SonarQube NIC
resource "azurerm_network_interface" "sonarqube_nic" {
  name                = "sonarqube-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sonarqube_ip.id
  }
}

# Associate NICs with NSG
resource "azurerm_network_interface_security_group_association" "sonarqube_nic_nsg" {
  network_interface_id      = azurerm_network_interface.sonarqube_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Jenkins VM
resource "azurerm_linux_virtual_machine" "jenkins_vm" {
  name                  = "jenkins-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "jenkins-vm-osdisk"
  }

  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts"
  version   = "latest"
  }

  custom_data = base64encode(data.local_file.jenkins_init.content)
}

# SonarQube VM
resource "azurerm_linux_virtual_machine" "sonarqube_vm" {
  name                  = "sonarqube-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.sonarqube_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "sonarqube-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(data.local_file.sonarqube_init.content)
}

#################################################################

# New: Docker
data "local_file" "docker_init" {
  filename = "${path.module}/cloud-init-docker.sh"
}

# Docker Public IP
resource "azurerm_public_ip" "docker_ip" {
  name                = "docker-ip"
  location            = "West US 2"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Docker NIC
resource "azurerm_network_interface" "docker_nic" {
  name                = "docker-nic"
  location            = "West US 2"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.docker_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.docker_ip.id
  }
}
resource "azurerm_virtual_network" "docker_vnet" {
  name                = "docker-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = "West US 2"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "docker_subnet" {
  name                 = "docker-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.docker_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

#For docker VM
resource "azurerm_network_security_group" "nsg_docker" {
  name                = "nsg_docker"
  location            = "West US 2"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "docker_nic_nsg" {
  network_interface_id      = azurerm_network_interface.docker_nic.id
  network_security_group_id = azurerm_network_security_group.nsg_docker.id
}

# Docker VM
resource "azurerm_linux_virtual_machine" "docker_vm" {
  name                  = "docker-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = "West US 2"
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.docker_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "docker-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(data.local_file.docker_init.content)
}
