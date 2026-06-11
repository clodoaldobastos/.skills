---
name: kubernetes-security-analysis
version: 1.0.0
description: Analisa riscos Kubernetes
owner: devops
inputs:
  - manifest_yaml
outputs:
  - security_report
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