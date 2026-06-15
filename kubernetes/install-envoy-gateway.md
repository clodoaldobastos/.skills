# Install Envoy Gateway

## Overview

Envoy Gateway é um implementação do Gateway API que usa Envoy Proxy como data plane. Substitui o Ingress tradicional com uma abordagem baseada em CRDs (GatewayClass, Gateway, HTTPRoute).

## Prerequisites

- Kubernetes cluster (Kind, AKS, etc.)
- Helm 3.x instalado
- kubectl configurado

## Instalação

### 1. Instalar Envoy Gateway via Helm

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.6.0 \
  --namespace envoy-gateway-system \
  --create-namespace
```

### 2. Verificar a instalação

```bash
kubectl -n envoy-gateway-system get pods
# NAME                             READY   STATUS
# envoy-gateway-xxx                1/1     Running
# envoy-default-eg-yyy             2/2     Running
```

### 3. Liberar CRDs (se necessário)

Em clusters Kind com CRDs grandes (annotation > 256KB), o `kubectl apply` falha. Use `kubectl create`:

```bash
curl -sL https://github.com/envoyproxy/gateway/releases/download/v1.6.0/install.yaml \
  > /tmp/eg-install.yaml

# Extrair CRDs e criar separadamente
python3 -c "
with open('/tmp/eg-install.yaml') as f:
    docs = f.read().split('---')
crds = [d for d in docs if 'kind: CustomResourceDefinition' in d]
with open('/tmp/eg-crds.yaml', 'w') as f:
    f.write('\n---\n'.join(crds))
"
kubectl create -f /tmp/eg-crds.yaml
```

## Configuração

### 1. GatewayClass + Gateway

```yaml
# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
  namespace: default
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
```

```bash
kubectl apply -f gateway.yaml
```

### 2. HTTPRoute para uma aplicação

```yaml
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: minha-app
  namespace: default
spec:
  parentRefs:
    - name: eg
  rules:
    - backendRefs:
        - name: minha-app
          port: 8080
```

```bash
kubectl apply -f httproute.yaml
```

### 3. Verificar o roteamento

```bash
kubectl get gatewayclass,gateway,httproutes -A
# NAME                                        ACCEPTED
# gatewayclass/eg                              True

# NAMESPACE   NAME                             PROGRAMMED
# default     gateway/eg                       False (sem IP externo em Kind)

# NAMESPACE   NAME                             HOSTNAMES
# default     httproute/minha-app
```

O Gateway fica `PROGRAMMED=False` em Kind por não ter LoadBalancer, mas o listener fica ativo (verifique com `kubectl get gateway -o yaml`).

## Acesso

### Em Kind (sem metallb)

O serviço do Envoy proxy é do tipo LoadBalancer, que em Kind gera um NodePort automaticamente:

```bash
# Descobrir a porta
kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-namespace=default

# NAME                        TYPE           PORT(S)
# envoy-default-eg-xxx        LoadBalancer   80:3XXXX/TCP
```

### Proxy socat para acesso do host

```bash
WORKER_IP=$(docker inspect dev-cluster-worker2 \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
ENVOY_PORT=$(kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-namespace=default \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}')

docker run -d --name envoy-proxy --network kind -p 8080:8080 \
  alpine/socat TCP-LISTEN:8080,fork TCP-CONNECT:${WORKER_IP}:${ENVOY_PORT}
```

```bash
curl http://localhost:8080
# Hello World from pod minha-app-xxx!
```

## mTLS (Mutual TLS)

### 1. Gerar certificados

```bash
mkdir -p .memory/certs && cd .memory/certs

# CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -out ca.crt -subj "/CN=mtls-ca"

# Server (para o Envoy apresentar ao cliente)
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=envoy-gateway"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256

# Client (para o cliente apresentar ao Envoy)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=client"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 365 -sha256
```

### 2. Criar secrets

```bash
kubectl create secret tls server-cert \
  --cert=server.crt --key=server.key -n default

kubectl create secret generic client-ca \
  --from-file=ca.crt=ca.crt -n default
```

### 3. Gateway HTTPS

```yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: eg
spec:
  gatewayClassName: eg
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: server-cert
```

### 4. ClientTrafficPolicy (mTLS)

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: ClientTrafficPolicy
metadata:
  name: mtls-policy
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: eg
  tls:
    clientValidation:
      caCertificateRefs:
        - name: client-ca
          group: ""
          kind: Secret
      optional: false    # false = exige certificado do cliente
```

### 5. Proxy com TLS

```bash
WORKER_IP=$(docker inspect dev-cluster-worker2 \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
ENVOY_PORT=$(kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-namespace=default \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}')

docker run -d --name envoy-proxy --network kind -p 8080:8080 \
  -v $(pwd)/.memory/certs:/certs:ro alpine/socat \
  TCP-LISTEN:8080,fork \
  OPENSSL-CONNECT:${WORKER_IP}:${ENVOY_PORT},cert=/certs/client.crt,key=/certs/client.key,verify=0
```

### 6. Testar

```bash
# Sem client cert (deve falhar - mTLS rejeita)
curl -sk https://${WORKER_IP}:${ENVOY_PORT}
# (resposta vazia)

# Com client cert (deve funcionar)
curl -sk --cert .memory/certs/client.crt --key .memory/certs/client.key \
  https://${WORKER_IP}:${ENVOY_PORT}
# Hello World from pod xxx!

# Via proxy
curl http://localhost:8080
# Hello World from pod xxx!
```

## Regras

- **Envoy Gateway é o único entry point** — nenhum serviço de aplicação expõe NodePort ou LoadBalancer
- Todos os serviços de aplicação devem ser `ClusterIP`
- Novas aplicações são expostas via HTTPRoute + Gateway
- Fluxo: `cliente → Envoy Gateway → HTTPRoute → service ClusterIP → pod`
- Exceção: o próprio Envoy Gateway pode usar LoadBalancer (vira NodePort em Kind)
- mTLS é configurado via `ClientTrafficPolicy` com `tls.clientValidation.caCertificateRefs`
- Certificados ficam em `.memory/certs/` (não versionar no projeto)

## Troubleshooting

**CRD annotation too large (> 256KB)**:
```bash
kubectl delete validatingadmissionpolicy safe-upgrades.gateway.networking.k8s.io
kubectl create -f /tmp/eg-crds.yaml  # em vez de apply
```

**Envoy pod crash com "no matches for kind"**:
Instale a versão experimental dos CRDs do Gateway API ou use uma versão compatível do Envoy Gateway.

**Gateway não fica PROGRAMMED**:
Normal em Kind sem metallb. Verifique se o listener tem `attachedRoutes > 0`.
