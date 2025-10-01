# 🧪 Test API - Aplicação de Exemplo com Telemetria

## 📋 Visão Geral

Este repositório contém **aplicações de exemplo** e **configurações Kubernetes** para demonstrar integração com ferramentas de observabilidade, oferecendo exemplos práticos de instrumentação com OpenTelemetry.

### 🎯 Características

- ✅ **API REST** com FastAPI e Python
- ✅ **Instrumentação OpenTelemetry** completa
- ✅ **Banco de dados PostgreSQL** integrado
- ✅ **Configurações Kustomize** por ambiente
- ✅ **Aplicações ArgoCD** para GitOps

---

## 🏗️ Arquitetura da API

```mermaid
graph TB
    subgraph "Test API Application"
        API[FastAPI Application]
        Database[PostgreSQL Database]
        Telemetry[OpenTelemetry Instrumentation]
    end
    
    subgraph "Kubernetes Resources"
        Deployment[Deployment]
        Service[Service]
        ConfigMap[ConfigMap]
        Ingress[Ingress]
    end
    
    subgraph "Observability"
        SigNoz[SigNoz]
        OTelCollector[OpenTelemetry Collector]
        Metrics[Métricas]
        Logs[Logs]
        Traces[Traces]
    end
    
    API --> Database
    API --> Telemetry
    Telemetry --> OTelCollector
    OTelCollector --> SigNoz
    
    Deployment --> API
    Service --> Deployment
    ConfigMap --> API
    
    SigNoz --> Metrics
    SigNoz --> Logs
    SigNoz --> Traces
```

---

## 📁 Estrutura do Projeto

### 🔧 Arquivos Principais

| Arquivo | Descrição | Uso |
|---------|-----------|-----|
| `api.yaml` | API básica sem telemetria | Desenvolvimento inicial |
| `api-with-telemetry.yaml` | API com OpenTelemetry | Produção com observabilidade |
| `api-simple-telemetry.yaml` | API simplificada | Testes rápidos |
| `api-working-telemetry.yaml` | API testada e funcional | Referência |

### 📦 Configurações Kustomize

| Diretório | Descrição | Ambiente |
|-----------|-----------|----------|
| `base/` | Configurações base | Todos |
| `overlays/production/` | Configurações de produção | Produção |

### 🚀 Aplicações ArgoCD

| Arquivo | Descrição | Ambiente |
|---------|-----------|----------|
| `argocd-app.yaml` | Aplicação base | Desenvolvimento |
| `argocd-app-dev.yaml` | Aplicação de desenvolvimento | Desenvolvimento |
| `argocd-app-local.yaml` | Aplicação local | Local |
| `argocd-app-fixed.yaml` | Aplicação corrigida | Produção |

---

## 🚀 Instalação e Uso

### 📋 Pré-requisitos

- **Cluster Kubernetes** com observabilidade configurada
- **kubectl** configurado
- **ArgoCD** (opcional, para GitOps)

### ⚡ Instalação Rápida

```bash
# 1. Aplicar API básica
kubectl apply -f k8s/api.yaml

# 2. Aplicar API com telemetria
kubectl apply -f k8s/api-with-telemetry.yaml

# 3. Verificar status
kubectl get pods -n test-api
```

### 🔧 Instalação com Kustomize

```bash
# 1. Instalar base
kubectl apply -k k8s/base/

# 2. Instalar overlay de produção
kubectl apply -k k8s/overlays/production/
```

### 🚀 Instalação com ArgoCD

```bash
# 1. Aplicar aplicação ArgoCD
kubectl apply -f k8s/argocd-app.yaml

# 2. Verificar no ArgoCD UI
# Acesse: https://localhost:8080
```

---

## 📊 Funcionalidades da API

### 🔧 Endpoints Disponíveis

| Endpoint | Método | Descrição | Telemetria |
|----------|--------|-----------|------------|
| `/` | GET | Health check básico | ✅ |
| `/health` | GET | Health check detalhado | ✅ |
| `/users` | GET | Listar usuários | ✅ |
| `/users` | POST | Criar usuário | ✅ |
| `/users/{id}` | GET | Obter usuário | ✅ |
| `/docs` | GET | Documentação Swagger | ✅ |

### 📈 Métricas Coletadas

- **Request Rate**: Taxa de requisições por segundo
- **Response Time**: Tempo de resposta das APIs
- **Error Rate**: Taxa de erros (4xx, 5xx)
- **Database Connections**: Conexões com banco de dados
- **Memory Usage**: Uso de memória da aplicação

### 🔗 Traces Gerados

- **HTTP Requests**: Rastreamento de requisições HTTP
- **Database Queries**: Rastreamento de queries SQL
- **External Calls**: Chamadas para serviços externos
- **Error Handling**: Rastreamento de erros e exceções

---

## 🔧 Configuração Avançada

### 📊 Personalização da Telemetria

```yaml
# Exemplo de configuração personalizada
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: test-api
data:
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://signoz-otel-collector.platform:4317"
  OTEL_SERVICE_NAME: "test-api"
  OTEL_RESOURCE_ATTRIBUTES: "service.name=test-api,service.version=1.0.0,environment=production"
  OTEL_TRACES_EXPORTER: "otlp"
  OTEL_METRICS_EXPORTER: "otlp"
  OTEL_LOGS_EXPORTER: "otlp"
```

### 🗄️ Configuração do Banco de Dados

```yaml
# Exemplo de configuração do PostgreSQL
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: test-api
data:
  POSTGRES_DB: "testdb"
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "password123"
  POSTGRES_HOST: "postgres-service"
  POSTGRES_PORT: "5432"
```

---

## 🎯 Casos de Uso

### 👨‍💻 Para Desenvolvedores

- **Testes de instrumentação** com OpenTelemetry
- **Validação** de configurações de telemetria
- **Debugging** com traces distribuídos
- **Desenvolvimento** de APIs observáveis

### 🔧 Para DevOps

- **Testes de integração** com ferramentas de observabilidade
- **Validação** de pipelines de telemetria
- **Configuração** de ambientes de teste
- **Automação** de deployments

### 📊 Para SRE

- **Testes de observabilidade** em ambiente controlado
- **Validação** de alertas e dashboards
- **Análise** de performance e latência
- **Treinamento** em ferramentas de observabilidade

---

## 🔧 Troubleshooting

### ❌ Problemas Comuns

#### API não inicia
```bash
# Verificar logs
kubectl logs -n test-api -l app=test-api

# Verificar configuração
kubectl describe pod -n test-api -l app=test-api
```

#### Telemetria não funciona
```bash
# Verificar configuração OpenTelemetry
kubectl get configmap -n test-api api-config -o yaml

# Verificar conectividade com collector
kubectl exec -n test-api -l app=test-api -- nslookup signoz-otel-collector.platform.svc.cluster.local
```

#### Banco de dados não conecta
```bash
# Verificar logs do PostgreSQL
kubectl logs -n test-api -l app=postgres

# Verificar serviço
kubectl get svc -n test-api postgres-service
```

### 🔧 Comandos de Diagnóstico

```bash
# Verificar status dos pods
kubectl get pods -n test-api

# Verificar serviços
kubectl get svc -n test-api

# Verificar logs
kubectl logs -n test-api -l app=test-api
kubectl logs -n test-api -l app=postgres

# Testar conectividade
kubectl exec -n test-api -l app=test-api -- curl http://localhost:8000/health
```

---

## 📚 Exemplos Práticos

### 🔧 API Básica

```yaml
# Exemplo de API simples
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-api
  namespace: test-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-api
  template:
    metadata:
      labels:
        app: test-api
    spec:
      containers:
      - name: test-api
        image: python:3.11-slim
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          value: "postgresql://postgres:password123@postgres-service:5432/testdb"
```

### 📡 API com Telemetria

```yaml
# Exemplo de API com OpenTelemetry
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-api-telemetry
  namespace: test-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-api-telemetry
  template:
    metadata:
      labels:
        app: test-api-telemetry
    spec:
      containers:
      - name: test-api-telemetry
        image: python:3.11-slim
        ports:
        - containerPort: 8000
        env:
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://signoz-otel-collector.platform:4317"
        - name: OTEL_SERVICE_NAME
          value: "test-api"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.name=test-api,service.version=1.0.0"
```

---

## 📚 Documentação Adicional

### 🔗 Links Úteis

- **[FastAPI Documentation](https://fastapi.tiangolo.com/)** - Documentação do FastAPI
- **[OpenTelemetry Python](https://opentelemetry.io/docs/instrumentation/python/)** - Instrumentação Python
- **[PostgreSQL Documentation](https://www.postgresql.org/docs/)** - Documentação do PostgreSQL

### 📖 Exemplos Práticos

- **[API Configs](k8s/)** - Configurações Kubernetes
- **[ArgoCD Apps](k8s/argocd-app-*.yaml)** - Aplicações ArgoCD
- **[Kustomize](k8s/base/)** - Configurações Kustomize

---

## 🎯 Próximos Passos

Após a instalação da API de teste, você pode:

1. **Explorar** os dados no SigNoz
2. **Configurar** alertas personalizados
3. **Criar** dashboards específicos
4. **Integrar** com outras aplicações

---

## 🤝 Contribuição

### 📝 Como Contribuir

1. **Fork** o repositório
2. **Crie** uma branch para sua feature
3. **Atualize** a documentação
4. **Teste** as mudanças
5. **Abra** um Pull Request

### 📋 Padrões de Código

- **Python**: PEP 8 e type hints
- **YAML**: Indentação consistente
- **Documentação**: Markdown com exemplos práticos

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**Versão**: 1.0.0  
**Última atualização**: $(date +%Y-%m-%d)  
**Status**: ✅ Documentação Completa
