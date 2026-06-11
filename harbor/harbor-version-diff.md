---
name: harbor-version-diff
version: 1.0.0
description: Compara versões de um chart
owner: devops
inputs:
  - old_version
  - new_version
outputs:
  - diff_report
tools:
  - helm
  - bash
---

inputs:

  old_version
  new_version

processo:

  baixar_versao_antiga

  baixar_versao_nova

  helm template old

  helm template new

  diff