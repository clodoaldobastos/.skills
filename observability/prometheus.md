# Prometheus Setup

## Installation

```bash
# Deploy with Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

## Default Components
- Prometheus server (metrics storage)
- Alertmanager (alert routing)
- Grafana (visualization)
- Node Exporter (host metrics)
- kube-state-metrics (Kubernetes metrics)

## Access

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
