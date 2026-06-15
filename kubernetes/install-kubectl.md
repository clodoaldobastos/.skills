# Install kubectl

Kubernetes command-line tool for deploying and managing applications on Kubernetes.

## Prerequisites
- curl installed
- sudo/root access

## Installation - Get Latest Stable Version

Fetch actual latest version from Kubernetes release API:

```bash
# Get latest stable kubectl version
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

echo "Latest kubectl version: $KUBECTL_VERSION"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"

# Verify checksum (optional but recommended)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client --output=yaml
```

## Quick Install (Latest)

One-liner:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Install Specific Version

```bash
# Example: Install v1.31.0
KUBECTL_VERSION="v1.31.0"

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## Version Compatibility

kubectl supports +/-1 minor version skew with the cluster:

| kubectl Version | Supported Cluster Versions |
|-----------------|----------------------------|
| v1.31.x         | v1.30, v1.31, v1.32       |
| v1.30.x         | v1.29, v1.30, v1.31       |
| v1.29.x         | v1.28, v1.29, v1.30       |

**Recommendation:** Install kubectl version matching your cluster control-plane version or one minor version higher.

## Verify Installation

```bash
# Check version
kubectl version --client

# Or with more detail
kubectl version --client --output=yaml
```

Expected output:
```yaml
clientVersion:
  buildDate: "2024-08-13T09:28:04Z"
  compiler: gc
  gitCommit: 4feb669566b42e6c1ff8e45ad54822a805033
  gitTreeState: clean
  gitVersion: v1.31.0
  goVersion: go1.22.6
  major: "1"
  minor: "31"
  platform: linux/amd64
kustomizeVersion: v5.4.2
```

## Enable Shell Autocompletion

### Bash

```bash
# Install bash-completion if needed
sudo apt install bash-completion  # Debian/Ubuntu
sudo dnf install bash-completion  # RHEL/Fedora

# Enable for current session
source <(kubectl completion bash)

# Enable permanently
echo 'source <(kubectl completion bash)' >> ~/.bashrc
```

### Zsh

```bash
# Enable for current session
source <(kubectl completion zsh)

# Enable permanently
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
```

## Add kubectl Alias (Optional)

```bash
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# Now you can use:
k get nodes
k get pods
```

## Alternative: Package Manager

### Debian/Ubuntu

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubectl
```

### RHEL/CentOS/Fedora

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

sudo yum install -y kubectl
```

## Uninstall

```bash
sudo rm /usr/local/bin/kubectl
```

## Check Available Versions

```bash
# List all available versions
curl -L -s https://dl.k8s.io/release/stable.txt  # Latest stable
curl -L -s https://dl.k8s.io/release/latest.txt  # Latest (including pre-releases)
```

## Links

- Official Documentation: https://kubernetes.io/docs/tasks/tools/
- Release Notes: https://kubernetes.io/releases/
