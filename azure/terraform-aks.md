# Terraform AKS Module Usage

## Example

```hcl
module "aks" {
  source              = "./.templates/terraform-module"
  cluster_name        = "my-aks-cluster"
  resource_group_name = "my-rg"
  location            = "eastus"
  node_count          = 3
  vm_size             = "Standard_D2s_v3"
  kubernetes_version  = "1.28"
}
```

## Outputs

```hcl
output "kubeconfig" {
  value = module.aks.kubeconfig
  sensitive = true
}

output "cluster_endpoint" {
  value = module.aks.cluster_endpoint
}
```
