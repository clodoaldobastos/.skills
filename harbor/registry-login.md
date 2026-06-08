---
name: registry-login
description: Realiza autenticação no Harbor 
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