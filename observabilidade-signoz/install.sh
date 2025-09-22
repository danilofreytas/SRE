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

log "🚀 Iniciando instalação do SigNoz..."

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
# INSTALAÇÃO DO SIGNOZ
# =============================================================================

log "📦 Instalando SigNoz..."

# Adicionar repositório Helm do SigNoz
log "📋 Adicionando repositório Helm do SigNoz..."
helm repo add signoz https://charts.signoz.io || error "Falha ao adicionar repositório SigNoz"
helm repo update || error "Falha ao atualizar repositórios Helm"

# Criar namespace platform
log "🏗️ Criando namespace platform..."
kubectl create namespace platform || warning "Namespace platform já existe"

# Instalar SigNoz
log "🚀 Instalando SigNoz..."
helm install signoz signoz/signoz -n platform || error "Falha ao instalar SigNoz"

# =============================================================================
# INSTALAÇÃO DE MÉTRICAS
# =============================================================================

log "📊 Instalando componentes de métricas..."

# Instalar metrics-server
log "📈 Instalando metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml || error "Falha ao instalar metrics-server"

# Adicionar repositório Prometheus
log "📋 Adicionando repositório Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || error "Falha ao adicionar repositório Prometheus"
helm repo update || error "Falha ao atualizar repositórios Helm"

# Criar namespace monitoring
log "🏗️ Criando namespace monitoring..."
kubectl create namespace monitoring || warning "Namespace monitoring já existe"

# Instalar kube-state-metrics
log "📊 Instalando kube-state-metrics..."
helm install kube-state-metrics prometheus-community/kube-state-metrics -n monitoring || error "Falha ao instalar kube-state-metrics"

# Instalar node-exporter
log "🖥️ Instalando node-exporter..."
helm install node-exporter prometheus-community/prometheus-node-exporter -n monitoring || error "Falha ao instalar node-exporter"

# =============================================================================
# APLICAÇÃO DE EXEMPLO (HOTROD)
# =============================================================================

log "🎯 Criando aplicação HotROD de exemplo..."

# Criar namespace hotrod
log "🏗️ Criando namespace hotrod..."
kubectl create namespace hotrod || warning "Namespace hotrod já existe"

# Deployar aplicação HotROD
log "🚀 Deployando aplicação HotROD..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: hotrod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hotrod
  namespace: hotrod
  labels:
    app: hotrod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hotrod
  template:
    metadata:
      labels:
        app: hotrod
    spec:
      containers:
        - name: hotrod
          image: jaegertracing/example-hotrod:latest
          args: ["all"]
          env:
            - name: OTEL_EXPORTER_OTLP_ENDPOINT
              value: "http://signoz-otel-collector.platform.svc.cluster.local:4318"
            - name: OTEL_SERVICE_NAME
              value: "hotrod"
          ports:
            - name: frontend
              containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hotrod
  namespace: hotrod
spec:
  selector:
    app: hotrod
  ports:
    - protocol: TCP
      port: 8080
      targetPort: frontend
  type: ClusterIP
EOF

if [ $? -eq 0 ]; then
    log "✅ Aplicação HotROD deployada com sucesso!"
else
    error "Falha ao deployar aplicação HotROD"
fi

# =============================================================================
# AGUARDAR PODS FICAREM PRONTOS
# =============================================================================

log "⏳ Aguardando pods ficarem prontos..."

# Aguardar pods do SigNoz
log "⏳ Aguardando pods do SigNoz..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=signoz -n platform --timeout=300s || warning "Timeout aguardando pods do SigNoz"

# Aguardar pods do HotROD
log "⏳ Aguardando pods do HotROD..."
kubectl wait --for=condition=ready pod -l app=hotrod -n hotrod --timeout=120s || warning "Timeout aguardando pods do HotROD"

# Aguardar pods de métricas
log "⏳ Aguardando pods de métricas..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kube-state-metrics -n monitoring --timeout=120s || warning "Timeout aguardando pods do kube-state-metrics"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-node-exporter -n monitoring --timeout=120s || warning "Timeout aguardando pods do node-exporter"

# =============================================================================
# VERIFICAÇÃO FINAL
# =============================================================================

log "🔍 Verificando instalação..."

# Verificar status dos pods
log "📊 Status dos pods:"
kubectl get pods --all-namespaces

# Verificar serviços
log "🌐 Status dos serviços:"
kubectl get svc --all-namespaces

# =============================================================================
# INFORMAÇÕES DE ACESSO
# =============================================================================

log "🎉 Instalação do SigNoz concluída com sucesso!"
echo ""
info "📊 Serviços disponíveis:"
info "  - SigNoz UI: http://localhost:3301"
info "  - HotROD App: http://localhost:8080"
echo ""
info "🔧 Comandos para acessar os serviços:"
info "  - SigNoz: kubectl port-forward -n platform svc/signoz 3301:8080"
info "  - HotROD: kubectl port-forward svc/hotrod -n hotrod 8080:8080"
echo ""
info "📋 Comandos úteis:"
info "  - Ver pods: kubectl get pods --all-namespaces"
info "  - Ver serviços: kubectl get svc --all-namespaces"
info "  - Logs SigNoz: kubectl logs -n platform -l app.kubernetes.io/name=signoz"
info "  - Logs HotROD: kubectl logs -n hotrod -l app=hotrod"
echo ""
warning "💡 Dica: Execute os comandos port-forward em terminais separados para acessar os serviços"
echo ""
info "🎯 Próximos passos:"
info "  1. Acesse o SigNoz em http://localhost:3301"
info "  2. Configure alertas no SigNoz"
info "  3. Explore métricas, logs e traces"
info "  4. Configure dashboards personalizados"
