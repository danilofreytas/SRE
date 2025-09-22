# ⚙️ Especificações Técnicas - Ambiente de Observabilidade

## 🎯 Visão Geral Técnica

Este documento especifica tecnicamente todos os componentes, configurações e parâmetros do ambiente de observabilidade segmentado.

## 🏗️ Especificações de Infraestrutura

### Docker Engine
```yaml
Version: 24.0+
Runtime: containerd
Storage Driver: overlay2
Network: bridge
```

### Kubernetes (Kind)
```yaml
Cluster Name: observability
Kubernetes Version: v1.28+
Node Type: control-plane
Container Runtime: containerd
CNI: kindnet
```

### Recursos do Sistema
```yaml
CPU: 2-3 cores
Memory: 4-6 GB RAM
Disk: 15-20 GB
Network: 3 port-forwards ativos
```

## 📊 Especificações do SigNoz

### SigNoz UI
```yaml
Namespace: platform
Service: signoz
Port: 8080
Protocol: HTTP
Image: signoz/signoz:latest
Resources:
  CPU: 500m
  Memory: 1Gi
```

### ClickHouse Database
```yaml
Namespace: platform
Service: signoz-clickhouse
Ports:
  - 8123 (HTTP)
  - 9000 (TCP)
Image: clickhouse/clickhouse-server:latest
Storage: 10Gi
Resources:
  CPU: 1
  Memory: 2Gi
```

### ZooKeeper
```yaml
Namespace: platform
Service: signoz-zookeeper
Port: 2181
Protocol: TCP
Image: zookeeper:3.8
Resources:
  CPU: 200m
  Memory: 512Mi
```

### SigNoz OTel Collector
```yaml
Namespace: platform
Service: signoz-otel-collector
Ports:
  - 4317 (gRPC)
  - 4318 (HTTP)
Image: signoz/otel-collector:latest
Resources:
  CPU: 500m
  Memory: 1Gi
```

## 📡 Especificações do OpenTelemetry

### OpenTelemetry Operator
```yaml
Namespace: opentelemetry-operator-system
Image: ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator:0.134.1
Resources:
  CPU: 200m
  Memory: 256Mi
```

### DaemonSet Collector
```yaml
Namespace: platform
Name: signoz-collector-daemonset
Image: docker.io/otel/opentelemetry-collector-contrib:0.109.0
Mode: daemonset
Resources:
  CPU: 500m
  Memory: 1Gi
Volumes:
  - /var/log (hostPath)
  - /hostfs (hostPath)
```

### Deployment Collector
```yaml
Namespace: platform
Name: signoz-collector-deployment
Image: docker.io/otel/opentelemetry-collector-contrib:0.109.0
Mode: deployment
Replicas: 1
Resources:
  CPU: 500m
  Memory: 1Gi
```

## 🚀 Especificações do ArgoCD

### ArgoCD Server
```yaml
Namespace: argocd
Service: argocd-server
Ports:
  - 80 (HTTP)
  - 443 (HTTPS)
Image: quay.io/argoproj/argocd:v2.8.4
Resources:
  CPU: 500m
  Memory: 1Gi
```

### Application Controller
```yaml
Namespace: argocd
Image: quay.io/argoproj/argocd:v2.8.4
Resources:
  CPU: 500m
  Memory: 1Gi
```

### Repo Server
```yaml
Namespace: argocd
Image: quay.io/argoproj/argocd:v2.8.4
Resources:
  CPU: 500m
  Memory: 1Gi
```

## 🔐 Especificações de RBAC

### ClusterRole - DaemonSet
```yaml
Name: signoz-collector-daemonset-collector-role
Rules:
  - apiGroups: [""]
    resources: [pods, namespaces, nodes, persistentvolumeclaims]
    verbs: [get, list, watch]
  - apiGroups: ["apps"]
    resources: [replicasets]
    verbs: [get, list, watch]
  - apiGroups: [""]
    resources: [nodes/proxy]
    verbs: [get]
  - apiGroups: [""]
    resources: [nodes/stats, configmaps, events]
    verbs: [create, get]
```

### ClusterRole - Deployment
```yaml
Name: signoz-collector-deployment-collector-role
Rules:
  - apiGroups: [""]
    resources: [events, namespaces, namespaces/status, nodes, nodes/spec, pods, pods/status, replicationcontrollers, replicationcontrollers/status, resourcequotas, services]
    verbs: [get, list, watch]
  - apiGroups: ["apps"]
    resources: [daemonsets, deployments, replicasets, statefulsets]
    verbs: [get, list, watch]
  - apiGroups: ["batch"]
    resources: [jobs, cronjobs]
    verbs: [get, list, watch]
  - apiGroups: ["autoscaling"]
    resources: [horizontalpodautoscalers]
    verbs: [get, list, watch]
```

## 🌐 Especificações de Rede

### Port-Forwards
```yaml
SigNoz:
  Local: 3301
  Remote: 8080
  Protocol: HTTP
  Service: signoz.platform.svc.cluster.local

ArgoCD:
  Local: 8080
  Remote: 443
  Protocol: HTTPS
  Service: argocd-server.argocd.svc.cluster.local

HotROD:
  Local: 8081
  Remote: 8080
  Protocol: HTTP
  Service: hotrod.hotrod.svc.cluster.local
```

### Serviços Internos
```yaml
OTLP Endpoints:
  gRPC: signoz-otel-collector.platform.svc.cluster.local:4317
  HTTP: signoz-otel-collector.platform.svc.cluster.local:4318

ClickHouse:
  HTTP: signoz-clickhouse.platform.svc.cluster.local:8123
  TCP: signoz-clickhouse.platform.svc.cluster.local:9000

ZooKeeper:
  TCP: signoz-zookeeper.platform.svc.cluster.local:2181
```

## 📈 Especificações de Monitoramento

### Receivers Configurados
```yaml
OTLP:
  gRPC: 0.0.0.0:4317
  HTTP: 0.0.0.0:4318

filelog/k8s:
  Include: /var/log/pods/*/*/*.log
  Exclude:
    - /var/log/pods/default_my-release*-signoz-*/*/*.log
    - /var/log/pods/kube-system_*/*/*.log
    - /var/log/pods/*_hotrod*_*/*/*.log

hostmetrics:
  Collection Interval: 30s
  Root Path: /hostfs
  Scrapers:
    - cpu
    - disk
    - filesystem
    - load
    - memory
    - network

kubeletstats:
  Collection Interval: 30s
  Endpoint: ${env:K8S_HOST_IP}:10250
  Metric Groups:
    - container
    - pod
    - node
    - volume

k8s_cluster:
  Collection Interval: 30s
  Allocatable Types:
    - cpu
    - memory

k8s_events:
  Auth Type: serviceAccount
```

### Processors Configurados
```yaml
batch:
  Send Batch Size: 10000
  Timeout: 200ms (DaemonSet) / 1s (Deployment)

k8sattributes:
  Extract:
    Metadata:
      - k8s.namespace.name
      - k8s.deployment.name
      - k8s.pod.name
      - k8s.pod.uid
      - k8s.node.name
  Pod Association:
    - k8s.pod.ip
    - k8s.pod.uid
    - connection

resourcedetection:
  Detectors:
    - k8snode
    - env
    - system
  Timeout: 2s
```

### Exporters Configurados
```yaml
otlp:
  Endpoint: signoz-otel-collector.platform.svc.cluster.local:4317
  TLS:
    Insecure: true

debug:
  Verbosity: normal
```

## 🔧 Especificações dos Scripts

### install-all.sh
```bash
#!/usr/bin/env bash
# Instala todos os componentes em sequência
# Dependências: Docker, Internet
# Tempo estimado: 10-15 minutos
```

### start.sh
```bash
#!/usr/bin/env bash
# Inicia ambiente verificando dependências
# Verificações: Docker, Kind, kubectl
# Tempo estimado: 2-3 minutos
```

### stop.sh
```bash
#!/usr/bin/env bash
# Para ambiente completamente
# Opções: Parar Kind, Parar Docker
# Tempo estimado: 1-2 minutos
```

### status.sh
```bash
#!/usr/bin/env bash
# Verifica status de todos os componentes
# Output: Status detalhado com cores
# Tempo estimado: 30 segundos
```

## 📊 Especificações de Métricas

### Métricas Coletadas
```yaml
Host Metrics:
  - cpu.usage
  - disk.io
  - filesystem.usage
  - memory.usage
  - network.io

Kubernetes Metrics:
  - container.cpu.usage
  - container.memory.usage
  - k8s.pod.cpu.usage
  - k8s.pod.memory.usage
  - k8s.node.cpu.usage
  - k8s.node.memory.usage

Cluster Metrics:
  - k8s.node.condition
  - k8s.pod.status_reason
  - k8s.container.status.last_terminated_reason
```

### Logs Coletados
```yaml
Container Logs:
  - All pods (except system pods)
  - Format: JSON
  - Path: /var/log/pods/*/*/*.log

Kubernetes Events:
  - All events
  - Format: JSON
  - Source: k8s_events receiver
```

## 🎯 Especificações de Acesso

### URLs de Acesso
```yaml
SigNoz UI:
  URL: http://localhost:3301
  Protocol: HTTP
  Authentication: None

ArgoCD UI:
  URL: https://localhost:8080
  Protocol: HTTPS
  Authentication: admin / <password>

HotROD App:
  URL: http://localhost:8081
  Protocol: HTTP
  Authentication: None
```

### Credenciais
```yaml
ArgoCD Admin:
  Username: admin
  Password: <obtained via kubectl command>
  Command: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🔍 Especificações de Troubleshooting

### Comandos de Diagnóstico
```bash
# Verificar pods
kubectl get pods --all-namespaces

# Verificar serviços
kubectl get svc --all-namespaces

# Verificar collectors
kubectl get opentelemetrycollector --all-namespaces

# Verificar logs
kubectl logs -n platform -l app.kubernetes.io/name=signoz
kubectl logs -n platform -l app.kubernetes.io/name=opentelemetry-collector

# Verificar conectividade
curl -I http://localhost:3301
curl -k -I https://localhost:8080
curl -I http://localhost:8081
```

### Logs Importantes
```yaml
SigNoz:
  Namespace: platform
  Label: app.kubernetes.io/name=signoz

OpenTelemetry Operator:
  Namespace: opentelemetry-operator-system
  Label: app.kubernetes.io/name=opentelemetry-operator

OpenTelemetry Collectors:
  Namespace: platform
  Label: app.kubernetes.io/name=opentelemetry-collector

ArgoCD:
  Namespace: argocd
  Label: app.kubernetes.io/name=argocd-server
```

## 📋 Especificações de Verificação

### Checklist Técnico
```yaml
Infraestrutura:
  - [x] Docker rodando
  - [x] Kind cluster criado
  - [x] kubectl configurado

Componentes:
  - [x] SigNoz instalado
  - [x] OpenTelemetry Operator instalado
  - [x] ArgoCD instalado
  - [x] cert-manager instalado

Configurações:
  - [x] RBAC configurado
  - [x] Port-forwards ativos
  - [x] Collectors funcionando
  - [x] Métricas sendo coletadas

Acessos:
  - [x] SigNoz UI acessível
  - [x] ArgoCD UI acessível
  - [x] HotROD App acessível
```

### Métricas de Sucesso
```yaml
Pods: 31/33 rodando (94%)
Namespaces: 6 ativos
Services: 19 serviços
Collectors: 2 OpenTelemetry Collectors
Port-forwards: 3 ativos
```

---

**Especificações criadas em**: 22 de Setembro de 2025  
**Versão**: 1.0  
**Status**: ✅ Especificado e Documentado
