# 🚀 Guia de Instalação Completa - Stack de Observabilidade

## 📋 Visão Geral

Este guia fornece **instruções passo a passo** para instalação completa da stack de observabilidade, incluindo todas as ferramentas e configurações necessárias para um ambiente de produção.

### 🎯 Objetivo

Criar um ambiente completo de observabilidade com:
- **Kubernetes local** (Kind)
- **OpenTelemetry** para coleta de telemetria
- **SigNoz** para visualização e análise
- **ArgoCD** para GitOps
- **API de teste** para demonstração

---

## 📋 Pré-requisitos

### 💻 Requisitos de Sistema

| Componente | Versão Mínima | Recomendada |
|------------|---------------|-------------|
| **Sistema Operacional** | Linux/macOS | Ubuntu 20.04+ |
| **RAM** | 4GB | 8GB+ |
| **Espaço em Disco** | 10GB | 20GB+ |
| **CPU** | 2 cores | 4 cores+ |

### 🔧 Software Necessário

| Software | Versão | Instalação |
|----------|--------|------------|
| **Docker** | 20.10+ | [Docker Install](https://docs.docker.com/get-docker/) |
| **Git** | 2.30+ | `sudo apt install git` |
| **curl** | 7.68+ | `sudo apt install curl` |

---

## 🚀 Instalação Passo a Passo

### 1️⃣ Preparação do Ambiente

```bash
# 1. Clone o repositório
git clone <seu-repositorio>
cd SRE

# 2. Verificar Docker
docker --version
docker info

# 3. Verificar permissões
sudo usermod -aG docker $USER
newgrp docker
```

### 2️⃣ Instalação do Kubernetes Local

```bash
# 1. Navegar para o diretório
cd observabilidade-k8s-local

# 2. Executar instalação
chmod +x install.sh
./install.sh

# 3. Verificar instalação
kubectl get nodes
kubectl get pods --all-namespaces
```

**⏱️ Tempo estimado**: 5-10 minutos

### 3️⃣ Instalação do OpenTelemetry

```bash
# 1. Navegar para o diretório
cd ../observabilidade-opentelemetry

# 2. Executar instalação
chmod +x install.sh
./install.sh

# 3. Verificar instalação
kubectl get pods --all-namespaces
kubectl get opentelemetrycollector -n platform
```

**⏱️ Tempo estimado**: 10-15 minutos

### 4️⃣ Instalação do SigNoz

```bash
# 1. Navegar para o diretório
cd ../observabilidade-signoz

# 2. Executar instalação
chmod +x install.sh
./install.sh

# 3. Verificar instalação
kubectl get pods --all-namespaces
kubectl get svc -n platform
```

**⏱️ Tempo estimado**: 15-20 minutos

### 5️⃣ Instalação do ArgoCD

```bash
# 1. Navegar para o diretório
cd ../observabilidade-argocd

# 2. Executar instalação
chmod +x install.sh
./install.sh

# 3. Verificar instalação
kubectl get pods -n argocd
kubectl get applicationset -n argocd
```

**⏱️ Tempo estimado**: 10-15 minutos

### 6️⃣ Instalação da API de Teste

```bash
# 1. Navegar para o diretório
cd ../test-api

# 2. Aplicar configurações
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/api-with-telemetry.yaml

# 3. Verificar instalação
kubectl get pods -n test-api
kubectl get svc -n test-api
```

**⏱️ Tempo estimado**: 5-10 minutos

---

## 🌐 Configuração de Acesso

### 🔧 Port-Forward dos Serviços

```bash
# Terminal 1: SigNoz
kubectl port-forward -n platform svc/signoz 3301:8080

# Terminal 2: ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 3: Test API
kubectl port-forward svc/test-api-telemetry-service -n test-api 8080:8000

# Terminal 4: HotROD (opcional)
kubectl port-forward svc/hotrod -n hotrod 8080:8080
```

### 🌐 URLs de Acesso

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **SigNoz UI** | http://localhost:3301 | Acesso direto |
| **ArgoCD UI** | https://localhost:8080 | admin / [senha gerada] |
| **Test API** | http://localhost:8080 | Acesso direto |
| **HotROD App** | http://localhost:8080 | Acesso direto |

### 🔐 Obter Credenciais do ArgoCD

```bash
# Obter senha do admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📊 Verificação da Instalação

### 🔍 Comandos de Verificação

```bash
# 1. Verificar status do cluster
kubectl get nodes
kubectl get pods --all-namespaces

# 2. Verificar serviços
kubectl get svc --all-namespaces

# 3. Verificar namespaces
kubectl get namespaces

# 4. Verificar recursos
kubectl top nodes
kubectl top pods --all-namespaces
```

### 📈 Verificação de Telemetria

```bash
# 1. Verificar OpenTelemetry Collectors
kubectl get opentelemetrycollector -n platform

# 2. Verificar logs dos collectors
kubectl logs -n platform -l app.kubernetes.io/name=opentelemetry-collector

# 3. Verificar métricas
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 🚀 Verificação do ArgoCD

```bash
# 1. Verificar ApplicationSets
kubectl get applicationset -n argocd

# 2. Verificar Applications
kubectl get applications -n argocd

# 3. Verificar logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

---

## 🔧 Configuração Avançada

### 📊 Personalização do SigNoz

```yaml
# Exemplo de configuração personalizada
apiVersion: v1
kind: ConfigMap
metadata:
  name: signoz-config
  namespace: platform
data:
  config.yaml: |
    frontend:
      service:
        type: ClusterIP
        port: 8080
    otelCollector:
      service:
        type: ClusterIP
        port: 4317
    clickhouse:
      persistence:
        enabled: true
        size: 10Gi
```

### 🔐 Configuração de Segurança

```bash
# 1. Alterar senha do ArgoCD
argocd account update-password --account admin --current-password [senha-atual] --new-password [nova-senha]

# 2. Configurar RBAC
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, */*, allow
    p, role:admin, repositories, *, */*, allow
    g, argocd-admins, role:admin
EOF
```

---

## 🔧 Troubleshooting

### ❌ Problemas Comuns

#### Cluster não inicia
```bash
# Verificar Docker
docker info

# Verificar logs do Kind
kind logs --name observability

# Recriar cluster
kind delete cluster --name observability
kind create cluster --name observability
```

#### Pods não ficam prontos
```bash
# Verificar recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Verificar eventos
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Verificar logs
kubectl logs -n platform -l app.kubernetes.io/name=signoz
```

#### Telemetria não funciona
```bash
# Verificar conectividade
kubectl exec -n platform -l app.kubernetes.io/name=opentelemetry-collector -- nslookup signoz-otel-collector.platform.svc.cluster.local

# Verificar configuração
kubectl get opentelemetrycollector -n platform -o yaml

# Verificar logs
kubectl logs -n platform -l app.kubernetes.io/name=opentelemetry-collector
```

### 🔧 Comandos de Diagnóstico

```bash
# Verificar status geral
kubectl get all --all-namespaces

# Verificar recursos
kubectl top nodes
kubectl top pods --all-namespaces

# Verificar logs
kubectl logs --all-namespaces --tail=100

# Verificar eventos
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

---

## 🧹 Limpeza e Manutenção

### 🗑️ Remoção Completa

```bash
# 1. Remover cluster Kind
kind delete cluster --name observability

# 2. Limpar recursos Docker
docker system prune -a

# 3. Remover imagens
docker image prune -a
```

### 🔄 Recriação do Ambiente

```bash
# 1. Remover cluster existente
kind delete cluster --name observability

# 2. Recriar cluster
kind create cluster --name observability

# 3. Reinstalar componentes
cd observabilidade-k8s-local && ./install.sh
cd ../observabilidade-opentelemetry && ./install.sh
cd ../observabilidade-signoz && ./install.sh
cd ../observabilidade-argocd && ./install.sh
```

---

## 📚 Documentação Adicional

### 🔗 Links Úteis

- **[Kubernetes Documentation](https://kubernetes.io/docs/)** - Documentação oficial
- **[OpenTelemetry](https://opentelemetry.io/docs/)** - Telemetria
- **[SigNoz](https://signoz.io/docs/)** - Observabilidade
- **[ArgoCD](https://argo-cd.readthedocs.io/)** - GitOps

### 📖 Exemplos Práticos

- **[Test API](test-api/)** - Aplicações de exemplo
- **[ArgoCD Apps](test-api/k8s/argocd-app-*.yaml)** - Aplicações ArgoCD
- **[Kustomize](test-api/k8s/base/)** - Configurações por ambiente

---

## 🎯 Próximos Passos

Após a instalação completa, você pode:

1. **Explorar** a interface do SigNoz
2. **Configurar** dashboards personalizados
3. **Criar** alertas para monitoramento
4. **Integrar** com aplicações existentes
5. **Configurar** pipelines de CI/CD com ArgoCD

---

## 🤝 Suporte

### 📞 Contato

- **Issues**: Use o sistema de issues do GitHub
- **Discussões**: Use as discussões do repositório
- **Email**: Para questões urgentes

### 📚 Recursos Adicionais

- **Wiki**: Documentação colaborativa
- **FAQ**: Perguntas frequentes
- **Changelog**: Histórico de mudanças

---

**Versão**: 1.0.0  
**Última atualização**: $(date +%Y-%m-%d)  
**Status**: ✅ Documentação Completa
