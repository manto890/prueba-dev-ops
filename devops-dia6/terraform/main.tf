terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloud-lab"
    storage_account_name = "sttfstatecloudlab"
    container_name       = "tfstate"
    key                  = "devops-dia6.tfstate"
    use_azuread_auth     = true
  }  
  required_providers {
    azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 4.0"
  }
}

  required_version = ">= 1.6.0"
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "none"
}

variable "admin_ssh_public_key" {
  type = string
}

resource "azurerm_linux_virtual_machine" "cloud_lab" {
  name                = "vm-cloud-lab"
  resource_group_name = "rg-cloud-lab"
  location            = "Spain Central"

  size = "Standard_B2ts_v2"
  zone = "2"

  admin_username = "mantonio"

  network_interface_ids = [
    "/subscriptions/2a2ffa7d-ec53-41c9-926a-24bb00479174/resourceGroups/rg-cloud-lab/providers/Microsoft.Network/networkInterfaces/vm-cloud-lab753"
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "mantonio"
    public_key = var.admin_ssh_public_key
  }

  secure_boot_enabled = true
  vtpm_enabled        = true

  additional_capabilities {
    hibernation_enabled = false
    ultra_ssd_enabled   = false
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 30
  }
}
