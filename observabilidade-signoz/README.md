# SigNoz - Repositório de Observabilidade

Este repositório contém os scripts e a documentação para a instalação isolada do SigNoz e seus componentes de telemetria (métricas, logs e traces).

## 🚀 Instalação

Para instalar o SigNoz isoladamente, siga os passos abaixo:

### Pré-requisitos

Certifique-se de que um cluster Kubernetes (Kind) esteja em execução. Se não estiver, você pode instalá-lo usando o repositório `k8s-local` ou o script de gerenciamento completo.

### Executar a Instalação

1. Navegue até o diretório `signoz`:
   ```bash
   cd /home/danilo-reis/devops/repo/observabilidade-segmentado/signoz
   ```
2. Execute o script de instalação:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

O script irá:
- Verificar a existência do cluster Kind `observability`.
- Verificar e instalar o `helm` (se não estiver presente).
- Adicionar o repositório Helm do SigNoz.
- Criar o namespace `platform`.
- Instalar o SigNoz no cluster.
- Instalar `metrics-server`, `kube-state-metrics` e `node-exporter` para coleta de métricas.
- Deployar uma aplicação de exemplo (HotROD) para geração de traces.

## 📋 Verificação Pós-Instalação

Após a execução do script, você pode verificar o status dos componentes e acessar os serviços:

- **Verificar pods:**
  ```bash
  kubectl get pods --all-namespaces
  ```
- **Verificar serviços:**
  ```bash
  kubectl get svc --all-namespaces
  ```

## 🌐 Acessando os Serviços

Para acessar a UI do SigNoz e a aplicação HotROD, você precisará usar `kubectl port-forward` em terminais separados:

- **SigNoz UI:**
  ```bash
  kubectl port-forward -n platform svc/signoz 3301:8080
  # Acesse em seu navegador: http://localhost:3301
  ```
- **HotROD App:**
  ```bash
  kubectl port-forward svc/hotrod -n hotrod 8080:8080
  # Acesse em seu navegador: http://localhost:8080
  ```

## 💡 Próximos Passos

1. Acesse o SigNoz UI e explore os dados de métricas, logs e traces.
2. Crie alertas personalizados para monitorar o ambiente.
3. Configure dashboards para visualizar as informações de forma eficiente.

## 🔗 Componentes Relacionados

- **Kubernetes Local**: Pré-requisito para execução
- **OpenTelemetry**: Para coleta avançada de telemetria
- **ArgoCD**: Para deployment via GitOps
