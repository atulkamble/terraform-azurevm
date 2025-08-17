```
// azure vm launch with terraform 

1. Install git 
2. Install and configure terrafiorm 
3. clone repo 
git clone https://github.com/atulkamble/terraform-azurevm.git
cd terraform-azurevm
4. try az login 
5. update your subcription id in versions.tf
6. 
terraform init 
terraform plan
terraform apply 
terraform destroy 
```

👍 Let’s start with a **very basic Azure Terraform practice** that will help you understand the flow:

1. **Install Terraform & Azure CLI**

   * Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
   * Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
   * Login to Azure:

     ```bash
     az login
     ```

---

## 📂 Project Structure

```
terraform-azure-vm/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

---

## 🔹 main.tf

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-practice-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "tf-practice-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "tf-practice-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "tf-practice-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "tf-practice-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_password = "Password1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
```

---

## 🔹 variables.tf

```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}
```

---

## 🔹 outputs.tf

```hcl
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}
```

---

## 🔹 terraform.tfvars

```hcl
location = "East US"
```

---

## 🚀 Steps to Run

```bash
# Initialize provider plugins
terraform init

# Validate code
terraform validate

# See what will be created
terraform plan

# Create resources
terraform apply -auto-approve

# Destroy resources when done
terraform destroy -auto-approve
```

---

👉 This creates:

* **Resource Group**
* **Virtual Network & Subnet**
* **NIC**
* **Ubuntu Linux VM**

Would you like me to extend this practice with **SSH key-based login** (instead of password) so you can directly SSH into the VM?

