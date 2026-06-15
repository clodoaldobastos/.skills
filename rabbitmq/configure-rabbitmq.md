---
name: configure-rabbitmq
description: Configuração operacional do RabbitMQ via Ansible.
  Cria vhosts, usuários, permissões, políticas e ativa plugins.
tags:
  - rabbitmq
  - ansible
  - configuration
  - vhost
  - policy
---

# Skill: Configure RabbitMQ (Ansible)

## Visão Geral

Aplica configuração operacional em um cluster RabbitMQ já implantado.
Usa os módulos `community.rabbitmq.*` para gerenciar vhosts, usuários,
políticas e plugins de forma idempotente.

## Pré-requisitos

- RabbitMQ operacional (ver skill `install-rabbitmq.md`)
- Ansible >= 2.15 com collection `community.rabbitmq`
- Acesso network ao service RabbitMQ (via `kubectl port-forward` ou service DNS)

## Inventory

```yaml
# inventory.yml
all:
  hosts:
    rabbitmq:
      ansible_host: localhost
      ansible_port: 15672
      ansible_connection: local
      rabbitmq_api_host: "{{ lookup('env', 'RABBITMQ_HOST') | default('localhost', true) }}"
      rabbitmq_api_port: 15672
      rabbitmq_user: "{{ lookup('env', 'RABBITMQ_USER') | default('admin', true) }}"
      rabbitmq_password: "{{ lookup('env', 'RABBITMQ_PASSWORD') }}"
```

## Playbook

```yaml
# configure-rabbitmq.yml
- name: Configure RabbitMQ cluster
  hosts: rabbitmq
  vars:
    rabbitmq_vhosts:
      - name: /dev
        description: Desenvolvimento
      - name: /prod
        description: Produção
      - name: /qa
        description: Homologação

    rabbitmq_users:
      - username: app_dev
        password: "{{ vault_app_dev_password }}"
        tags: "developer"
        vhost_permissions:
          - vhost: /dev
            configure_priv: ".*"
            write_priv: ".*"
            read_priv: ".*"
      - username: app_prod
        password: "{{ vault_app_prod_password }}"
        tags: "producer,consumer"
        vhost_permissions:
          - vhost: /prod
            configure_priv: ""
            write_priv: ".*"
            read_priv: ".*"
      - username: monitoring
        password: "{{ vault_monitoring_password }}"
        tags: "monitoring"
        vhost_permissions:
          - vhost: /dev
            configure_priv: ""
            write_priv: ""
            read_priv: ".*"

    rabbitmq_policies:
      - name: ha-all
        vhost: /prod
        pattern: ".*"
        definition:
          ha-mode: all
          ha-sync-mode: automatic
        priority: 1
      - name: ttl-30d
        vhost: /prod
        pattern: "log.*"
        definition:
          message-ttl: 2592000000
          max-length: 1000000
        priority: 0
      - name: dead-letter
        vhost: /prod
        pattern: "work.*"
        definition:
          dead-letter-exchange: dlx
          dead-letter-routing-key: dlq
        priority: 0

  tasks:
    - name: Create vhosts
      community.rabbitmq.rabbitmq_vhost:
        name: "{{ item.name }}"
        description: "{{ item.description | default(omit) }}"
        tracing: "{{ item.tracing | default(false) }}"
        state: present
      loop: "{{ rabbitmq_vhosts }}"

    - name: Create users
      community.rabbitmq.rabbitmq_user:
        username: "{{ item.username }}"
        password: "{{ item.password }}"
        tags: "{{ item.tags | default('') }}"
        state: present
      loop: "{{ rabbitmq_users }}"
      no_log: true

    - name: Set user permissions per vhost
      community.rabbitmq.rabbitmq_user:
        username: "{{ item.0.username }}"
        vhost: "{{ item.1.vhost }}"
        configure_priv: "{{ item.1.configure_priv }}"
        write_priv: "{{ item.1.write_priv }}"
        read_priv: "{{ item.1.read_priv }}"
        state: present
      loop: "{{ rabbitmq_users | subelements('vhost_permissions') }}"
      no_log: true

    - name: Apply policies
      community.rabbitmq.rabbitmq_policy:
        name: "{{ item.name }}"
        vhost: "{{ item.vhost }}"
        pattern: "{{ item.pattern }}"
        definition: "{{ item.definition }}"
        priority: "{{ item.priority | default(0) }}"
        apply_to: "{{ item.apply_to | default('all') }}"
        state: present
      loop: "{{ rabbitmq_policies }}"

    - name: Enable plugins
      community.rabbitmq.rabbitmq_plugin:
        names: "{{ item }}"
        state: enabled
      loop:
        - rabbitmq_management
        - rabbitmq_prometheus
        - rabbitmq_shovel
        - rabbitmq_federation
        - rabbitmq_consistent_hash_exchange
```

## Configuração de Vault

```bash
ansible-vault create group_vars/all/vault.yml
```

Estrutura do vault:

```yaml
vault_app_dev_password: "dev-secure-password"
vault_app_prod_password: "prod-secure-password"
vault_monitoring_password: "monitoring-secure-password"
```

## Execução

Inicie o port-forward em um terminal separado:

```bash
kubectl port-forward -n rabbitmq svc/rabbitmq 15672:15672 &
```

Execute o playbook:

```bash
ansible-playbook -i inventory.yml configure-rabbitmq.yml --ask-vault-pass
```

## Validação

```bash
# Listar vhosts
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_vhosts

# Listar usuários e permissões
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_permissions

# Listar políticas
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_policies

# Listar plugins ativos
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_plugins
```

## Troubleshooting

**Erro "401 Unauthorized"**: usuário admin padrão ou senha incorreta. Verificar o secret.

**Erro "403 access refused"**: o usuário admin precisa de permissão de configuração no vhost alvo. Usar `rabbitmqctl set_permissions -p /prod admin ".*" ".*" ".*"`.

**Policy não aplicada**: RabbitMQ não aplica policies retroativamente. Usar `rabbitmqctl set_policy` manualmente ou re-publicar mensagens.

## Referências

- `.agents/platform/agent-rabbitmq/rabbitmq-agent/rabbitmq-agent.md`
- `.templates/ansible-role/rabbitmq-config/`
- `.skills/rabbitmq/install-rabbitmq.md`
