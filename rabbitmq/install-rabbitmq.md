---
name: install-rabbitmq
description: Deploy do RabbitMQ no AKS via Terraform e Helm chart bitnami/rabbitmq.
  Inclui values.yaml parametrizável e validação pós-deploy.
tags:
  - rabbitmq
  - helm
  - terraform
  - aks
  - kubernetes
---

# Skill: Install RabbitMQ via Terraform + Helm

## Visão Geral

Realiza o deploy completo do RabbitMQ no AKS usando Terraform com o Helm provider
e o chart oficial `bitnami/rabbitmq`. Ideal para ambientes corporativos que exigem
rastreabilidade GitOps e separação entre infraestrutura e configuração.

## Topologia

```
┌────────────────────────────────────────────────────────────┐
│                      Cluster AKS                            │
│                                                             │
│  ┌──────────────────────────────────────────────────┐       │
│  │  Namespace: rabbitmq                              │       │
│  │                                                    │       │
│  │  ┌────────────────────┐  statefulset  ┌────────┐  │       │
│  │  │ rabbitmq-0         │ ◄──────────── │ PVC    │  │       │
│  │  │ rabbitmq-1         │ ◄──────────── │ PVC    │  │       │
│  │  │ rabbitmq-2         │ ◄──────────── │ PVC    │  │       │
│  │  └────────┬───────────┘              └────────┘  │       │
│  │           │                                      │       │
│  │  ┌────────┴───────────┐                          │       │
│  │  │ Service: rabbitmq  │  ports: 5672, 15672      │       │
│  │  └────────────────────┘                          │       │
│  │                                                    │       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## Pré-requisitos

- Cluster AKS operacional
- kubectl com contexto configurado
- Terraform >= 1.5
- Helm >= 3.12
- Acesso ao registry bitnami/rabbitmq

## Passos

### 1. Preparar values.yaml

Crie um `values.yaml` personalizado:

```yaml
replicaCount: 3
auth:
  username: admin
  password: "{{ RABBITMQ_PASSWORD }}"
  existingPasswordSecret: rabbitmq-secret
persistence:
  enabled: true
  size: 8Gi
  storageClass: managed-csi-premium
service:
  type: ClusterIP
resources:
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1
metrics:
  enabled: true
  podMonitor:
    enabled: true
plugins: "rabbitmq_management rabbitmq_peer_discovery_k8s rabbitmq_prometheus"
loadDefinition:
  enabled: false
```

### 2. Terraform module

```hcl
module "rabbitmq" {
  source = "./.templates/terraform-module/aks-rabbitmq"

  cluster_name        = var.cluster_name
  namespace           = var.namespace
  release_name        = var.release_name
  chart_version       = var.chart_version
  rabbitmq_user       = var.rabbitmq_user
  rabbitmq_password   = var.rabbitmq_password
  replicas            = var.replicas
  storage_size        = var.storage_size
  values_file         = "values.yaml"
}
```

### 3. Executar

```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -auto-approve
```

### 4. Validar

```bash
kubectl wait --namespace rabbitmq \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=rabbitmq \
  --timeout=300s

kubectl get pods -n rabbitmq
kubectl exec -n rabbitmq deploy/rabbitmq -- rabbitmqctl cluster_status
kubectl -n rabbitmq port-forward svc/rabbitmq 15672:15672 &
curl -u admin:$PASSWORD http://localhost:15672/api/overview
```

## Rollback

```bash
terraform destroy -auto-approve
```

Ou via Helm diretamente:
```bash
helm uninstall rabbitmq -n rabbitmq
kubectl delete pvc -n rabbitmq --all
kubectl delete namespace rabbitmq
```

## Troubleshooting

**PVC pendente**: verificar storage class disponível no AKS:
```bash
kubectl get storageclass
```

**Erro de quota**: verificar resource limits no namespace.

**CrashLoopBackOff**: `kubectl logs -n rabbitmq rabbitmq-0` — checar permissões de diretório.

## Referências

- `.agents/platform/agent-rabbitmq/rabbitmq-agent/rabbitmq-agent.md`
- `.templates/terraform-module/aks-rabbitmq/`
- `.rules/kubernetes-rules.md`
