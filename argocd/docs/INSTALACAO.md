# 📖 Guia de Instalação - ArgoCD

## 🎯 Objetivo

Este guia fornece instruções detalhadas para instalar e configurar o ArgoCD em um cluster Kubernetes para automação GitOps.

## 📋 Pré-requisitos

### Sistema
- **Kubernetes**: Versão 1.19 ou superior
- **kubectl**: Configurado e conectado ao cluster
- **Helm**: Versão 3.x instalada
- **Git**: Para clonagem de repositórios

### Recursos Mínimos
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 10GB

## 🚀 Instalação Passo a Passo

### 1. Preparação do Cluster

```bash
# Verificar conectividade
kubectl cluster-info

# Verificar recursos disponíveis
kubectl top nodes
```

### 2. Criação do Namespace

```bash
# Criar namespace
kubectl create namespace argocd

# Verificar criação
kubectl get namespaces | grep argocd
```

### 3. Instalação via Helm

```bash
# Adicionar repositório Helm
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Instalar ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --version 5.51.6 \
  --values values.yaml
```

### 4. Verificação da Instalação

```bash
# Verificar pods
kubectl get pods -n argocd

# Verificar serviços
kubectl get svc -n argocd

# Verificar deployments
kubectl get deployments -n argocd
```

## ⚙️ Configuração Inicial

### 1. Obter Senha Admin

```bash
# Obter senha inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### 2. Configurar Port Forward

```bash
# Port forward para acesso local
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 3. Acesso à Interface Web

```bash
# Acessar interface
open https://localhost:8080

# Login
Username: admin
Password: [senha obtida no passo 1]
```

## 🔧 Configurações Avançadas

### 1. Configurar Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - argocd.yourdomain.com
    secretName: argocd-server-tls
  rules:
  - host: argocd.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
```

### 2. Configurar RBAC

```yaml
# rbac-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    g, argocd-admins, role:admin
```

## 🧪 Teste da Instalação

### 1. Criar Aplicação de Teste

```yaml
# test-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 2. Aplicar e Verificar

```bash
# Aplicar aplicação
kubectl apply -f test-app.yaml

# Verificar status
kubectl get applications -n argocd

# Verificar sincronização
argocd app get test-app
```

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Pods não iniciam
```bash
# Verificar logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Verificar recursos
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
```

#### 2. Erro de conectividade
```bash
# Verificar serviços
kubectl get svc -n argocd

# Verificar endpoints
kubectl get endpoints -n argocd
```

#### 3. Problemas de autenticação
```bash
# Verificar secret
kubectl get secret argocd-initial-admin-secret -n argocd

# Regenerar senha
kubectl delete secret argocd-initial-admin-secret -n argocd
kubectl apply -f argocd-server-deployment.yaml
```

## 📊 Monitoramento

### 1. Métricas

```bash
# Verificar métricas
kubectl port-forward svc/argocd-server-metrics -n argocd 8083:8083

# Acessar métricas
curl http://localhost:8083/metrics
```

### 2. Logs

```bash
# Logs do servidor
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Logs do controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

## 🔄 Atualização

### 1. Backup

```bash
# Backup das aplicações
kubectl get applications -n argocd -o yaml > backup-applications.yaml

# Backup das configurações
kubectl get configmaps -n argocd -o yaml > backup-configmaps.yaml
```

### 2. Atualização

```bash
# Atualizar via Helm
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --version 5.52.0 \
  --values values.yaml
```

## ✅ Verificação Final

### Checklist de Instalação

- [ ] Namespace criado
- [ ] Pods rodando
- [ ] Serviços funcionando
- [ ] Interface web acessível
- [ ] Login funcionando
- [ ] Aplicação de teste sincronizada
- [ ] RBAC configurado
- [ ] Ingress configurado (se aplicável)

## 📞 Suporte

### Comandos Úteis

```bash
# Status geral
kubectl get all -n argocd

# Logs em tempo real
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# Descrever recursos
kubectl describe deployment argocd-server -n argocd
```

### Documentação Adicional

- [Documentação Oficial ArgoCD](https://argo-cd.readthedocs.io/)
- [Exemplos de Aplicações](https://github.com/argoproj/argocd-example-apps)
- [Configurações Avançadas](https://argo-cd.readthedocs.io/en/stable/operator-manual/)

---

**Versão**: 1.0.0  
**Última atualização**: $(date +%Y-%m-%d)  
**Status**: ✅ Testado e Funcional
