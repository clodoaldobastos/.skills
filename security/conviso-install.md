---
name: conviso-install
description: Instalação e configuração do Conviso CLI para scans de segurança.
tags:
  - conviso
  - install
  - setup
  - cli
---

# Skill: Install Conviso CLI

## Visão Geral

Instala o Conviso CLI e configura a autenticação para uso nos scans
SAST, DAST e SCA. Suporta múltiplos sistemas operacionais e métodos
de autenticação.

## Pré-requisitos

- Acesso à internet
- curl instalado
- API Key da plataforma Conviso

## Instalação

### Linux / macOS

```bash
curl -fsSL https://cli.convisoappsec.com/install.sh | bash
```

### Verificar instalação

```bash
conviso --version
```

### Docker

```bash
docker pull convisoappsec/cli:latest
alias conviso='docker run --rm -v "$(pwd):/app" convisoappsec/cli:latest'
```

## Autenticação

### Via API Key

```bash
conviso auth login --api-key $CONVISO_API_KEY
```

### Via interativo

```bash
conviso auth login
```

### Verificar autenticação

```bash
conviso auth status
```

Saída esperada:
```
Authenticated as: user@company.com
Organization: MyOrg
Expires at: 2026-06-28
```

## Configuração de Projeto

Inicializar o Conviso no diretório do projeto:

```bash
conviso init
```

Isso cria o arquivo `.conviso/config.yaml` com a configuração do projeto.

## Configuração de Ambiente

Criar arquivo `.conviso/config.yaml`:

```yaml
project:
  name: my-app
  language: python
  framework: django

scan:
  sast:
    enabled: true
    path: src/
  sca:
    enabled: true
  dast:
    enabled: false

notifications:
  email: security@company.com
  slack: "#security-alerts"
```

## Variáveis de Ambiente

| Variável | Descrição | Obrigatória |
|----------|-----------|-------------|
| CONVISO_API_KEY | Chave de API para autenticação | Sim |
| CONVISO_ORG | Organização Conviso | Não |
| CONVISO_PROJECT | Nome do projeto | Não |
| CONVISO_TIMEOUT | Timeout dos scans (segundos) | Não |

## Troubleshooting

**Permission denied**: `sudo chmod +x /usr/local/bin/conviso`

**API Key inválida**: gerar nova chave no painel Conviso > Settings > API Keys.

**Proxy**: configurar `HTTP_PROXY` e `HTTPS_PROXY` no ambiente.

## Referências

- `.agents/security/conviso-scanner/conviso-scanner.md`
- `.skills/security/conviso-sast.md`
- `.skills/security/conviso-sca.md`
- `.skills/security/conviso-dast.md`
