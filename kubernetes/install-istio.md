# Install Istio Service Mesh

## Prerequisites
- Kubernetes cluster (kind, minikube, or cloud)
- kubectl configured

## Installation

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
sudo cp bin/istioctl /usr/local/bin/

# Install Istio with demo profile
istioctl install --set profile=demo -y

# Label namespace for sidecar injection
kubectl label namespace default istio-injection=enabled

# Verify installation
istioctl version
kubectl get pods -n istio-system
```

## Deploy Sample App

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```
