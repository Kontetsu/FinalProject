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
resource "azurerm_resource_group" "agentvm" {
  name = "agentvm"
  location = "eastus"

  tags = {
    environment = "agentvm"
  }
}

# Creating Virtual Netowrk

resource "azurerm_virtual_network" "agentvm_vn" {
  name          = "myVnet"
  address_space = [ "10.0.0.0/16" ]
  location      = "eastus"
  resource_group_name = azurerm_resource_group.agentvm.name

  tags = {
    environment = "jenkins Network"
  }
}
# Create a subnet

resource "azurerm_subnet" "jenkinsSubnet" {
  name        = "MySubnet"
  resource_group_name = azurerm_resource_group.agentvm.name
  virtual_network_name = azurerm_virtual_network.agentvm_vn.name
  address_prefixes = ["10.0.1.0/24"]
}

#create public Ips

resource "azurerm_public_ip" "jenkinspubip" {
  name        = "MyPubIp"
  location    = "eastus"
  resource_group_name = azurerm_resource_group.agentvm.name
  allocation_method = "Dynamic"

  tags = {
    environment = "jenkins Pub Ip"
  }
}
# Create Network Security Group and rule

resource "azurerm_network_security_group" "jenkinsmnsg" {
  name        = "jenkins_NSG"
  location    = "eastus"
  resource_group_name = azurerm_resource_group.agentvm.name

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
  security_rule {
    name                        = "jenkins_web"
    priority                    = "1010"
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "TCP"
    source_port_range           = "*"
    destination_port_range      = "8080"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  tags = {
    environment = "jenkins NSG"
  }
}

# Create Network Interface

resource "azurerm_network_interface" "jenkinsnic" {
  name            = "MyNIC"
  location        = "eastus"
  resource_group_name = azurerm_resource_group.agentvm.name

  ip_configuration {
    name  = "MyNIcConfiguration"
    subnet_id = azurerm_subnet.jenkinsSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jenkinspubip.id
  }
  tags = {
    environment = "Terraform NIC"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "jenkins_sec_group" {
  network_interface_id = azurerm_network_interface.jenkinsnic.id
  network_security_group_id = azurerm_network_security_group.jenkinsmnsg.id
}

# Generate random text for a unique storage account name

resource "random_id" "randomID" {
  keepers = {

    resource_group = azurerm_resource_group.agentvm.name
  }
  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "jenkins_sa" {
  name                        = "diag${random_id.randomID.hex}"
  resource_group_name         = azurerm_resource_group.agentvm.name
  location                    = "eastus"
  account_tier                = "Standard"
  account_replication_type    = "LRS"

  tags = {
    environment = "Terraform Demo"
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
resource "azurerm_linux_virtual_machine" "jenkinsagent" {
  name                      = "jenkinsagent"
  location                  = "eastus"
  resource_group_name       = azurerm_resource_group.agentvm.name
  network_interface_ids     = [azurerm_network_interface.jenkinsnic.id]
  size                      = "Standard_DS1_v2"


  os_disk {
    name                    = "JenkinsOSdisk"
    caching                 = "ReadWrite"
    storage_account_type    = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "jenkins"
  admin_username = "ergi"
  disable_password_authentication = false
  admin_password = var.admin_password

  admin_ssh_key {
    username = "ergi"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.jenkins_sa.primary_blob_endpoint
  }

  tags = {
    environment = "Jenkins Agent"
  }
}
