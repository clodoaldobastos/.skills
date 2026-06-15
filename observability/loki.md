# Loki Log Aggregation

## Installation

```bash
# Deploy Loki with Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace logging \
  --create-namespace \
  --set promtail.enabled=true
```

## Query Examples

```logql
# All logs from a specific pod
{container_name="nginx"} |= "error"

# Rate of errors over 5m
rate({container_name="nginx"} |= "error"[5m])

# Logs with JSON parsing
{app="my-app"} | json | line_format "{{.message}}"
```

## Access

```bash
kubectl port-forward -n logging svc/loki 3100:3100
```
