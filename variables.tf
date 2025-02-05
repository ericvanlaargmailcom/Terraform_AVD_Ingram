variable "tenant_id" {
  description = "The Tenant ID for the Azure Active Directory"
  default     = "8c781dba-1521-44e4-9886-e37f91a6f736"
}

variable "subscription_id" {
  description = "The Subscription ID for the Azure account"
  default     = "ef17a603-a390-49bd-946c-cc18aa67f388"
}

variable "region" {
  description = "The Azure region to deploy resources"
  default     = "westeurope"
}

variable "admin_username" {
  description = "The administrator username for the VM"
  default     = "adminuser"
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  default     = "Standard_DS1_v2"
}

variable "key_vault_name" {
  description = "The name of the Key Vault"
  default     = "keyvaulteje"
}

variable "key_vault_secret_name" {
  description = "The name of the secret in the Key Vault"
  default     = "azvmpassword"
}
