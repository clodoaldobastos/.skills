---
name: pipeline-otel-validation
description: Skill de raciocínio para validar pipelines OpenTelemetry (metrics/logs/traces) em coletores OTel
tools:
  - bash
  - kubectl
  - grep
---

# Skill: Pipeline OTel Validation

Padrão de raciocínio para diagnosticar problemas em pipelines OpenTelemetry.

## 1. Identificar o pipeline

Para cada pipeline (metrics, logs, traces) no config do collector:

1. Quais receivers alimentam o pipeline?
2. Quais processors transformam os dados?
3. Quais exporters enviam os dados?

## 2. Verificar recebimento

No log do collector, busque:
```
# OTLP recebendo dados:
OTLP receiver is starting...
Everything is ready.

# Falha no recebimento:
Failed to start receiver
failed to resolve endpoint
```

Para métricas específicas do Prometheus exporter:
```
otel_otlp_receiver_*_received_total
```

## 3. Verificar processamento

Problemas comuns em processors:
- **batch**: verificar `timeout` e `send_batch_size`
- **memory_limiter**: verificar se não está dropping por limite
- **k8sattributes**: verificar RBAC (ClusterRole) para ler pods/nodes
- **resourcedetection**: verificar se metadados foram detectados

## 4. Verificar exportação

Para cada exporter:

| Exporter | Como validar | Erro comum |
|----------|-------------|------------|
| Prometheus | `GET /metrics` no endpoint | Porta ocupada |
| Loki | `POST /loki/api/v1/push` | 401/403, endpoint errado |
| OTLP (Tempo) | gRPC `:4317` | connection refused |
| Debug | `kubectl logs` | Verbosity baixo |

## 5. Diagnóstico diferencial

```
Problema: métricas não aparecem no Prometheus
├── Agent não envia?
│   └── Verificar OTLP exporter no Agent apontando para Central:4317
├── Central não recebe?
│   └── Verificar OTLP receiver no Central (porta 4317 aberta?)
├── Central não exporta?
│   └── Verificar Prometheus exporter no Central (porta 8889)
└── Prometheus não scrapper?
    └── Verificar service discovery (kubernetes_sd_configs)
```

```
Problema: logs não aparecem no Loki
├── Agent não coleta?
│   └── Verificar filelog receiver (caminho /var/log/pods/...)
├── Central não encaminha?
│   └── Verificar Loki exporter (endpoint, TLS, labels)
└── Loki não recebe?
    └── Verificar /ready e logs do Loki
```

```
Problema: traces não aparecem no Tempo
├── App não exporta?
│   └── Verificar variável OTEL_EXPORTER_OTLP_ENDPOINT
├── Agent não encaminha?
│   └── Verificar pipeline traces no Agent
├── Central não encaminha?
│   └── Verificar OTLP exporter apontando para Tempo:4317
└── Tempo não recebe?
    └── Verificar OTLP receiver no Tempo (grpc :4317)
```

## 6. Comandos de diagnóstico rápido

```bash
# Ver se Central recebe dados
kubectl logs -n otel-monitoring deployment/otel-central --tail=50 | grep -E "(received|exported|error|failed)"

# Ver se Agent consegue conectar no Central
kubectl logs -n otel-monitoring daemonset/otel-agent --tail=20 | grep "otlp"

# Ver targets no Prometheus
kubectl run curl-test --image curlimages/curl --rm -i --restart=Never -n otel-monitoring \
  -- -s http://prometheus:9090/api/v1/targets | python3 -m json.tool

# Ver métricas exportadas pelo Central
kubectl run curl-test --image curlimages/curl --rm -i --restart=Never -n otel-monitoring \
  -- -s http://otel-central:8889/metrics | head -50
```
