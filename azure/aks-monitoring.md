# AKS Monitoring Setup

## Enable Container Insights

```bash
# Create AKS cluster with monitoring
az aks create \
  --resource-group my-rg \
  --name my-aks \
  --enable-managed-identity \
  --enable-addons monitoring \
  --workspace-resource-id <workspace-id>

# Enable monitoring on existing cluster
az aks enable-addons \
  --resource-group my-rg \
  --name my-aks \
  --addons monitoring
```

## Azure Monitor Features
- Container Insights for logs and metrics
- Prometheus metrics scraping (preview)
- Azure Managed Grafana dashboards
- Log Analytics workspace queries
- Metric alerts and action groups
