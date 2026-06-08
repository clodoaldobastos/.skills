---
name: harbor-chart-download
description: Realiza download do Helm Chart OCI
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