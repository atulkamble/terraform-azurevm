project_name      = "demo-azvm"
location          = "eastus"
admin_username    = "azureuser"
ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your_key ..."
vm_size           = "Standard_B1s"
allowed_ssh_source = "YOUR.PUBLIC.IP.ADDRESS/32" # e.g., "203.0.113.10/32"
tags = {
  env   = "dev"
  owner = "Atul"
}
