---
name: conviso-pipeline
description: Integração do Conviso em pipelines CI/CD com gates de segurança.
  Gera YAML de pipeline para Azure DevOps, GitHub Actions e GitLab CI.
tags:
  - conviso
  - pipeline
  - ci-cd
  - devsecops
  - azure-devops
  - github-actions
  - gitlab
---

# Skill: Conviso Pipeline Integration

## Visão Geral

Integra os scans Conviso (SAST, SCA, DAST) em pipelines CI/CD com gates
automáticos que bloqueiam deploys com base na severidade das vulnerabilidades.
Suporta Azure DevOps, GitHub Actions e GitLab CI.

## Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: ubuntu-latest

variables:
  CONVISO_API_KEY: $(CONVISO_API_KEY)  # Azure DevOps Secret

steps:
  - checkout: self

  - script: |
      curl -fsSL https://cli.convisoappsec.com/install.sh | bash
      conviso auth login --api-key $(CONVISO_API_KEY)
    displayName: "Setup Conviso CLI"

  - script: |
      conviso sast scan --path $(System.DefaultWorkingDirectory) \
        --project $(Build.Repository.Name) \
        --severity critical,high
    displayName: "Conviso SAST Scan"

  - script: |
      conviso sca scan --path $(System.DefaultWorkingDirectory) \
        --project $(Build.Repository.Name) \
        --severity critical,high
    displayName: "Conviso SCA Scan"

  - task: ConvisoGate@1
    inputs:
      apiKey: $(CONVISO_API_KEY)
      project: $(Build.Repository.Name)
      blockOnCritical: true
      blockOnHighThreshold: 5
    displayName: "Conviso Security Gate"
```

## GitHub Actions

```yaml
# .github/workflows/conviso-scan.yml
name: Conviso Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Conviso CLI
        run: |
          curl -fsSL https://cli.convisoappsec.com/install.sh | bash
          conviso auth login --api-key ${{ secrets.CONVISO_API_KEY }}

      - name: SAST Scan
        run: |
          conviso sast scan --path . \
            --project ${{ github.repository }} \
            --severity critical,high

      - name: SCA Scan
        run: |
          conviso sca scan --path . \
            --project ${{ github.repository }} \
            --severity critical,high

      - name: Security Gate
        run: |
          conviso gate check \
            --project ${{ github.repository }} \
            --block-on-critical \
            --block-on-high 5
        env:
          CONVISO_API_KEY: ${{ secrets.CONVISO_API_KEY }}
```

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - security-scan

conviso-security:
  stage: security-scan
  image: convisoappsec/cli:latest
  variables:
    CONVISO_API_KEY: $CONVISO_API_KEY
  script:
    - conviso auth login --api-key $CONVISO_API_KEY
    - conviso sast scan --path . --project $CI_PROJECT_NAME --severity critical,high
    - conviso sca scan --path . --project $CI_PROJECT_NAME --severity critical,high
    - conviso gate check --project $CI_PROJECT_NAME --block-on-critical --block-on-high 5
  only:
    - main
    - develop
    - merge_requests
```

## Security Gate

O gate de segurança decide se o pipeline deve prosseguir:

```bash
conviso gate check \
  --project my-app \
  --block-on-critical true \
  --block-on-high 5
```

### Comportamento

| Condição | Resultado |
|----------|-----------|
| Críticas = 0 e High ≤ 5 | ✅ Pipeline prossegue |
| Críticas ≥ 1 | ❌ Pipeline bloqueado |
| High > 5 | ❌ Pipeline bloqueado |

## Configuração de Notificações

```yaml
# .conviso/notifications.yaml
alerts:
  critical:
    slack: "#security-critical"
    email: "security-leads@company.com"
  high:
    slack: "#security-alerts"
    email: "dev-team@company.com"
  pipeline_blocked:
    slack: "#security-gate"
    email: "devops@company.com"
```

## Troubleshooting

**Pipeline quebrado por falso positivo**: adicionar waiving em `.conviso/waivers.yaml` e re-executar.

**Secret não encontrado**: verificar se a variável está configurada no CI/CD.

**DAST em pipeline**: DAST precisa de ambiente executando — usar job separado com service container.

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.policies/security/conviso-gate.md`
- `.skills/security/conviso-install.md`
- `.skills/security/conviso-sast.md`
- `.skills/security/conviso-sca.md`
