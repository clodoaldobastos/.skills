---
name: skill-analise-versao
version: 1.0.0
description: >
  Valida YAML contra chart Harbor e documentação.
  Use quando o agente matera-analise-versao for chamado
  ou quando solicitado a comparar/validar versões.

owner: matera
inputs:
  - projeto
  - chart
  - versao
  - pasta_yaml
  - arquivo_doc  # Opcional: se omitido, descoberto automaticamente (passo 1A)
outputs:
  - conformity_report
---

# Skill: Análise de Versão

## 1. Credenciais Harbor
- Ler `.secrets/harbor.env`
- Extrair: `HARBOR_USER`, `HARBOR_PASSWORD`, `HARBOR_URL`

## 1A. Auto-descoberta do(s) arquivo(s) de documentação
- Se `{arquivo_doc}` NÃO foi fornecido:
  1. Listar todos os arquivos em `{pasta_yaml}/doc/`
  2. Priorizar `.md` — filtrar os que contêm `{versao}` no nome
  3. Se houver exatamente 1 match `.md`, usar como `{arquivo_doc}`
  4. Se houver 0 matches `.md` com a versão, tentar qualquer `.md` (primeiro encontrado)
  5. Se ainda sem `.md`, tentar extrair texto de `.pdf` via `pdftotext` (se disponível) e usar como `{arquivo_doc}`
  6. Se múltiplos arquivos forem encontrados (`.md` + `.pdf`), **ler todos** e consolidar o conteúdo para a etapa 7
  7. Se nada encontrado, definir como `N/A` e pular etapa 7
- Se `{arquivo_doc}` foi fornecido mas não existe no disco, tentar o mesmo fallback acima
- **Nota:** Para `.pdf`, extrair texto com `pdftotext` (poppler-utils) e ler o resultado em `.txt`

## 2. Buscar repositório do chart no Harbor

```bash
curl -s -u "$HARBOR_USER:$HARBOR_PASSWORD" \
  "$HARBOR_URL/api/v2.0/projects/{projeto}/repositories?page=1&page_size=100" \
  | jq '.[] | select(.name | endswith("/{chart}"))'
```

Extrair `name` (usar como `repo_name` codificado para URL, ex: `charts%2Fmp-core`).

## 3. Obter metadados da versão

```bash
curl -s -u "$HARBOR_USER:$HARBOR_PASSWORD" \
  "$HARBOR_URL/api/v2.0/projects/{projeto}/repositories/{repo_name}/artifacts?page=1&page_size=50" \
  | jq '.[] | select(.extra_attrs.version == "{versao}")'
```

Extrair:
- `extra_attrs.appVersion`
- `extra_attrs.dependencies[].name` — subcharts
- `extra_attrs.dependencies[].version`
- `annotations` (data de criação, descrição)
- `digest`

## 4. Tentar obter values.yaml do chart (via additions API)

```bash
curl -s -u "$HARBOR_USER:$HARBOR_PASSWORD" \
  "$HARBOR_URL/api/v2.0/projects/{projeto}/repositories/{repo_name}/artifacts/{digest}/additions/values.yaml"
```

Se falhar (HTTP 000/404), registrar que values.yaml não está disponível via API.

## 5. Ler YAML local

- Encontrar arquivos `.yaml`/`.yml` em `{pasta_yaml}`
- Identificar seções de topo (ex: `global`, `application-server-admin`, etc.)

## 6. Comparar YAML vs Chart

### 6.1. Version tag
- Se YAML tem `global.image.tag`, comparar com `appVersion` do chart
- Reportar divergências

### 6.2. Alinhamento de subcharts
- Para cada seção de topo no YAML:
  - Se existe como `dependencies[].name` no chart → ✅
  - Se NÃO existe → ❌ **fora do chart** (pode pertencer a outro chart)
- Para cada `dependencies[].name` no chart:
  - Se não tem seção correspondente no YAML → ℹ️ **usa defaults**

### 6.3. Valores vs defaults
- Se `values.yaml` foi obtido, comparar valores do YAML com defaults
- Reportar divergências significativas

## 7. Validar contra documentação

Ler `{arquivo_doc}`. Extrair itens como:
- **Propriedades obrigatórias** (ex: `cadastro-central.alphanumeric-cnpj-validation-start-date`)
- **Feature flags** (ex: `antifraud.enabled`, `cache.provider`)
- **Pré-requisitos de infra** (ex: criação de filas, tópicos, tabelas)
- **Mudanças comportamentais** (ex: exchange Fanout → Topic)

Para cada item, verificar se existe no YAML e classificar:

| Marcação | Significado |
|----------|-------------|
| ✅ Conforme | Configurado corretamente no YAML |
| ❌ Não conforme | Ausente ou com valor/propriedade incorreta |
| ⚠️ Parcial | Existe mas incompleto |
| ℹ️ N/A | Não se aplica ao contexto |

## 8. Gerar Relatório

- Salvar o relatório em `{pasta_yaml}/relatorio/relatorio-validacao-{chart}-{versao}.md`
- Criar diretório `{pasta_yaml}/relatorio/` se não existir

```markdown
## Relatório: {projeto}/{chart} {versao}

### 1. Metadados
- Projeto: {projeto}
- Chart: {chart}
- Versão: {versao}
- AppVersion: {appVersion}
- YAML: {pasta_yaml}
- Documento: {arquivo_doc}

### 2. Estrutura YAML vs Chart
| Seção no YAML | Subchart? | Status | Observação |
|---|---|---|---|

### 3. Documentação vs Configuração
| Requisito | Status | Detalhe |
|---|---|---|

### 4. Não Conformidades
Lista ordenada dos itens ❌ e ⚠️.

### 5. Recomendações
Ações corretivas sugeridas.
```
