# Install Kind (Kubernetes in Docker)

## Prerequisites
- Docker installed and running
- kubectl installed
- curl and jq (for version detection)

## Installation - Get Actual Latest Version (not 'latest' tag)

**Important:** The `latest` tag on GitHub is a redirect that can cause issues. Always fetch the actual release version number.

```bash
# Fetch the actual latest release version from GitHub API
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r '.tag_name')

echo "Latest KIND version: $KIND_VERSION"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download KIND binary
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version
```

## Create Multi-Node Cluster (1 control-plane + 2 workers)

Create the cluster configuration file:

```yaml
# kind-multinode-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-cluster
nodes:
  - role: control-plane
    image: kindest/node:v1.31.0
  - role: worker
    image: kindest/node:v1.31.0
  - role: worker
    image: kindest/node:v1.31.0
```

Create the cluster:

```bash
# Create with configuration
kind create cluster --config kind-multinode-config.yaml

# Or one-liner without config file
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-cluster
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF
```

## Verify Cluster

```bash
# List clusters
kind get clusters

# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# Cluster info
kubectl cluster-info --context kind-dev-cluster
```

## Expected Output

```
NAME                      STATUS   ROLES           AGE   VERSION
dev-cluster-control-plane Ready    control-plane   5m    v1.31.0
dev-cluster-worker        Ready    <none>          5m    v1.31.0
dev-cluster-worker2       Ready    <none>          5m    v1.31.0
```

## Deploy Example Workload

```bash
# Create an nginx deployment
kubectl create deployment nginx --image=nginx:alpine

# Scale to 2 replicas
kubectl scale deployment nginx --replicas=2

# Expose as NodePort
kubectl expose deployment nginx --type=NodePort --port=80

# Check
kubectl get deployments
kubectl get pods -o wide
kubectl get svc
```

## Useful Commands

```bash
# Delete cluster
kind delete cluster --name dev-cluster

# Load Docker image into KIND cluster
kind load docker-image my-custom-image:tag --name dev-cluster

# Export kubeconfig
kind get kubeconfig --name dev-cluster > ~/.kube/kind-config
```

## Version Matrix

KIND releases are tied to specific Kubernetes versions:

| KIND Version | Default K8s Version |
|--------------|---------------------|
| v0.27.0      | v1.31.0             |
| v0.26.0      | v1.30.0             |
| v0.25.0      | v1.29.2             |
| v0.24.0      | v1.28.0             |

Check available node images: https://github.com/kubernetes-sigs/kind/releases
