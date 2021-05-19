resource "azurerm_public_ip" "public_ip_win" {
  count               = var.win_vm_count
  name                = format("%s-public-ip-win-%02d", var.prefix, (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = {
    Environment = var.prefix
  }
}

resource "azurerm_network_interface" "nic_win" {
  count               = var.win_vm_count
  name                = format("%s-nic-win-%02d", var.prefix, (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.win_vm_private_ip[count.index]
    public_ip_address_id          = azurerm_public_ip.public_ip_win[count.index].id
  }
}

# configure security group with rules
resource "azurerm_network_security_group" "sg_win" {
  count               = var.win_vm_count > 0 ? 1 : 0
  name                = "${var.prefix}-sg-win"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.prefix
  }
}

# attach security group to network interface
resource "azurerm_network_interface_security_group_association" "nic_win_sg_win" {
  count                     = var.win_vm_count
  network_interface_id      = azurerm_network_interface.nic_win[count.index].id
  network_security_group_id = azurerm_network_security_group.sg_win[0].id
}

resource "azurerm_windows_virtual_machine" "vm_win" {
  count = var.win_vm_count
  name  = format("%s-win-%02d", var.prefix, (count.index + 1))
  # hostname lenght can only be 15 characters 
  computer_name       = format("%s-win-%02d", substr(var.prefix, 0, 5), (count.index + 1))
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.win_vm_size
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic_win[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}