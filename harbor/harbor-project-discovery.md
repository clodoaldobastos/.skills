---
name: harbor-project-discovery
description: Descobre todos os projetos Harbor disponíveis
tools:
  - bash
---

execute:

curl -s \
-u "$HARBOR_USER:$HARBOR_PASSWORD" \
"https://registry.${DOMINIO}.com/api/v2.0/projects?page_size=500"