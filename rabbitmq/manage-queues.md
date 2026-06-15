---
name: manage-queues
description: Declaração de filas, exchanges e bindings no RabbitMQ via Ansible.
tags:
  - rabbitmq
  - ansible
  - queues
  - exchanges
  - bindings
---

# Skill: Manage Queues (Ansible)

## Visão Geral

Gerencia o ciclo de vida de filas, exchanges e bindings no RabbitMQ
usando Ansible. Ideal para ambientes com dezenas ou centenas de filas
que precisam ser versionadas via GitOps.

## Pré-requisitos

- RabbitMQ configurado (ver skills `install-rabbitmq.md` e `configure-rabbitmq.md`)
- Ansible >= 2.15 com collection `community.rabbitmq`
- Vhosts e usuários já criados

## Playbook

```yaml
# manage-queues.yml
- name: Manage RabbitMQ queues, exchanges, and bindings
  hosts: rabbitmq
  vars:
    rabbitmq_exchanges:
      - name: service.direct
        type: direct
        vhost: /prod
        durable: true
      - name: service.topic
        type: topic
        vhost: /prod
        durable: true
      - name: service.fanout
        type: fanout
        vhost: /prod
        durable: true
      - name: service.delayed
        type: x-delayed-message
        vhost: /prod
        arguments:
          x-delayed-type: direct
        durable: true
      - name: dlx
        type: direct
        vhost: /prod
        durable: true

    rabbitmq_queues:
      # Work queues
      - name: work.orders
        vhost: /prod
        durable: true
        arguments:
          x-dead-letter-exchange: dlx
          x-dead-letter-routing-key: dlq.orders
          x-message-ttl: 86400000

      - name: work.notifications
        vhost: /prod
        durable: true
        arguments:
          x-dead-letter-exchange: dlx
          x-dead-letter-routing-key: dlq.notifications
          x-max-length: 10000

      # Dead letter queues
      - name: dlq.orders
        vhost: /prod
        durable: true

      - name: dlq.notifications
        vhost: /prod
        durable: true

      # Delayed queues
      - name: delayed.retry
        vhost: /prod
        durable: true
        arguments:
          x-dead-letter-exchange: service.direct
          x-dead-letter-routing-key: work.orders

      # Priority queue
      - name: priority.alerts
        vhost: /prod
        durable: true
        arguments:
          x-max-priority: 10

    rabbitmq_bindings:
      - source: service.topic
        destination: work.orders
        destination_type: queue
        routing_key: "order.created"
        vhost: /prod
      - source: service.topic
        destination: work.notifications
        destination_type: queue
        routing_key: "notification.*"
        vhost: /prod
      - source: service.direct
        destination: work.orders
        destination_type: queue
        routing_key: work.orders
        vhost: /prod
      - source: dlx
        destination: dlq.orders
        destination_type: queue
        routing_key: dlq.orders
        vhost: /prod
      - source: dlx
        destination: dlq.notifications
        destination_type: queue
        routing_key: dlq.notifications
        vhost: /prod
      - source: service.delayed
        destination: delayed.retry
        destination_type: queue
        routing_key: delayed.retry
        arguments:
          x-delay: 30000
        vhost: /prod
      - source: service.fanout
        destination: priority.alerts
        destination_type: queue
        routing_key: ""
        vhost: /prod

  tasks:
    - name: Create exchanges
      community.rabbitmq.rabbitmq_exchange:
        name: "{{ item.name }}"
        type: "{{ item.type }}"
        vhost: "{{ item.vhost }}"
        durable: "{{ item.durable | default(true) }}"
        arguments: "{{ item.arguments | default(omit) }}"
        state: present
      loop: "{{ rabbitmq_exchanges }}"

    - name: Create queues
      community.rabbitmq.rabbitmq_queue:
        name: "{{ item.name }}"
        vhost: "{{ item.vhost }}"
        durable: "{{ item.durable | default(true) }}"
        arguments: "{{ item.arguments | default(omit) }}"
        state: present
      loop: "{{ rabbitmq_queues }}"

    - name: Create bindings
      community.rabbitmq.rabbitmq_binding:
        source: "{{ item.source }}"
        destination: "{{ item.destination }}"
        destination_type: "{{ item.destination_type }}"
        routing_key: "{{ item.routing_key }}"
        arguments: "{{ item.arguments | default(omit) }}"
        vhost: "{{ item.vhost }}"
        state: present
      loop: "{{ rabbitmq_bindings }}"
```

## Execução

```bash
ansible-playbook -i inventory.yml manage-queues.yml
```

## Validação

```bash
# Listar exchanges por vhost
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_exchanges -p /prod

# Listar filas por vhost
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_queues -p /prod

# Ver bindings de uma exchange
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqctl list_bindings -p /prod

# Via rabbitmqadmin
kubectl exec -n rabbitmq deploy/rabbitmq -- \
  rabbitmqadmin -u admin -p $PASSWORD -V /prod list queues
```

## Exclusão

Para remover recursos, mude o `state` para `absent` no playbook.
Recursos com dependências (bindings) devem ser removidos antes das exchanges/queues.

## Referências

- `.agents/platform/agent-rabbitmq/rabbitmq-agent/rabbitmq-agent.md`
- `.skills/rabbitmq/configure-rabbitmq.md`
- `.templates/ansible-role/rabbitmq-config/`
