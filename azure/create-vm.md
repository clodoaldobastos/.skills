# Create Azure VM

## Via Azure CLI

```bash
# Login
az login

# Create resource group
az group create --name my-rg --location eastus

# Create VM
az vm create \
  --resource-group my-rg \
  --name my-vm \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys

# Open port 80
az vm open-port --port 80 --resource-group my-rg --name my-vm
```

## Via Terraform

See `.templates/terraform-module/` for reusable Terraform module.
