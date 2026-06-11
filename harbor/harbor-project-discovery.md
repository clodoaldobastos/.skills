---
name: harbor-project-discovery
version: 1.0.0
description: Descobre todos os projetos Harbor disponíveis
owner: devops
inputs:
  - harbor_url
  - harbor_user
  - harbor_password
outputs:
  - projects_list
tools:
  - bash
---

execute:

curl -s \
-u "$HARBOR_USER:$HARBOR_PASSWORD" \
"https://registry.${DOMINIO}.com/api/v2.0/projects?page_size=500"