# Install K3s Cluster (1 Control Plane + 2 Workers)

## Prerequisites
- Linux host with root/sudo access
- Internet connectivity
- No Docker required (K3s uses embedded containerd)

k3s is a lightweight Kubernetes distribution certified by CNCF, ideal for edge, IoT, and development environments.

## Installation

Save the script below as `install-k3s.sh` and run as root:

```bash
#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION="${K3S_VERSION:-v1.30.2}"
K3S_TOKEN="${K3S_TOKEN:-k3s-cluster-token}"
SERVER_PORT="${SERVER_PORT:-6443}"
BASE_DIR="${BASE_DIR:-/var/lib/rancher/k3s}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
SERVER_IP="127.0.0.1"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

[ "$(id -u)" -eq 0 ] || err "Execute como root (sudo su)"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *)       err "Arquitetura $ARCH não suportada" ;;
esac

BINARY_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-${ARCH}"

cleanup_previous() {
  warn "Removendo instalação anterior do k3s..."
  systemctl stop k3s-server 2>/dev/null || true
  systemctl stop k3s-agent-worker-1 2>/dev/null || true
  systemctl stop k3s-agent-worker-2 2>/dev/null || true
  rm -f /etc/systemd/system/k3s-server.service
  rm -f /etc/systemd/system/k3s-agent-worker-1.service
  rm -f /etc/systemd/system/k3s-agent-worker-2.service
  rm -rf "${BASE_DIR}/server" "${BASE_DIR}/agent-1" "${BASE_DIR}/agent-2"
  rm -f "${BIN_DIR}/k3s" /usr/local/bin/kubectl /usr/local/bin/crictl /usr/local/bin/ctr
  systemctl daemon-reload 2>/dev/null || true
}

download_k3s() {
  log "Baixando k3s ${K3S_VERSION} (${ARCH})..."
  curl -sfL "$BINARY_URL" -o "${BIN_DIR}/k3s" || err "Falha ao baixar k3s"
  chmod 755 "${BIN_DIR}/k3s"
  ln -sf "${BIN_DIR}/k3s" /usr/local/bin/kubectl
  ln -sf "${BIN_DIR}/k3s" /usr/local/bin/crictl
  ln -sf "${BIN_DIR}/k3s" /usr/local/bin/ctr
}

setup_server() {
  log "Configurando control plane (server)..."
  cat > /etc/systemd/system/k3s-server.service <<'SERVEOF'
[Unit]
Description=k3s Server (Control Plane)
Documentation=https://docs.k3s.io
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s server \
  --disable-agent \
  --token K3S_TOKEN_PLACEHOLDER \
  --bind-address 0.0.0.0 \
  --advertise-address SERVER_IP_PLACEHOLDER \
  --https-listen-port SERVER_PORT_PLACEHOLDER \
  --write-kubeconfig-mode 644 \
  --data-dir /var/lib/rancher/k3s/server
KillMode=process
Delegate=yes
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVEOF
  sed -i "s/K3S_TOKEN_PLACEHOLDER/${K3S_TOKEN}/" /etc/systemd/system/k3s-server.service
  sed -i "s/SERVER_IP_PLACEHOLDER/${SERVER_IP}/" /etc/systemd/system/k3s-server.service
  sed -i "s/SERVER_PORT_PLACEHOLDER/${SERVER_PORT}/" /etc/systemd/system/k3s-server.service
  systemctl daemon-reload
  systemctl enable k3s-server
  systemctl start k3s-server
  log "Servidor iniciado (porta ${SERVER_PORT})"
  warn "Aguardando servidor ficar pronto (~30s)..."
  for i in $(seq 1 30); do
    "${BIN_DIR}/k3s" kubectl get nodes --no-headers 2>/dev/null && break
    sleep 2
  done
}

setup_agent() {
  local name="$1"
  local data_dir="${BASE_DIR}/${name}"
  local kubelet_port="$2"
  log "Configurando worker ${name} (kubelet port ${kubelet_port})..."
  mkdir -p "$data_dir"
  cat > "/etc/systemd/system/k3s-agent-${name}.service" <<AGEOF
[Unit]
Description=k3s Agent (${name})
Documentation=https://docs.k3s.io
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/k3s agent \
  --server https://${SERVER_IP}:${SERVER_PORT} \
  --token ${K3S_TOKEN} \
  --node-name ${name} \
  --data-dir ${data_dir} \
  --kubelet-arg "port=${kubelet_port}"
KillMode=process
Delegate=yes
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
AGEOF
  systemctl daemon-reload
  systemctl enable "k3s-agent-${name}"
  systemctl start "k3s-agent-${name}"
  log "Worker ${name} iniciado"
}

show_status() {
  echo ""
  log "=== Status do Cluster ==="
  sleep 5
  "${BIN_DIR}/k3s" kubectl get nodes -o wide 2>/dev/null || warn "Aguardando nodes..."
  echo ""
  log "=== Services ==="
  systemctl is-active k3s-server k3s-agent-worker-1 k3s-agent-worker-2 2>/dev/null
  echo ""
  log "Kubeconfig: /etc/rancher/k3s/k3s.yaml"
  log "Logs server: journalctl -u k3s-server -f"
  log "Logs worker-1: journalctl -u k3s-agent-worker-1 -f"
  log "Parar tudo: systemctl stop k3s-server k3s-agent-worker-1 k3s-agent-worker-2"
}

case "${1:-install}" in
  install)
    echo "=== Instalação k3s: 1 Control Plane + 2 Workers ==="
    cleanup_previous
    download_k3s
    setup_server
    setup_agent "worker-1" "10251"
    setup_agent "worker-2" "10252"
    show_status
    ;;
  start)   systemctl start k3s-server k3s-agent-worker-1 k3s-agent-worker-2 ;;
  stop)    systemctl stop k3s-server k3s-agent-worker-1 k3s-agent-worker-2 ;;
  status)  show_status ;;
  uninstall) cleanup_previous; log "k3s removido" ;;
  *)       echo "Uso: $0 {install|start|stop|status|uninstall}"; exit 1 ;;
esac
```

## Usage

```bash
# Save and run
chmod +x install-k3s.sh
sudo ./install-k3s.sh

# Custom version and token
sudo K3S_VERSION=v1.30.2 K3S_TOKEN=mycluster ./install-k3s.sh

# Stop cluster
sudo ./install-k3s.sh stop

# Remove completely
sudo ./install-k3s.sh uninstall
```

## Verify Cluster

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes -o wide
```

Expected output:
```
NAME       STATUS   ROLES                  AGE   VERSION
worker-1   Ready    <none>                 2m    v1.30.2
worker-2   Ready    <none>                 2m    v1.30.2
```

> The control-plane node does not appear in `get nodes` because it runs with `--disable-agent`. Only the two workers are registered as separate nodes.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Single Host                        │
│  ┌──────────────────┐                                │
│  │  k3s server      │  --disable-agent               │
│  │  (control-plane)  │  Port 6443                     │
│  └──────┬───────────┘                                │
│         │                                            │
│  ┌──────▼──────────┐  ┌──────────────────────────┐   │
│  │  k3s agent      │  │  k3s agent               │   │
│  │  worker-1       │  │  worker-2                │   │
│  │  :10251         │  │  :10252                  │   │
│  └─────────────────┘  └──────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```
