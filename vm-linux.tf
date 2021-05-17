resource "azurerm_public_ip" "public_ip_linux" {
  count               = var.linux_vm_count
  name                = format("%s-public-ip-linux-%02d", var.prefix, (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    Environment = var.prefix
  }
}

resource "azurerm_network_interface" "nic_linux" {
  count               = var.linux_vm_count
  name                = format("%s-nic-linux-%02d", var.prefix, (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.linux_vm_private_ip[count.index]
    public_ip_address_id          = azurerm_public_ip.public_ip_linux[count.index].id
  }
}

# configure security group with rules
resource "azurerm_network_security_group" "sg_linux" {
  count               = var.linux_vm_count > 0 ? 1 : 0
  name                = "${var.prefix}-sg-linux"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

  tags = {
    Environment = var.prefix
  }
}

# attach security group to network interface
resource "azurerm_network_interface_security_group_association" "nic_linux_sg_linux" {
  count                     = var.linux_vm_count
  network_interface_id      = azurerm_network_interface.nic_linux[count.index].id
  network_security_group_id = azurerm_network_security_group.sg_linux[0].id
}


resource "azurerm_linux_virtual_machine" "vm_linux" {
  count = var.linux_vm_count
  name  = format("%s-linux-%02d", var.prefix, (count.index + 1))
  # hostname lenght can only be 15 characters   
  computer_name       = format("%s-lin-%02d", substr(var.prefix, 0, 5), (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.linux_vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic_linux[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    # az vm image list --output table  
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  # connection {
  #   type        = "ssh"
  #   user        = "adminuser"
  #   private_key = file("~/.ssh/id_rsa")
  #   host        = azurerm_public_ip.public_ip_linux[count.index].ip_address
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo apt-get update",
  #     "sudo apt-get -y install rsync nginx",
  #   ]
  # }

}


