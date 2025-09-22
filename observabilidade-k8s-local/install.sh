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

log "🚀 Iniciando instalação do Kubernetes Local (Kind)..."

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root"
fi

# 1. Instalar Kind
echo "[1/3] Verificando e instalando Kind..."
if ! command_exists kind; then
    log "📦 Instalando Kind..."
    # For AMD64 / x86_64
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    # For ARM64
    [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    log "✅ Kind instalado com sucesso!"
else
    log "✅ Kind já está instalado"
fi

# 2. Instalar kubectl
echo "[2/3] Verificando e instalando kubectl..."
if ! command_exists kubectl; then
    log "📦 Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    log "✅ kubectl instalado com sucesso!"
else
    log "✅ kubectl já está instalado"
fi

# 3. Verificar Docker
echo "[3/3] Verificando Docker..."
if ! command_exists docker; then
    error "Docker não está instalado. Por favor, instale o Docker e tente novamente."
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker não está rodando ou o usuário não tem permissão para acessá-lo. Inicie o Docker ou verifique suas permissões."
fi
log "✅ Docker está rodando"

# Criar cluster Kind
log "🏗️ Criando cluster Kind 'observability'..."
if ! kind get clusters | grep -q "observability"; then
    kind create cluster --name observability || error "Falha ao criar cluster Kind"
    log "✅ Cluster Kind 'observability' criado com sucesso!"
else
    warning "Cluster Kind 'observability' já existe. Pulando criação."
fi

# Aguardar cluster ficar pronto
log "⏳ Aguardando cluster ficar pronto..."
kubectl wait --for=condition=Ready node/observability-control-plane --timeout=300s || warning "Timeout aguardando cluster Kind"

log "📊 Status do cluster:"
kubectl get nodes
kubectl get pods --all-namespaces

log "🎉 Instalação do Kubernetes Local concluída com sucesso!"
echo ""
info "📝 Para usar o cluster:"
info "   kubectl get nodes"
info "   kubectl get pods --all-namespaces"
info "   kind get clusters"
echo ""
warning "💡 Dica: Se precisar remover o cluster, execute: kind delete cluster --name observability"
