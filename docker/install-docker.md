# Install Docker Engine

## Overview
Detects the Linux distribution and installs Docker Engine using the appropriate package manager. Verifies installation by running `hello-world`.

## Prerequisites
- Root or sudo access
- Internet connectivity
- curl, wget, or gpg available (for key management on apt/dnf-based distros)

## Installation Script

```bash
#!/bin/bash
set -euo pipefail

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION_ID="$VERSION_ID"
  elif command -v lsb_release &>/dev/null; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=$(lsb_release -rs)
  else
    echo "ERROR: Cannot detect OS. /etc/os-release not found."
    exit 1
  fi
}

check_docker_installed() {
  if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
    echo "Running hello-world verification..."
    docker run --rm hello-world 2>/dev/null && {
      echo "Docker is working correctly."
      exit 0
    } || {
      echo "WARNING: docker binary found but hello-world failed. Reinstalling..."
    }
  fi
}

install_docker_apt() {
  echo "Detected Debian/Ubuntu family. Installing via apt..."
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS_ID} $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_dnf() {
  echo "Detected RHEL/Fedora family. Installing via dnf..."
  dnf -y install dnf-plugins-core
  dnf config-manager --add-repo https://download.docker.com/linux/${OS_ID}/docker-ce.repo
  dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_yum() {
  echo "Detected RHEL/CentOS 7. Installing via yum..."
  yum install -y yum-utils
  yum-config-manager --add-repo https://download.docker.com/linux/${OS_ID}/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_apk() {
  echo "Detected Alpine Linux. Installing via apk..."
  apk add --no-cache docker docker-cli-compose containerd
  rc-update add docker default
}

install_docker_zypper() {
  echo "Detected openSUSE. Installing via zypper..."
  zypper --non-interactive addrepo https://download.docker.com/linux/suse/docker-ce.repo
  zypper --non-interactive --gpg-auto-import-keys refresh
  zypper --non-interactive install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_pacman() {
  echo "Detected Arch Linux. Installing via pacman..."
  pacman -Sy --noconfirm docker docker-compose containerd
}

post_install() {
  systemctl enable docker 2>/dev/null || true
  systemctl start docker  2>/dev/null || true
  echo "Verifying Docker installation..."
  docker run --rm hello-world && echo "SUCCESS: Docker is installed and working!" || echo "WARNING: hello-world failed. Check daemon status."
  usermod -aG docker "${SUDO_USER:-$USER}" 2>/dev/null && echo "User '${SUDO_USER:-$USER}' added to docker group (log out and back in)." || true
}

# === Main ===
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

detect_os
check_docker_installed

case "$OS_ID" in
  debian|ubuntu|linuxmint|pop|kali)
    install_docker_apt ;;
  fedora|rhel|centos)
    if command -v dnf &>/dev/null; then
      install_docker_dnf
    else
      install_docker_yum
    fi ;;
  amzn)
    amazon-linux-extras install docker -y
    yum install -y docker ;;
  alpine)
    install_docker_apk ;;
  suse|opensuse*|sles)
    install_docker_zypper ;;
  arch|manjaro|endeavouros)
    install_docker_pacman ;;
  *)
    echo "ERROR: Unsupported OS: $OS_ID"
    echo "See https://docs.docker.com/engine/install/ for manual installation."
    exit 1 ;;
esac

post_install
```

## Manual Verification

```bash
# Check Docker version
docker --version

# Check daemon status
systemctl status docker

# Run test container
docker run --rm hello-world

# List running containers
docker ps
```

## Post-Install Steps

```bash
# Add your user to docker group (avoids sudo requirement)
sudo usermod -aG docker $USER

# Apply group changes (log out and back in, or use:)
newgrp docker

# Enable Docker daemon on boot
sudo systemctl enable docker

# Configure Docker to start on boot (Alpine)
rc-update add docker default
```
