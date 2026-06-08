---
name: kubernetes-security-analysis
description: Analisa riscos Kubernetes
tools:
  - bash
---

validar:

  - RBAC
  - ServiceAccounts
  - ClusterRoles
  - SecurityContext
  - Privileged
  - HostPath
  - Capabilities
  - NetworkPolicy
  - PodDisruptionBudget
  - ResourceLimits
  - ResourceRequests
  - HPA
  - Ingress