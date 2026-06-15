---
name: conviso-remediate
description: Workflow de remediação de vulnerabilidades encontradas pelo Conviso.
  Cria branch de correção, aplica fix, re-scaneia e valida.
tags:
  - conviso
  - remediation
  - fix
  - vulnerability
---

# Skill: Conviso Remediation Workflow

## Visão Geral

Coordena o workflow de remediação de vulnerabilidades descobertas pelos
scans Conviso. Cria branch dedicada, aplica correções sugeridas,
re-executa scans para validar e prepara o merge request.

## Topologia

```
VULN DETECTED → BRANCH → FIX → RE-SCAN → VALIDATE → MR → APPROVE
```

## Pré-requisitos

- Scan Conviso executado (SAST, SCA ou DAST)
- Relatório de vulnerabilidades disponível
- Repositório Git clonado localmente

## Workflow

### 1. Analisar Vulnerabilidade

```bash
conviso report get --scan-id $SCAN_ID --format json | jq '.findings[] | select(.severity == "critical" or .severity == "high")'
```

### 2. Criar Branch de Correção

```bash
VULN_ID=$(conviso report get --scan-id $SCAN_ID | jq -r '.findings[0].id')
git checkout -b fix/$VULN_ID
```

### 3. Aplicar Correção

```bash
# SAST: corrigir no código-fonte seguindo a recomendação
# SCA: atualizar dependência
npm update lodash  # ou pip install --upgrade requests

# Registrar waiving se falso positivo
# Adicionar em .conviso/waivers.yaml
```

### 4. Re-escanear

```bash
conviso sast scan --path ./src --project my-app --severity critical,high
```

### 5. Validar Correção

```bash
# Verificar se a vulnerabilidade foi resolvida
conviso report compare --scan-id $SCAN_ID --new-scan-id $NEW_SCAN_ID

# Verificar se nenhuma nova vulnerabilidade foi introduzida
conviso gate check --project my-app --block-on-critical true
```

### 6. Criar Merge Request

```bash
git add .
git commit -m "fix: resolve $VULN_ID - $TITLE"
git push origin fix/$VULN_ID

# GitHub CLI
gh pr create --title "fix: resolve $VULN_ID - $TITLE" \
  --body "Resolves $VULN_ID\n\n**Severity:** $SEVERITY\n**File:** $FILE:$LINE\n**Recommendation:** $RECOMMENDATION" \
  --label security
```

## Modelo de Commit

```
fix(security): resolve SQL Injection em src/api/users.py:42

- Substitui concatenação de string por query parametrizada
- Adiciona validação de input no controller

CVE: CWE-89
Severity: critical
Scan: sast-20260529-001
```

## Modelo de Merge Request

```markdown
## Descrição
Correção de vulnerabilidade **[SEVERITY]**: [TITLE]

## Localização
- Arquivo: [FILE]
- Linha: [LINE]
- CWE: [CWE-ID]

## Correção Aplicada
[DESCRIÇÃO DA CORREÇÃO]

## Re-scan
- Antes: [VULNS_BEFORE] vulnerabilidades
- Depois: [VULNS_AFTER] vulnerabilidades
- Status: ✅ Limpo

## Checklist
- [ ] Código revisado
- [ ] Scan aprovado
- [ ] Sem novas vulnerabilidades introduzidas
```

## Automação com Script

```bash
#!/bin/bash
# remediate.sh - Automação parcial de remediação

SCAN_ID=$1
PROJECT=$2

conviso report get --scan-id $SCAN_ID --format json > report.json

jq -c '.findings[] | select(.severity == "critical" or .severity == "high")' report.json | while read finding; do
  VULN_ID=$(echo $finding | jq -r '.id')
  TITLE=$(echo $finding | jq -r '.title')
  FILE=$(echo $finding | jq -r '.file')
  REC=$(echo $finding | jq -r '.recommendation')

  echo "Creating branch for $VULN_ID: $TITLE"
  git checkout -b "fix/$VULN_ID"

  echo "Recommendation: $REC"
  echo "Edit file: $FILE"
  echo "After fixing, run: conviso sast scan --path . --project $PROJECT"
done
```

## Troubleshooting

**Correção não resolve**: verificar se a alteração cobre todos os caminhos de ataque.

**Quebra de teste**: ajustar implementação ou corrigir teste.

**Múltiplas vulnerabilidades no mesmo arquivo**: agrupar correções em um único commit.

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.skills/security/conviso-sast.md`
- `.skills/security/conviso-sca.md`
- `.skills/security/conviso-dast.md`
- `.policies/security/conviso-gate.md`
