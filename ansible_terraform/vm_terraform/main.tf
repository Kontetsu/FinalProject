# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}
#Create a resource group is it doesent exist
resource "azurerm_resource_group" "Terraform_vm" {
  name = "MyTerraformVM"
  location = "eastus"

  tags = {
    environment = "Terraform Ergi"
  }
}

# Creating Virtual Netowrk

resource "azurerm_virtual_network" "Terraformnet" {
  name          = "myVnet"
  address_space = [ "10.0.0.0/16" ]
  location      = "eastus"
  resource_group_name = azurerm_resource_group.Terraform_vm.name

  tags = {
    environment = "Terraform Network"
  }
}
# Create a subnet

resource "azurerm_subnet" "TerraformSubnet" {
  name        = "MySubnet"
  resource_group_name = azurerm_resource_group.Terraform_vm.name
  virtual_network_name = azurerm_virtual_network.Terraformnet.name
  address_prefixes = ["10.0.1.0/24"]
}

#create public Ips

resource "azurerm_public_ip" "terraformpubip" {
  name        = "MyPubIp"
  location    = "eastus"
  resource_group_name = azurerm_resource_group.Terraform_vm.name
  allocation_method = "Dynamic"

  tags = {
    environment = "Terraform Pub Ip"
  }
}
# Create Network Security Group and rule

resource "azurerm_network_security_group" "myterraformnsg" {
  name        = "Terraform_NSG"
  location    = "eastus"
  resource_group_name = azurerm_resource_group.Terraform_vm.name
  
  security_rule {
    name                        = "SSH"
    priority                    = "1001"
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  tags = {
    environment = "Terraform NSG"
  }
}

# Create Network Interface

resource "azurerm_network_interface" "myterraformnic" {
  name            = "MyNIC"
  location        = "eastus"
  resource_group_name = azurerm_resource_group.Terraform_vm.name

  ip_configuration {
    name  = "MyNIcConfiguration"
    subnet_id = azurerm_subnet.TerraformSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.terraformpubip.id
  }
  tags = {
    environment = "Terraform NIC"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "terraecample" {
  network_interface_id = azurerm_network_interface.myterraformnic.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Generate random text for a unique storage account name

resource "random_id" "randomID" {
  keepers = {

    resource_group = azurerm_resource_group.Terraform_vm.name
  }
  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Terraformsa" {
  name                        = "diag${random_id.randomID.hex}"
  resource_group_name         = azurerm_resource_group.Terraform_vm.name
  location                    = "eastus"
  account_tier                = "Standard"
  account_replication_type    = "LRS"
  
  tags = {
    environment = "Terraform ASA"
  }
}

# Create (and display) an SSH key

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tsl_privat_key" {
  value = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                      = "TerraformVM"
  location                  = "eastus"
  resource_group_name       = azurerm_resource_group.Terraform_vm.name
  network_interface_ids     = [azurerm_network_interface.myterraformnic.id]
  size                      = "Standard_DS1_v2"

  os_disk {
    name                    = "TerraformOSdisk"
    caching                 = "ReadWrite"
    storage_account_type    = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "terraformvm"
  admin_username = "ergi"
  disable_password_authentication = true
  
  admin_ssh_key {
    username = "ergi"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.Terraformsa.primary_blob_endpoint
  }

  tags = {
    environment = "Terraform VM Test"
  }
}