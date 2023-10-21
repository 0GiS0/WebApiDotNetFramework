resource "azurerm_resource_group" "rg" {
  name     = "rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"  
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "vm_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
	name                          = "vm_ip_configuration"
	subnet_id                     = azurerm_subnet.vm_subnet.id
	private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  computer_name         = "vm"
  enable_automatic_updates = false
  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true
  os_disk {
	name              = "vm_os_disk"
	caching           = "ReadWrite"
	storage_account_type = "Standard_LRS"
  }
  source_image_reference {
	publisher = "MicrosoftWindowsServer"
	offer     = "WindowsServer"
	sku       = "2016-Datacenter"
	version   = "latest"
  }
  os_profile {
	computer_name  = "vm"
	admin_username = "adminuser"
	admin_password = "Password1234!"
  }
  os_profile_windows_config {
	provision_vm_agent = true
  }
}


resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
SETTINGS
}
