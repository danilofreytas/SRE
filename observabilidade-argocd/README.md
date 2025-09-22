# ArgoCD - Repositório de Observabilidade

Este repositório contém os scripts e a documentação para a instalação isolada do ArgoCD com ApplicationSet em um cluster Kubernetes local.

## 🚀 Instalação

Para instalar o ArgoCD isoladamente, siga os passos abaixo:

### Pré-requisitos

Certifique-se de que um cluster Kubernetes (Kind) esteja em execução. Se não estiver, você pode instalá-lo usando o repositório `k8s-local` ou o script de gerenciamento completo.

### Executar a Instalação

1. Navegue até o diretório `argocd`:
   ```bash
   cd /home/danilo-reis/devops/repo/observabilidade-segmentado/argocd
   ```
2. Execute o script de instalação:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

O script irá:
- Verificar a existência do cluster Kind `observability`.
- Verificar e instalar o `helm` (se não estiver presente).
- Criar o namespace `argocd`.
- Instalar o ArgoCD usando Helm.
- Configurar ApplicationSet para observabilidade.
- Aguardar os pods do ArgoCD ficarem prontos.

## 📋 Verificação Pós-Instalação

Após a execução do script, você pode verificar o status dos componentes do ArgoCD:

- **Verificar pods do ArgoCD:**
  ```bash
  kubectl get pods -n argocd
  ```
- **Verificar ApplicationSet:**
  ```bash
  kubectl get applicationset -n argocd
  ```
- **Verificar Applications:**
  ```bash
  kubectl get applications -n argocd
  ```
- **Verificar serviços do ArgoCD:**
  ```bash
  kubectl get svc -n argocd
  ```

## 🌐 Acessando a UI do ArgoCD

Para acessar a interface web do ArgoCD:

1. **Execute o port-forward** em um terminal separado:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
2. **Acesse em seu navegador:**
   ```
   https://localhost:8080
   ```
   (Você precisará aceitar o aviso de certificado, pois o ArgoCD usa um certificado autoassinado por padrão).

### Obtendo a Senha Inicial do Admin

A senha inicial para o usuário `admin` é armazenada em um segredo do Kubernetes. Para obtê-la:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## 🔧 Componentes Instalados

### ArgoCD Server
- **Namespace**: `argocd`
- **Função**: Interface web e API do ArgoCD
- **Porta**: 443 (HTTPS)

### ArgoCD Application Controller
- **Namespace**: `argocd`
- **Função**: Controla o estado das aplicações
- **Status**: Verificar com `kubectl get pods -n argocd`

### ArgoCD Repo Server
- **Namespace**: `argocd`
- **Função**: Servidor de repositórios Git
- **Status**: Verificar com `kubectl get pods -n argocd`

### ApplicationSet
- **Namespace**: `argocd`
- **Função**: Gerencia múltiplas aplicações
- **Status**: Verificar com `kubectl get applicationset -n argocd`

## 💡 Próximos Passos

1. Faça login na UI do ArgoCD com o usuário `admin` e a senha obtida.
2. Considere alterar a senha padrão do admin na UI.
3. Comece a configurar suas aplicações para deployment via GitOps com o ArgoCD.
4. Configure repositórios Git para sincronização automática.

## 🔗 Componentes Relacionados

- **Kubernetes Local**: Pré-requisito para execução
- **SigNoz**: Para observabilidade das aplicações
- **OpenTelemetry**: Para coleta de telemetria
