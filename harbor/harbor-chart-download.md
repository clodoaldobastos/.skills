---
name: harbor-chart-download
version: 1.0.0
description: Realiza download do Helm Chart OCI
owner: devops
inputs:
  - oci_path
  - version
outputs:
  - chart_directory
tools:
  - helm
---

inputs:

  oci_path

  version

commands:

helm pull \
${oci_path} \
--version ${version} \
--untar