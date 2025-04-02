provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "avd_rg" {
  name     = "rg-AVD-Ingram-poc-we-001"
  location = var.region

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_virtual_network" "avd_vnet" {
  name                = "avdVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

resource "azurerm_subnet" "avd_subnet" {
  name                 = "avdSubnet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "avd_nic" {
  name                = "avdNic"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "avd_vm" {
  name                  = "avdVM"
  location              = azurerm_resource_group.avd_rg.location
  resource_group_name   = azurerm_resource_group.avd_rg.name
  network_interface_ids = [azurerm_network_interface.avd_nic.id]
  vm_size               = var.vm_size

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 128
  }

  os_profile {
    computer_name  = "avdvm"
    admin_username = var.admin_username
    admin_password = data.azurerm_key_vault_secret.azvmpassword.value
  }

  os_profile_windows_config {}

  delete_os_disk_on_termination = true

  depends_on = [
    azurerm_network_interface.avd_nic
  ]
}

data "azurerm_key_vault" "example" {
  name                = var.key_vault_name
  resource_group_name = "rg-keyvault-deploy-sandb-we-001"
}

data "azurerm_key_vault_secret" "azvmpassword" {
  name         = var.key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.example.id
}

resource "azurerm_user_assigned_identity" "avd_identity" {
  name                 = "avdIdentity"
  location             = azurerm_resource_group.avd_rg.location
  resource_group_name  = azurerm_resource_group.avd_rg.name
}

resource "azurerm_role_assignment" "avd_identity_assignment" {
  principal_id         = azurerm_user_assigned_identity.avd_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.avd_rg.id
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = data.azurerm_key_vault.example.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.avd_identity.principal_id

  secret_permissions = ["Get"]
}

resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                = "hostpooleje1"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
  friendly_name       = "Host Pool EJE1"
}

resource "azurerm_virtual_desktop_application_group" "app_group" {
  name                = "appgroup1"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  type                = "Desktop"
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "workspace1"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  description         = "Workspace for AVD"
  friendly_name       = "Workspace EJE1"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "association" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.app_group.id
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registration_info" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = "2025-04-24T23:59:59Z"
}