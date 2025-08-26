variable "location" {
  default = "East US"
}
# But All docker related resources (Docker VM and Docker NIC, Public IP) has hard-coded to West_US_2

variable "resource_group_name" {
  default = "tf-vm-rg"
}

variable "vnet_name" {
  default = "tf-vnet"
}

variable "subnet_name" {
  default = "tf-subnet"
}

variable "nsg_name" {
  default = "tf-nsg"
}

variable "public_ip_name" {
  default = "tf-public-ip"
}

variable "nic_name" {
  default = "tf-nic"
}

variable "admin_username" {
  default = "azureuser"
}

variable "ssh_key" {
  description = "Your public SSH key"
  default = "<PATH>/<KEY>.pub"
}
