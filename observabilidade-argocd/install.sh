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

log "🚀 Iniciando instalação do ArgoCD..."

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
# INSTALAÇÃO DO ARGOCD
# =============================================================================

log "📦 Instalando ArgoCD..."

# Adicionar repositório ArgoCD
log "📋 Adicionando repositório ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm || error "Falha ao adicionar repositório ArgoCD"
helm repo update || error "Falha ao atualizar repositórios Helm"

# Criar namespace argocd
log "🏗️ Criando namespace argocd..."
kubectl create namespace argocd || warning "Namespace argocd já existe"

# Instalar ArgoCD
log "🚀 Instalando ArgoCD..."
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set server.ingress.enabled=false \
  --set configs.params."server\.insecure"=true \
  --set configs.params."server\.rootpath"=/ \
  --set server.extraArgs[0]="--insecure" \
  --set server.extraArgs[1]="--rootpath" \
  --set server.extraArgs[2]="/" || error "Falha ao instalar ArgoCD"

# Aguardar pods do ArgoCD ficarem prontos
log "⏳ Aguardando pods do ArgoCD ficarem prontos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || warning "Timeout aguardando pods do ArgoCD Server"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-repo-server -n argocd --timeout=300s || warning "Timeout aguardando pods do ArgoCD Repo Server"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=300s || warning "Timeout aguardando pods do ArgoCD Application Controller"

# =============================================================================
# CONFIGURAÇÃO DO ARGOCD
# =============================================================================

log "🔧 Configurando ArgoCD..."

# Obter senha inicial do admin
log "🔐 Obtendo senha inicial do admin..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
log "✅ Senha do admin: $ARGOCD_PASSWORD"

# Configurar port-forward para ArgoCD
log "🌐 Configurando port-forward para ArgoCD..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
ARGOCD_PID=$!

# Aguardar port-forward ficar ativo
sleep 5

# Pular instalação do ArgoCD CLI (requer sudo)
log "📦 Pulando instalação do ArgoCD CLI (requer sudo)..."
log "✅ ArgoCD CLI não será instalado automaticamente"

# =============================================================================
# CONFIGURAÇÃO DE APLICAÇÕES DE EXEMPLO
# =============================================================================

log "🎯 Configurando aplicações de exemplo..."

# Criar ApplicationSet para observabilidade
log "📝 Criando ApplicationSet para observabilidade..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: observability-apps
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - name: signoz
        namespace: platform
        repoURL: https://charts.signoz.io
        chart: signoz
        targetRevision: "0.0.50"
        values: |
          frontend:
            service:
              type: ClusterIP
          otelCollector:
            service:
              type: ClusterIP
      - name: prometheus
        namespace: monitoring
        repoURL: https://prometheus-community.github.io/helm-charts
        chart: kube-state-metrics
        targetRevision: "5.9.2"
      - name: node-exporter
        namespace: monitoring
        repoURL: https://prometheus-community.github.io/helm-charts
        chart: prometheus-node-exporter
        targetRevision: "4.32.1"
  template:
    metadata:
      name: '{{name}}'
      namespace: '{{namespace}}'
    spec:
      project: default
      source:
        repoURL: '{{repoURL}}'
        chart: '{{chart}}'
        targetRevision: '{{targetRevision}}'
        helm:
          valueFiles:
          - values.yaml
          values: |
            {{values}}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
EOF

# Aguardar ApplicationSet ser processado
log "⏳ Aguardando ApplicationSet ser processado..."
sleep 10

# =============================================================================
# VERIFICAÇÃO FINAL
# =============================================================================

log "🔍 Verificando instalação..."

# Verificar status dos pods
log "📊 Status dos pods do ArgoCD:"
kubectl get pods -n argocd

# Verificar ApplicationSet
log "📋 Status do ApplicationSet:"
kubectl get applicationset -n argocd

# Verificar Applications criadas
log "📋 Applications criadas:"
kubectl get applications -n argocd

# Verificar serviços
log "🌐 Status dos serviços:"
kubectl get svc -n argocd

log "🎉 Instalação do ArgoCD concluída com sucesso!"
echo ""
info "🌐 Para acessar o ArgoCD UI:"
info "  1. Execute o port-forward em um terminal separado:"
info "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
info "  2. Acesse em seu navegador: https://localhost:8080"
info "     (Aceite o aviso de certificado, pois é um certificado autoassinado)"
echo ""
info "🔑 Credenciais de acesso:"
info "  - Usuário: admin"
info "  - Senha: $ARGOCD_PASSWORD"
echo ""
info "🔧 Comandos úteis:"
info "  - Ver pods do ArgoCD: kubectl get pods -n argocd"
info "  - Ver ApplicationSet: kubectl get applicationset -n argocd"
info "  - Ver Applications: kubectl get applications -n argocd"
info "  - Ver serviços do ArgoCD: kubectl get svc -n argocd"
echo ""
warning "💡 Dica: Após o login, você pode alterar a senha do admin na UI do ArgoCD."
echo ""
info "🎯 Próximos passos:"
info "  1. Acesse o ArgoCD UI e explore as aplicações"
info "  2. Configure repositórios Git para GitOps"
info "  3. Crie ApplicationSets personalizados"
info "  4. Configure notificações e webhooks"
