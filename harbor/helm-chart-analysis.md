---
name: helm-chart-analysis
version: 1.0.0
description: Analisa estrutura Helm
owner: devops
inputs:
  - chart_path
outputs:
  - lint_result
  - rendered_yaml
  - analysis_report
tools:
  - helm
  - bash
---

executar:

helm lint .

helm dependency list .

helm template release . \
> rendered.yaml

analisar:

  - Chart.yaml
  - values.yaml
  - templates/
  - charts/
  - crds/