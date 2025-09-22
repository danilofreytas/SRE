# OpenTelemetry - Repositório de Observabilidade

Este repositório contém os scripts e a documentação para a instalação isolada do OpenTelemetry Operator e a configuração de OpenTelemetry Collectors para coleta de telemetria (métricas, logs e traces).

## 🚀 Instalação

Para instalar o OpenTelemetry isoladamente, siga os passos abaixo:

### Pré-requisitos

Certifique-se de que um cluster Kubernetes (Kind) esteja em execução. Se não estiver, você pode instalá-lo usando o repositório `k8s-local` ou o script de gerenciamento completo.

### Executar a Instalação

1. Navegue até o diretório `opentelemetry`:
   ```bash
   cd /home/danilo-reis/devops/repo/observabilidade-segmentado/opentelemetry
   ```
2. Execute o script de instalação:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

O script irá:
- Verificar a existência do cluster Kind `observability`.
- Verificar e instalar o `helm` (se não estiver presente).
- Instalar o `cert-manager` (pré-requisito para o OpenTelemetry Operator).
- Instalar o `OpenTelemetry Operator`.
- Configurar dois `OpenTelemetry Collectors` (um DaemonSet para logs/métricas e um Deployment para traces) no namespace `platform`.

## 📋 Verificação Pós-Instalação

Após a execução do script, você pode verificar o status dos componentes:

- **Verificar pods:**
  ```bash
  kubectl get pods --all-namespaces
  ```
- **Verificar OpenTelemetry Collectors:**
  ```bash
  kubectl get opentelemetrycollector -n platform
  ```
- **Verificar serviços:**
  ```bash
  kubectl get svc --all-namespaces
  ```

## 🔧 Componentes Instalados

### Cert-Manager
- **Namespace**: `cert-manager`
- **Função**: Gerenciamento de certificados TLS
- **Status**: Verificar com `kubectl get pods -n cert-manager`

### OpenTelemetry Operator
- **Namespace**: `opentelemetry-operator-system`
- **Função**: Operador para gerenciar OpenTelemetry Collectors
- **Status**: Verificar com `kubectl get pods -n opentelemetry-operator-system`

### OpenTelemetry Collectors
- **Namespace**: `platform`
- **DaemonSet**: Coleta logs e métricas de todos os nós
- **Deployment**: Coleta traces de aplicações
- **Status**: Verificar com `kubectl get opentelemetrycollector -n platform`

## 💡 Próximos Passos

1. Instale o SigNoz (usando o repositório `signoz` ou o script de gerenciamento completo) para visualizar os dados de telemetria.
2. Configure suas aplicações para enviar traces, métricas e logs para os OpenTelemetry Collectors.
3. Explore os dados no SigNoz e configure alertas e dashboards.

## 🔗 Componentes Relacionados

- **Kubernetes Local**: Pré-requisito para execução
- **SigNoz**: Para visualização dos dados coletados
- **ArgoCD**: Para deployment via GitOps
