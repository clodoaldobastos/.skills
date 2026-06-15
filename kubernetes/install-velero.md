# Install Velero (Backup & Restore)

## Overview
Velero é uma ferramenta open source para backup, restore e migração de clusters Kubernetes. Usa S3-compatible storage como backend.

## Pré-requisitos
- kubectl configurado
- Acesso de cluster-admin ao cluster

## Topologia

```
┌─────────────────────────────────────────────────────────┐
│                    Cluster Kubernetes                     │
│                                                          │
│  ┌──────────┐    backup/restore    ┌──────────────────┐  │
│  │ Velero   │ ──────────────────►  │    MinIO (S3)     │  │
│  │ Server   │ ◄──────────────────  │  velero-backups   │  │
│  └──────────┘                      │    bucket         │  │
│       │                            └──────────────────┘  │
│       ▼                                                   │
│  ┌──────────┐                                            │
│  │ Aplicação│                                            │
│  │ (default)│                                            │
│  └──────────┘                                            │
└─────────────────────────────────────────────────────────┘
```

## Instalação

### 1. MinIO + infra

```bash
kubectl apply -f projects/hello-world/k8s/velero-manifest.yaml
```

Aguarda o bucket ser criado:
```bash
kubectl -n velero wait --for=condition=complete job/minio-create-bucket --timeout=60s
```

### 2. Velero CLI

```bash
VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | jq -r '.tag_name' | sed 's/^v//')
curl -Lo /tmp/velero.tar.gz "https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz"
tar xzf /tmp/velero.tar.gz -C /tmp/
sudo mv /tmp/velero-v${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/
```

### 3. Velero server

```bash
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.10.0 \
  --bucket velero-backups \
  --secret-file <(kubectl get secret cloud-credentials -n velero -o jsonpath='{.data.cloud}' | base64 -d) \
  --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio.velero.svc.cluster.local:9000 \
  --use-volume-snapshots=false \
  --namespace velero \
  --wait
```

### 4. Verificar

```bash
velero version
velero backup-location get
velero plugin get
```

## Exemplos

### Backup manual

```bash
velero backup create hello-world-backup \
  --include-namespaces default \
  --ttl 72h
```

### Schedule diário

```bash
velero schedule create daily-backup \
  --schedule "0 2 * * *" \
  --include-namespaces default \
  --ttl 168h
```

### Restore (com dry-run)

```bash
velero restore create --from-backup hello-world-backup --dry-run
velero restore create --from-backup hello-world-backup
```

### Migrar para outro namespace

```bash
velero restore create --from-backup hello-world-backup \
  --namespace-mappings default:hello-restored
```

## Troubleshooting

**Backup stuck InProgress**: `kubectl -n velero logs deployment/velero`

**MinIO bucket não criado**: `kubectl -n velero logs job/minio-create-bucket`

**Restore não aparece recursos**: o backup precisa incluir o namespace alvo com `--include-namespaces`

## Referências
- `.agents/platform/agent-kubernetes/velero-agent/velero-agent.md`
- `.rules/kubernetes-rules.md`
