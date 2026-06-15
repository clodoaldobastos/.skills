# Remove Docker Engine

## Overview
Safely uninstalls Docker Engine and all associated components. Offers three levels of removal: soft (packages only), full (packages + data), and purge (complete system cleanup).

## Prerequisites
- Root or sudo access
- Docker service must be stoppable

## Removal Script

```bash
#!/bin/bash
set -euo pipefail

WARNINGS=()

warn() { echo "WARNING: $1"; WARNINGS+=("$1"); }

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
  elif command -v lsb_release &>/dev/null; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  else
    echo "ERROR: Cannot detect OS."
    exit 1
  fi
}

confirm() {
  echo ""
  echo "=== WARNING: This will destroy Docker and all its data ==="
  echo ""
  read -r -p "Are you sure you want to continue? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) echo "Aborted."; exit 1 ;;
  esac
}

stop_docker() {
  echo "Stopping Docker services..."
  systemctl stop docker.socket 2>/dev/null || true
  systemctl stop docker 2>/dev/null || true
  systemctl disable docker 2>/dev/null || true
  systemctl disable docker.socket 2>/dev/null || true
  pkill -9 docker 2>/dev/null || true
  sleep 2
}

remove_containers() {
  echo "Removing all containers, images, volumes, and networks..."
  docker stop $(docker ps -aq) 2>/dev/null || true
  docker rm $(docker ps -aq) 2>/dev/null || true
  docker system prune -a --volumes -f 2>/dev/null || true
}

remove_packages_apt() {
  apt-get purge -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
  apt-get autoremove -y -qq 2>/dev/null || true
}

remove_packages_dnf() {
  dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
}

remove_packages_yum() {
  yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
}

remove_packages_apk() {
  apk del docker docker-cli-compose containerd 2>/dev/null || true
}

remove_packages_zypper() {
  zypper --non-interactive remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
}

remove_packages_pacman() {
  pacman -Rns --noconfirm docker docker-compose containerd 2>/dev/null || true
}

cleanup_system() {
  echo "Cleaning up Docker directories..."
  rm -rf /var/lib/docker
  rm -rf /var/lib/containerd
  rm -rf /etc/docker
  rm -rf /etc/apt/keyrings/docker.asc 2>/dev/null || true
  rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
  rm -f /etc/yum.repos.d/docker-ce.repo 2>/dev/null || true
  rm -f /etc/zypp/repos.d/docker-ce.repo 2>/dev/null || true
  rm -rf ~/.docker 2>/dev/null || true
}

remove_group() {
  if getent group docker &>/dev/null; then
    groupdel docker 2>/dev/null && echo "Docker group removed." || warn "Could not remove docker group (users may be logged in)."
  fi
}

verify_removal() {
  if command -v docker &>/dev/null; then
    warn "docker binary still found in PATH."
  else
    echo "Docker binary removed successfully."
  fi
  if [ -d /var/lib/docker ]; then
    warn "/var/lib/docker still exists."
  fi
  if systemctl is-active docker &>/dev/null 2>&1; then
    warn "docker service is still active."
  fi
}

# === Main ===
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

detect_os
confirm

# Stop everything first
stop_docker

# Remove all Docker objects (containers, images, volumes)
remove_containers || warn "docker CLI not available for container removal."

# Remove packages
echo "Removing Docker packages..."
case "$OS_ID" in
  debian|ubuntu|linuxmint|pop|kali)
    remove_packages_apt ;;
  fedora|rhel|centos)
    if command -v dnf &>/dev/null; then remove_packages_dnf; else remove_packages_yum; fi ;;
  amzn)
    yum remove -y docker ;;
  alpine)
    remove_packages_apk ;;
  suse|opensuse*|sles)
    remove_packages_zypper ;;
  arch|manjaro|endeavouros)
    remove_packages_pacman ;;
  *)
    warn "Unsupported OS: $OS_ID. Attempting generic removal..."
    command -v docker && rm -f "$(command -v docker)" || true
    ;;
esac

# Purge configuration and data
cleanup_system
remove_group

# Final verification
verify_removal

echo ""
echo "=== Docker removal complete ==="
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "Warnings:"
  for w in "${WARNINGS[@]}"; do echo "  - $w"; done
fi
```

## Manual Removal

```bash
# 1. Stop Docker
sudo systemctl stop docker docker.socket
sudo systemctl disable docker docker.socket

# 2. Remove all containers, images, volumes
sudo docker system prune -a --volumes -f

# 3. Uninstall packages (choose your OS)
# Debian/Ubuntu
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo apt-get autoremove -y

# RHEL/Fedora
sudo dnf remove -y docker-ce docker-ce-cli containerd.io

# 4. Delete leftover directories
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker
sudo rm -rf ~/.docker

# 5. Remove docker group
sudo groupdel docker

# 6. Remove apt repo (Debian/Ubuntu)
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc
```
