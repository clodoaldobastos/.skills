#!/bin/bash
# Bootstrap script to initialize the development environment

set -euo pipefail

echo "=== Bootstrap: Development Environment Setup ==="

# Install common tools
echo "Installing common tools..."
sudo apt-get update
sudo apt-get install -y curl git jq yamllint shellcheck

# Install kubectl
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Install kind
if ! command -v kind &> /dev/null; then
  echo "Installing kind..."
  KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r '.tag_name')
  curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/
fi

# Install helm
if ! command -v helm &> /dev/null; then
  echo "Installing helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  rm get_helm.sh
fi

echo "=== Bootstrap Complete ==="
