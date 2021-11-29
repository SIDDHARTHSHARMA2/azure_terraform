terraform {
  required_version = ">= 0.14.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.44.0"
    }
  }
}

provider "azurerm" {
  features {}
}


data "azurerm_resource_group" "cloudinit" {
  name = var.resource_group_name

}

data "azurerm_virtual_network" "cloudinit" {
  name                = "hu19-tf-vnet"
  resource_group_name = data.azurerm_resource_group.cloudinit.name 
}

resource "azurerm_subnet" "cloudinit" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.cloudinit.name
  virtual_network_name = data.azurerm_virtual_network.cloudinit.name
  address_prefixes     = ["10.1.8.0/21"]
}

resource "azurerm_public_ip" "cloudinit" {
  name                = var.public_ip
  location            = data.azurerm_resource_group.cloudinit.location
  resource_group_name = data.azurerm_resource_group.cloudinit.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "cloudinit" {
  name                = var.network_security_group
  location            = data.azurerm_resource_group.cloudinit.location
  resource_group_name = data.azurerm_resource_group.cloudinit.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "cloudinit" {
  name                = var.network_interface
  location            = data.azurerm_resource_group.cloudinit.location
  resource_group_name = data.azurerm_resource_group.cloudinit.name

  ip_configuration {
    name                          = "sid-nic-config"
    subnet_id                     = azurerm_subnet.cloudinit.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cloudinit.id
  }
}

resource "azurerm_network_interface_security_group_association" "cloudinit" {
  network_interface_id      = azurerm_network_interface.cloudinit.id
  network_security_group_id = azurerm_network_security_group.cloudinit.id
}

resource "azurerm_linux_virtual_machine" "cloudinit" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.cloudinit.name
  location            = data.azurerm_resource_group.cloudinit.location
  size                = "Standard_B1s"
  admin_username      = "cloudinit"
  admin_password      = "HKKRoD24XLBzxdD"


  # This is where we pass our cloud-init.
  custom_data = "I2Nsb3VkLWNvbmZpZwoKcGFja2FnZXM6CiAgLSBkb2NrZXIuaW8KCiMgY3JlYXRlIHRoZSBkb2NrZXIgZ3JvdXAKZ3JvdXBzOgogIC0gZG9ja2VyCgp1c2VyczoKICAtIG5hbWU6IGNsb3VkaW5pdAogICAgZ3JvdXBzOiBkb2NrZXIKICAgIGhvbWU6IC9ob21lL2Nsb3VkaW5pdAogICAgc2hlbGw6IC9iaW4vYmFzaAogICAgc3VkbzogQUxMPShBTEwpIE5PUEFTU1dEOkFMTAoKIyBBZGQgZGVmYXVsdCBhdXRvIGNyZWF0ZWQgdXNlciB0byBkb2NrZXIgZ3JvdXAKc3lzdGVtX2luZm86CiAgZGVmYXVsdF91c2VyOgogICAgZ3JvdXBzOiBbZG9ja2VyXQoKcnVuY21kOgogIC0gc3VkbyBkb2NrZXIgbG9naW4gLS11c2VybmFtZSBzaWR3YXIgLS1wYXNzd29yZC1zdGRpbiBQYXNzd29yZEAxMjMKICAtIHN1ZG8gZG9ja2VyIHB1bGwgc2lkd2FyL25vZGUtYnVsbGV0aW4tYXBwCiAgLSBzdWRvIGRvY2tlciBydW4gIC1lICJNWV9WQVI9bXlWYWx1ZSIgZG9ja2VyIHB1bGwgc2lkd2FyL25vZGUtYnVsbGV0aW4tYXBwCiAgLSBzdWRvIGRvY2tlciBydW4gLWQgLXAgODA6ODAgLWUgU09NRV9WQVI9IlNPTUUgVkFMVUUiIHNpZHdhci9ub2RlLWJ1bGxldGluLWFwcCA="

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.cloudinit.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  tags = {
    environment = "staging"
  }
}
resource "azurerm_storage_account" "cloudinit" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.cloudinit.name
  location                 = data.azurerm_resource_group.cloudinit.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}
resource "azurerm_storage_container" "example" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.cloudinit.name
  container_access_type = "private"
}
resource "azurerm_storage_blob" "example" {
  name                   = "terraform.tfstate"
  storage_account_name   = azurerm_storage_account.cloudinit.name
  storage_container_name = azurerm_storage_container.example.name
  type                   = "Block"
  source                 = "/Users/siddharthsharma2/Desktop/terraform scripts /terraform.tfstate"
}
output "public_ip" {
  value = azurerm_linux_virtual_machine.cloudinit.public_ip_address
}