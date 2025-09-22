#!/usr/bin/env bash
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERRO: $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] AVISO: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se cluster Kind existe
check_kind_cluster() {
    if ! command_exists kind; then
        error "Kind não está instalado. Execute primeiro: ../k8s-local/install.sh"
    fi
    
    if ! kind get clusters | grep -q "observability"; then
        error "Cluster 'observability' não encontrado. Execute primeiro: ../k8s-local/install.sh"
    fi
    
    # Verificar se kubectl está configurado para o cluster correto
    if ! kubectl config current-context | grep -q "kind-observability"; then
        warning "Configurando kubectl para usar o cluster observability..."
        kubectl config use-context kind-observability || error "Falha ao configurar contexto do kubectl"
    fi
}

# Função para verificar se Helm está instalado
check_helm() {
    if ! command_exists helm; then
        log "📦 Instalando Helm..."
        
        # Instalar Helm
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        
        log "✅ Helm instalado com sucesso!"
    else
        log "✅ Helm já está instalado"
    fi
}

# =============================================================================
# INÍCIO DA INSTALAÇÃO
# =============================================================================

log "🚀 Iniciando instalação do OpenTelemetry Operator..."

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root"
fi

# Verificar dependências
log "🔍 Verificando dependências..."
check_kind_cluster
check_helm

log "✅ Dependências verificadas com sucesso"

# =============================================================================
# INSTALAÇÃO DO CERT-MANAGER (Pré-requisito para OpenTelemetry Operator)
# =============================================================================

log "🔐 Instalando cert-manager..."

# Adicionar repositório Helm do cert-manager
log "📋 Adicionando repositório cert-manager..."
helm repo add jetstack https://charts.jetstack.io || error "Falha ao adicionar repositório cert-manager"
helm repo update || error "Falha ao atualizar repositórios Helm"

# Criar namespace cert-manager
log "🏗️ Criando namespace cert-manager..."
kubectl create namespace cert-manager || warning "Namespace cert-manager já existe"

# Instalar cert-manager
log "🚀 Instalando cert-manager..."
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.0 \
  --set installCRDs=true || error "Falha ao instalar cert-manager"

# Aguardar cert-manager ficar pronto
log "⏳ Aguardando cert-manager ficar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s || warning "Timeout aguardando pods do cert-manager"

# =============================================================================
# INSTALAÇÃO DO OPENTELEMETRY OPERATOR
# =============================================================================

log "📡 Instalando OpenTelemetry Operator..."

# Adicionar repositório Helm do OpenTelemetry
log "📋 Adicionando repositório OpenTelemetry..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts || error "Falha ao adicionar repositório OpenTelemetry"
helm repo update || error "Falha ao atualizar repositórios Helm"

# Criar namespace opentelemetry-operator-system
log "🏗️ Criando namespace opentelemetry-operator-system..."
kubectl create namespace opentelemetry-operator-system || warning "Namespace opentelemetry-operator-system já existe"

# Instalar OpenTelemetry Operator
log "🚀 Instalando OpenTelemetry Operator..."
helm install opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system || error "Falha ao instalar OpenTelemetry Operator"

# Aguardar OpenTelemetry Operator ficar pronto
log "⏳ Aguardando OpenTelemetry Operator ficar pronto..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-operator -n opentelemetry-operator-system --timeout=300s || warning "Timeout aguardando pods do OpenTelemetry Operator"

# =============================================================================
# CONFIGURAÇÃO DO OPENTELEMETRY COLLECTOR
# =============================================================================

log "🔧 Configurando OpenTelemetry Collector (DaemonSet)..."

# Criar namespace platform (se não existir, para os collectors)
log "🏗️ Criando namespace platform..."
kubectl create namespace platform || warning "Namespace platform já existe"

# Aplicar configuração do DaemonSet
log "📝 Aplicando configuração do DaemonSet..."
cat <<EOF | kubectl apply -f -
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector-daemonset
  namespace: platform
spec:
  mode: daemonset
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus:
        config:
          scrape_configs:
            - job_name: 'kubernetes-pods'
              kubernetes_sd_configs:
                - role: pod
              relabel_configs:
                - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                  action: keep
                  regex: true
                - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                  action: replace
                  target_label: __metrics_path__
                  regex: (.+)
                - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
                  action: replace
                  regex: ([^:]+)(?::\d+)?;(\d+)
                  replacement: $1:$2
                  target_label: __address__
                - action: labelmap
                  regex: __meta_kubernetes_pod_label_(.+)
                - source_labels: [__meta_kubernetes_namespace]
                  action: replace
                  target_label: kubernetes_namespace
                - source_labels: [__meta_kubernetes_pod_name]
                  action: replace
                  target_label: kubernetes_pod_name
            - job_name: 'kube-state-metrics'
              static_configs:
                - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']
            - job_name: 'node-exporter'
              static_configs:
                - targets: ['node-exporter-prometheus-node-exporter.monitoring.svc.cluster.local:9100']
            - job_name: 'kubernetes-nodes'
              kubernetes_sd_configs:
                - role: node
              relabel_configs:
                - action: labelmap
                  regex: __meta_kubernetes_node_label_(.+)
                - target_label: __address__
                  replacement: kubernetes.default.svc:443
                - source_labels: [__meta_kubernetes_node_name]
                  regex: (.+)
                  target_label: __metrics_path__
                  replacement: /api/v1/nodes/${1}/proxy/metrics
      filelog:
        include: [ /var/log/pods/*/*/*.log ]
        exclude: [ /var/log/pods/*/*/*.log.gz ]
        start_at: beginning

    processors:
      batch:
        send_batch_size: 10000
        send_batch_max_size: 10000
        timeout: 10s
      memory_limiter:
        check_interval: 1s
        limit_mib: 200
        spike_limit_mib: 50

    exporters:
      otlp:
        endpoint: signoz-otel-collector.platform.svc.cluster.local:4317
        tls:
          insecure: true
      logging:
        verbosity: detailed

    service:
      pipelines:
        metrics:
          receivers: [otlp, prometheus]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
        logs:
          receivers: [otlp, filelog]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
EOF

log "🔧 Configurando OpenTelemetry Collector (Deployment)..."

# Aplicar configuração do Deployment
log "📝 Aplicando configuração do Deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector-deployment
  namespace: platform
spec:
  mode: deployment
  config: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    processors:
      batch:
        send_batch_size: 10000
        send_batch_max_size: 10000
        timeout: 10s
      memory_limiter:
        check_interval: 1s
        limit_mib: 200
        spike_limit_mib: 50

    exporters:
      otlp:
        endpoint: signoz-otel-collector.platform.svc.cluster.local:4317
        tls:
          insecure: true
      logging:
        verbosity: detailed

    service:
      pipelines:
        metrics:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
        logs:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp, logging]
EOF

# Aguardar pods ficarem prontos
log "⏳ Aguardando pods ficarem prontos..."
log "⏳ Aguardando pods do cert-manager..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s || warning "Timeout aguardando pods do cert-manager"
log "⏳ Aguardando pods do OpenTelemetry Operator..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-operator -n opentelemetry-operator-system --timeout=300s || warning "Timeout aguardando pods do OpenTelemetry Operator"
log "⏳ Aguardando pods dos OpenTelemetry Collectors..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentelemetry-collector -n platform --timeout=300s || warning "Timeout aguardando pods dos collectors"

# =============================================================================
# VERIFICAÇÃO FINAL
# =============================================================================

log "🔍 Verificando instalação..."

# Verificar status dos pods
log "📊 Status dos pods:"
kubectl get pods --all-namespaces

# Verificar status dos OpenTelemetry Collectors
log "📡 Status dos OpenTelemetry Collectors:"
kubectl get opentelemetrycollector -n platform

# Verificar serviços
log "🌐 Status dos serviços:"
kubectl get svc --all-namespaces

log "🎉 Instalação do OpenTelemetry Operator concluída com sucesso!"
echo ""
info "📡 Componentes instalados:"
info "  - cert-manager: Gerenciamento de certificados"
info "  - OpenTelemetry Operator: Operador para gerenciar collectors"
info "  - OpenTelemetry Collector (DaemonSet): Coleta de logs e métricas"
info "  - OpenTelemetry Collector (Deployment): Coleta de traces"
echo ""
info "🔧 Comandos úteis:"
info "  - Ver pods: kubectl get pods --all-namespaces"
info "  - Ver collectors: kubectl get opentelemetrycollector -n platform"
info "  - Ver serviços: kubectl get svc --all-namespaces"
info "  - Logs cert-manager: kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager"
info "  - Logs operator: kubectl logs -n opentelemetry-operator-system -l app.kubernetes.io/name=opentelemetry-operator"
info "  - Logs collectors: kubectl logs -n platform -l app.kubernetes.io/name=opentelemetry-collector"
echo ""
info "🎯 Próximos passos:"
info "  1. Instalar SigNoz para receber telemetria"
info "  2. Configurar aplicações para enviar traces"
info "  3. Verificar coleta de logs e métricas"
info "  4. Configurar alertas e dashboards"
