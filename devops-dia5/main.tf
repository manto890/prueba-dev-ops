terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "cloud_lab" {
  name     = "rg-cloud-lab"
  location = "Spain Central"
}

resource "azurerm_virtual_network" "cloud_lab" {
  name                = "vnet-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "cloud_lab" {
  name                 = "subnet-cloud-lab"
  resource_group_name  = azurerm_resource_group.cloud_lab.name
  virtual_network_name = azurerm_virtual_network.cloud_lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "cloud_lab" {
  name                = "pip-cloud-lab"
  resource_group_name = azurerm_resource_group.cloud_lab.name
  location            = azurerm_resource_group.cloud_lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "cloud_lab" {
  name                = "nic-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.cloud_lab.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloud_lab.id
  }
}

resource "azurerm_network_security_group" "cloud_lab" {
  name                = "nsg-cloud-lab"
  location            = azurerm_resource_group.cloud_lab.location
  resource_group_name = azurerm_resource_group.cloud_lab.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.cloud_lab.name
  network_security_group_name = azurerm_network_security_group.cloud_lab.name
}

resource "azurerm_network_interface_security_group_association" "cloud_lab" {
  network_interface_id      = azurerm_network_interface.cloud_lab.id
  network_security_group_id = azurerm_network_security_group.cloud_lab.id
}

resource "azurerm_linux_virtual_machine" "cloud_lab" {
  name                = "vm-terraform-lab"
  resource_group_name = azurerm_resource_group.cloud_lab.name
  location            = azurerm_resource_group.cloud_lab.location
  size                = "Standard_B2ts_v2"

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.cloud_lab.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

