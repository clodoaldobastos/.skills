---
name: harbor-chart-discovery
version: 1.0.0
description: Localiza charts OCI em qualquer projeto Harbor
owner: devops
inputs:
  - chart_name
outputs:
  - project
  - repository
  - oci_path
tools:
  - bash
---

input:

  chart_name

algoritmo:

  listar_projetos

  para cada projeto:

      listar_repositories

      procurar:
          chart_name

      se encontrar:

          retornar:
              projeto
              repository
              oci_path