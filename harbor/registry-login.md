---
name: registry-login
version: 1.0.0
description: Realiza autenticação no Harbor
owner: devops
inputs:
  - harbor_url
  - harbor_user
  - harbor_password
outputs:
  - session_file
tools:
  - playwright
---

steps:

  - acessar:
      https://registry.${DOMINIO}.com/account/sign-in

  - preencher:
      usuario: ${HARBOR_USER}

  - preencher:
      senha: ${HARBOR_PASSWORD}

  - clicar:
      Sign In

  - aguardar:
      harbor/projects

  - exportar:
      session:
        .sessions/registry-session.json