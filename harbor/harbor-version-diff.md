---
name: harbor-version-diff
description: Compara versões de um chart
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