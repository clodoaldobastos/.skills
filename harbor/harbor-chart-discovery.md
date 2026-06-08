---
name: harbor-chart-discovery
description: Localiza charts OCI em qualquer projeto Harbor
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