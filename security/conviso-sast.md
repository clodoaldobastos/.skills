---
name: conviso-sast
description: Análise estática de código-fonte (SAST) com Conviso.
  Detecta vulnerabilidades como SQL Injection, XSS, CSRF, hardcoded secrets e mais.
tags:
  - conviso
  - sast
  - static-analysis
  - code-scanning
---

# Skill: Conviso SAST Scan

## Visão Geral

Executa análise estática de código-fonte usando o motor SAST do Conviso.
Escaneia o código sem executá-lo, identificando padrões inseguros,
vulnerabilidades conhecidas e más práticas de programação.

## Topologia

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Código-fonte│────►│ Conviso SAST │────►│  Resultados  │
│  (repo)      │     │  Engine      │     │  (JSON/SARIF)│
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                 ▼
                                        ┌──────────────┐
                                        │  Relatório   │
                                        │  + Correções │
                                        └──────────────┘
```

## Pré-requisitos

- Conviso CLI instalado e autenticado (ver `conviso-install.md`)
- Código-fonte do projeto acessível localmente

## Execução

### Scan básico

```bash
conviso sast scan --path ./src --project my-app
```

### Scan com severidade mínima

```bash
conviso sast scan --path ./src --project my-app --severity high,critical
```

### Scan com output SARIF

```bash
conviso sast scan --path ./src --project my-app --format sarif --output results.sarif
```

### Scan ignorando falsos positivos

```bash
conviso sast scan --path ./src --project my-app --waiver-file .conviso/waivers.yaml
```

## Interpretação de Resultados

```json
{
  "scan_id": "sast-20260529-001",
  "summary": {
    "total": 5,
    "critical": 1,
    "high": 2,
    "medium": 1,
    "low": 1
  },
  "findings": [
    {
      "id": "CONV-001",
      "severity": "critical",
      "title": "SQL Injection",
      "file": "src/api/users.py:42",
      "description": "String concatenation in SQL query",
      "recommendation": "Use parameterized queries",
      "cwe": "CWE-89",
      "status": "open"
    }
  ]
}
```

### Criticidade

| Severidade | Ação |
|------------|------|
| CRITICAL | Correção imediata, bloqueia deploy |
| HIGH | Correção na sprint, bloqueia deploy se > 5 |
| MEDIUM | Correção no próximo ciclo |
| LOW | Backlog técnico |

## Waiving de Falsos Positivos

Criar `.conviso/waivers.yaml`:

```yaml
waivers:
  - id: CONV-001
    reason: "Input sanitized by framework ORM"
    expires: "2026-07-01"
    approved_by: "security-lead"
```

## Integração com Git

```bash
# Scannear apenas diff do PR
git diff --name-only main...HEAD | xargs conviso sast scan --path
```

## Troubleshooting

**Scan muito lento**: excluir diretórios com `--exclude vendor,node_modules,.venv`

**Falso positivo comum em frameworks**: adicionar waiving rules no `.conviso/waivers.yaml`

**Erro de parsing**: verificar se a linguagem é suportada pelo Conviso

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.agents/security/security-agent/agent-security.md`
- `.skills/security/conviso-install.md`
- `.skills/security/conviso-remediate.md`
- `.policies/security/conviso-gate.md`
