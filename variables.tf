variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "basic-azvm"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Your SSH public key (~/.ssh/id_rsa.pub)"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1s"
}

variable "allowed_ssh_source" {
  description = "CIDR allowed to SSH (use your IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {
    env     = "dev"
    owner   = "Atul"
    project = "basic-azvm"
  }
}
