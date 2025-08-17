Got it, Atul! Here’s a clean, minimal Terraform setup to launch a basic Ubuntu VM on Azure. It creates a resource group, VNet/Subnet, NSG (SSH open), public IP, NIC, and a Linux VM (Ubuntu 22.04 LTS). You can drop these files into a folder and apply.

# 1) Files

## `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.120"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "cc57cd42-dede-4674-b810-a0fbde41504a"
}
```

## `variables.tf`

```hcl
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
```

## `main.tf`

```hcl
locals {
  rg_name   = "${var.project_name}-rg"
  vnet_name = "${var.project_name}-vnet"
  snet_name = "${var.project_name}-snet"
  nsg_name  = "${var.project_name}-nsg"
  pip_name  = "${var.project_name}-pip"
  nic_name  = "${var.project_name}-nic"
  vm_name   = "${var.project_name}-vm"
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "snet" {
  name                 = local.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Optional: simple cloud-init to install NGINX and show hostname
locals {
  cloud_init = <<-CLOUD
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - bash -c 'echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.nginx-debian.html'
      - systemctl enable nginx
      - systemctl restart nginx
  CLOUD
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  tags = var.tags

  # Disable password login; use SSH key
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${local.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = local.vm_name
  custom_data    = base64encode(local.cloud_init)
}
```

## `outputs.tf`

```hcl
output "public_ip" {
  description = "Public IP of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "ssh_cmd" {
  description = "SSH command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
```

## `terraform.tfvars.example`

```hcl
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
```

---

# 2) How to Run

```bash
# 0) Login to Azure (CLI)
az login
# (optional) set subscription
az account set --subscription "<SUBSCRIPTION_ID>"

# 1) Prepare SSH key if you don’t have one
ssh-keygen -t rsa -b 4096 -C "you@example.com"
cat ~/.ssh/id_rsa.pub   # copy into ssh_public_key variable

# 2) Init & apply
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -auto-approve -var-file="terraform.tfvars"
```

When it completes, Terraform prints the `public_ip` and a ready-to-use `ssh_cmd`. Open `http://<public_ip>` to see the NGINX welcome page with the VM hostname from cloud-init.

---

# 3) Clean Up

```bash
terraform destroy -auto-approve -var-file="terraform.tfvars"
```

---

### Notes / Tweaks

* **Harden SSH**: Replace `allowed_ssh_source` with your IP `/32`. Avoid `0.0.0.0/0` in real environments.
* **Windows VM?** Swap `azurerm_linux_virtual_machine` for `azurerm_windows_virtual_machine` and use a password/WinRM as needed.
* **No public IP**: Remove `azurerm_public_ip` and that reference, then access via Bastion/VPN/Jumpbox.

If you want, I can turn this into a GitHub-ready repo layout with a README and CI (e.g., GitHub Actions) next.
