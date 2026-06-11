---
name: report-generator
version: 1.0.0
description: Gera relatório executivo e técnico
owner: devops
inputs:
  - chart_name
  - version
  - analysis_data
outputs:
  - executive_report
  - technical_report
---

seções:

  - Resumo Executivo

  - Informações do Chart

  - Dependências

  - Objetos Kubernetes

  - Segurança

  - Recursos

  - Recomendações

  - Riscos