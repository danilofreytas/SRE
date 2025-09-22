# Kubernetes Local (Kind) - Repositório de Observabilidade

Este repositório contém os scripts e a documentação para a instalação isolada de um cluster Kubernetes local usando Kind (Kubernetes in Docker).

## 🚀 Instalação

Para instalar o Kubernetes (Kind) isoladamente, siga os passos abaixo:

### Pré-requisitos

Certifique-se de ter o Docker instalado e em execução em sua máquina.

### Executar a Instalação

1. Navegue até o diretório `k8s-local`:
   ```bash
   cd /home/danilo-reis/devops/repo/observabilidade-segmentado/k8s-local
   ```
2. Execute o script de instalação:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

O script irá:
- Verificar e instalar o `kind` (se não estiver presente).
- Verificar e instalar o `kubectl` (se não estiver presente).
- Verificar se o Docker está em execução.
- Criar um cluster Kind chamado `observability`.
- Configurar o `kubectl` para usar o novo cluster.

## 📋 Verificação Pós-Instalação

Após a execução do script, você pode verificar o status do seu cluster Kubernetes com os seguintes comandos:

- Listar nós do cluster:
  ```bash
  kubectl get nodes
  ```
- Listar todos os pods em todos os namespaces:
  ```bash
  kubectl get pods --all-namespaces
  ```
- Listar clusters Kind existentes:
  ```bash
  kind get clusters
  ```

## 🗑️ Remoção do Cluster

Para remover o cluster Kind `observability`, execute o seguinte comando:

```bash
kind delete cluster --name observability
```

## 💡 Dicas

- Se encontrar problemas com permissões do Docker, certifique-se de que seu usuário está no grupo `docker` e reinicie sua sessão.
- Para mais informações sobre Kind, visite a [documentação oficial do Kind](https://kind.sigs.k8s.io/).
- Para mais informações sobre kubectl, visite a [documentação oficial do kubectl](https://kubernetes.io/docs/reference/kubectl/).

## 🔗 Próximos Passos

Após a instalação do Kubernetes, você pode instalar outros componentes:

1. **SigNoz**: Para observabilidade completa
2. **OpenTelemetry**: Para coleta de telemetria
3. **ArgoCD**: Para GitOps e deployment contínuo
