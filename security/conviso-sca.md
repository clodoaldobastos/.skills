---
name: conviso-sca
description: Análise de dependências e bibliotecas (SCA) com Conviso.
  Detecta vulnerabilidades em pacotes npm, pip, maven, nuget e mais.
tags:
  - conviso
  - sca
  - dependencies
  - supply-chain
---

# Skill: Conviso SCA Scan

## Visão Geral

Executa análise de composição de software (SCA) para identificar
vulnerabilidades conhecidas em dependências e bibliotecas de terceiros.
Ajuda a prevenir ataques à cadeia de suprimentos de software.

## Pré-requisitos

- Conviso CLI instalado e autenticado
- Manifesto de dependências do projeto (package.json, requirements.txt, pom.xml, etc.)

## Execução

### Scan básico

```bash
conviso sca scan --path ./src --project my-app
```

### Scan com saída detalhada

```bash
conviso sca scan --path ./src --project my-app --format json --output sca-report.json
```

### Scan apenas por severidade

```bash
conviso sca scan --path ./src --project my-app --severity critical,high
```

### Scan com verificação de licenças

```bash
conviso sca scan --path ./src --project my-app --check-license
```

## Interpretação de Resultados

```json
{
  "scan_id": "sca-20260529-001",
  "summary": {
    "total_dependencies": 240,
    "vulnerable": 4,
    "critical": 1,
    "high": 1,
    "medium": 1,
    "low": 1
  },
  "findings": [
    {
      "id": "SCA-001",
      "severity": "critical",
      "package": "lodash",
      "version": "4.17.20",
      "fixed_in": "4.17.21",
      "cve": "CVE-2024-12345",
      "description": "Prototype Pollution in lodash",
      "recommendation": "Upgrade to lodash@4.17.21 or later",
      "status": "open"
    }
  ],
  "licenses": {
    "MIT": 180,
    "Apache-2.0": 40,
    "GPL-3.0": 2,
    "unknown": 18
  }
}
```

## Licenças

O SCA também identifica licenças das dependências:

| Licença | Ação |
|---------|------|
| GPL-3.0/AGPL | ⚠️ Revisão legal recomendada |
| MIT/Apache | ✅ Permissiva |
| Desconhecida | ⚠️ Investigar |

## Correção Automática

```bash
# Atualizar dependência vulnerável
npm update lodash
# ou
pip install --upgrade requests
```

## Ações Recomendadas por Severidade

| Severidade | SLA | Ação |
|------------|-----|------|
| CRITICAL | 24h | Atualizar dependência imediatamente |
| HIGH | 7 dias | Agendar atualização na sprint |
| MEDIUM | 30 dias | Incluir no backlog |
| LOW | 90 dias | Monitorar na próxima release |

## Troubleshooting

**Scan não encontra manifestos**: verificar se `--path` aponta para o diretório correto.

**Muitos falsos positivos em dependências transitivas**: revisar waiving rules.

**Dependência não suportada**: verificar lista de linguagens/ecomanager suportados pelo Conviso.

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.skills/security/conviso-install.md`
- `.skills/security/conviso-sast.md`
- `.skills/security/conviso-remediate.md`
- `.policies/security/conviso-gate.md`
