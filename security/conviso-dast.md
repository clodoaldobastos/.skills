---
name: conviso-dast
description: Análise dinâmica de aplicações (DAST) com Conviso.
  Testa aplicações em execução contra vulnerabilidades como XSS, SQLi, SSRF e CSRF.
tags:
  - conviso
  - dast
  - dynamic-analysis
  - pentest
---

# Skill: Conviso DAST Scan

## Visão Geral

Executa análise dinâmica de segurança contra aplicações em execução.
Diferente do SAST, o DAST testa a aplicação de fora para dentro, identificando
vulnerabilidades no runtime que só aparecem durante a execução.

## Topologia

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Aplicação   │◄────┤ Conviso DAST │────►│  Resultados  │
│  (staging)   │     │  Engine      │     │  (JSON/SARIF)│
└──────────────┘     └──────────────┘     └──────┬───────┘
       ▲                                          ▼
       │                                 ┌──────────────┐
       └─────────────────────────────────┤  Relatório   │
                                         │  + Evidências│
                                         └──────────────┘
```

## Pré-requisitos

- Conviso CLI instalado e autenticado
- Aplicação alvo em execução (staging ou homologação)
- URL base da aplicação acessível
- Autorização explícita para testar o ambiente

## Execução

### Scan básico

```bash
conviso dast scan --url https://staging.app.com --project my-app
```

### Scan com autenticação

```bash
conviso dast scan \
  --url https://staging.app.com \
  --auth-type form \
  --auth-login-url https://staging.app.com/login \
  --auth-username user@test.com \
  --auth-password secret123 \
  --project my-app
```

### Scan com cookie de sessão

```bash
conviso dast scan \
  --url https://staging.app.com \
  --cookie "session=abc123; token=xyz" \
  --project my-app
```

### Scan rapido (após alterações)

```bash
conviso dast scan --url https://staging.app.com --fast --project my-app
```

### Scan com crawl limitado

```bash
conviso dast scan --url https://staging.app.com --max-pages 50 --project my-app
```

## Interpretação de Resultados

```json
{
  "scan_id": "dast-20260529-001",
  "summary": {
    "total": 3,
    "high": 1,
    "medium": 1,
    "low": 1
  },
  "findings": [
    {
      "id": "DAS-001",
      "severity": "high",
      "title": "Reflected XSS",
      "endpoint": "/search?q=test",
      "method": "GET",
      "parameter": "q",
      "payload": "<script>alert(1)</script>",
      "recommendation": "Sanitize output with context-aware encoding",
      "status": "open"
    }
  ],
  "endpoints_tested": 30,
  "requests_made": 450,
  "duration": "12m 30s"
}
```

## Boas Práticas

- **Nunca** executar DAST em produção sem janela de testes agendada
- Usar ambiente de staging ou homologação
- Autenticação pode ser necessária para alcançar endpoints protegidos
- Para APIs, usar `--api-format openapi` e passar o arquivo de spec

## Troubleshooting

**401 Unauthorized**: configurar autenticação com `--auth-*` ou `--cookie`.

**Muitos falsos positivos em formulários**: ajustar `--exclude-pattern` para endpoints conhecidos.

**Scan muito agressivo**: usar `--max-concurrent-requests 5` e `--delay 1000ms`.

**Timeout**: aumentar com `--timeout 3600`.

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.skills/security/conviso-install.md`
- `.skills/security/conviso-remediate.md`
- `.policies/security/conviso-gate.md`
