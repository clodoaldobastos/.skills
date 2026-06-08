---
name: helm-chart-analysis
description: Analisa estrutura Helm
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