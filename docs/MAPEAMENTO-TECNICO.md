# 🗺️ Mapeamento Técnico - Ambiente de Observabilidade

## 📋 Resumo Executivo

Este documento mapeia tecnicamente todas as configurações, componentes e interconexões do ambiente de observabilidade segmentado.

## 🏗️ Arquitetura Técnica

### Stack Tecnológico
- **Container Runtime**: Docker
- **Orquestração**: Kubernetes (Kind)
- **Observabilidade**: SigNoz + OpenTelemetry
- **GitOps**: ArgoCD
- **Certificados**: cert-manager
- **Métricas**: kube-state-metrics + node-exporter

### Fluxo de Dados
```
Aplicações → OpenTelemetry Collectors → SigNoz → ClickHouse → UI
```

## 📊 Componentes Mapeados

### 1. Kubernetes Cluster
- **Nome**: observability
- **Tipo**: Kind (Kubernetes in Docker)
- **Nodes**: 1 control-plane
- **Versão**: Latest stable
- **Context**: kind-observability

### 2. SigNoz Platform
- **Namespace**: platform
- **Componentes**:
  - SigNoz UI (port 8080)
  - ClickHouse DB (ports 8123, 9000)
  - ZooKeeper (port 2181)
  - OTel Collector (ports 4317, 4318)

### 3. OpenTelemetry
- **Operator**: opentelemetry-operator-system
- **Collectors**: platform
  - DaemonSet: logs + host metrics
  - Deployment: cluster metrics

### 4. ArgoCD
- **Namespace**: argocd
- **Componentes**:
  - Server (port 443)
  - Application Controller
  - Repo Server
  - ApplicationSet Controller

## 🔗 Interconexões

### Port-Forwards
| Local | Remote | Service | Namespace |
|-------|--------|---------|-----------|
| 3301 | 8080 | signoz | platform |
| 8080 | 443 | argocd-server | argocd |
| 8081 | 8080 | hotrod | hotrod |

### Serviços Internos
| From | To | Port | Protocol |
|------|----|----- |----------|
| DaemonSet | signoz-otel-collector | 4317 | gRPC |
| Deployment | signoz-otel-collector | 4317 | gRPC |
| HotROD | signoz-otel-collector | 4318 | HTTP |
| SigNoz | signoz-clickhouse | 8123 | HTTP |
| ClickHouse | signoz-zookeeper | 2181 | TCP |

## 📁 Estrutura de Arquivos

### Scripts de Instalação
- `k8s-local/install.sh` - Instala Kind + kubectl
- `signoz/install.sh` - Instala SigNoz + métricas
- `opentelemetry/install.sh` - Instala OTel Operator
- `argocd/install.sh` - Instala ArgoCD
- `gerenciamento/install-all.sh` - Instala tudo

### Configurações YAML
- `opentelemetry/rbac-daemonset.yaml` - RBAC DaemonSet
- `opentelemetry/rbac-deployment.yaml` - RBAC Deployment
- `opentelemetry/collector-daemonset.yaml` - Config DaemonSet
- `opentelemetry/collector-deployment.yaml` - Config Deployment

### Scripts de Gerenciamento
- `gerenciamento/start.sh` - Inicia ambiente
- `gerenciamento/stop.sh` - Para ambiente
- `gerenciamento/status.sh` - Verifica status

## 🔐 Configurações de Segurança

### RBAC Mapeado
- **signoz-collector-daemonset-collector-role**: Permissões para DaemonSet
- **signoz-collector-deployment-collector-role**: Permissões para Deployment
- **ServiceAccounts**: signoz-collector-*-collector (platform)

### Namespaces e Isolamento
- Cada componente em namespace separado
- RBAC específico por componente
- Network policies implícitas

## 📈 Métricas e Monitoramento

### Coleta de Dados
- **Logs**: filelog/k8s receiver
- **Métricas Host**: hostmetrics receiver
- **Métricas K8s**: kubeletstats receiver
- **Métricas Cluster**: k8s_cluster receiver
- **Eventos**: k8s_events receiver

### Processamento
- **Batch**: Agrupamento de dados
- **k8sattributes**: Enriquecimento de metadados
- **resourcedetection**: Detecção de recursos

### Armazenamento
- **ClickHouse**: Dados de telemetria
- **ZooKeeper**: Coordenação do ClickHouse

## 🚀 Deployment e GitOps

### ArgoCD ApplicationSet
- Gerencia múltiplas aplicações
- Sincronização automática
- Rollback automático

### Helm Charts
- SigNoz: signoz/signoz
- ArgoCD: argo/argo-cd
- OpenTelemetry: open-telemetry/opentelemetry-operator
- Métricas: prometheus-community/*

## 🔧 Comandos de Operação

### Verificação de Status
```bash
./status.sh                    # Status completo
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
kubectl get opentelemetrycollector --all-namespaces
```

### Gerenciamento
```bash
./start.sh                     # Iniciar ambiente
./stop.sh                      # Parar ambiente
./install-all.sh               # Instalação completa
```

### Acesso aos Serviços
```bash
# SigNoz
kubectl port-forward -n platform svc/signoz 3301:8080

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# HotROD
kubectl port-forward svc/hotrod -n hotrod 8081:8080
```

## 📊 Estatísticas do Ambiente

### Recursos
- **Pods**: 31/33 rodando
- **Namespaces**: 6 ativos
- **Services**: 19 serviços
- **Collectors**: 2 OpenTelemetry Collectors

### Uso de Recursos
- **CPU**: ~2-3 cores
- **Memória**: ~4-6 GB
- **Disco**: ~15-20 GB
- **Rede**: 3 port-forwards ativos

## 🎯 Pontos de Acesso

### URLs de Acesso
- **SigNoz UI**: http://localhost:3301
- **ArgoCD UI**: https://localhost:8080
- **HotROD App**: http://localhost:8081

### Credenciais
- **ArgoCD Admin**: Senha via `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 🔍 Troubleshooting Mapeado

### Problemas Comuns
1. **Docker não rodando** → `sudo systemctl start docker`
2. **Cluster Kind não encontrado** → `kind create cluster --name observability`
3. **Port-forward não funciona** → `pkill -f "kubectl port-forward"`
4. **Pods não ficam prontos** → `kubectl describe pod <pod-name>`
5. **RBAC issues** → Verificar ClusterRoleBindings
6. **SigNoz não acessível** → Verificar port-forward e logs

### Comandos de Diagnóstico
```bash
# Logs importantes
kubectl logs -n platform -l app.kubernetes.io/name=signoz
kubectl logs -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator
kubectl logs -n platform -l app.kubernetes.io/name=opentelemetry-collector

# Verificar conectividade
curl -I http://localhost:3301
curl -k -I https://localhost:8080
curl -I http://localhost:8081
```

## 📋 Checklist de Verificação

### ✅ Componentes Instalados
- [x] Kubernetes (Kind)
- [x] SigNoz
- [x] OpenTelemetry Operator
- [x] OpenTelemetry Collectors (DaemonSet + Deployment)
- [x] ArgoCD
- [x] cert-manager
- [x] kube-state-metrics
- [x] node-exporter
- [x] HotROD

### ✅ Configurações Aplicadas
- [x] RBAC para DaemonSet
- [x] RBAC para Deployment
- [x] Port-forwards configurados
- [x] ApplicationSet do ArgoCD
- [x] Coleta de logs configurada
- [x] Coleta de métricas configurada
- [x] Coleta de traces configurada

### ✅ Acessos Funcionando
- [x] SigNoz UI acessível
- [x] ArgoCD UI acessível
- [x] HotROD App acessível
- [x] Logs sendo coletados
- [x] Métricas sendo coletadas
- [x] Traces sendo coletados

---

**Mapeamento criado em**: 22 de Setembro de 2025  
**Versão**: 1.0  
**Status**: ✅ Completo e Mapeado
