# SRE - Site Reliability Engineering

Repositório centralizado com ferramentas e soluções de observabilidade para Site Reliability Engineering.

## 📋 Visão Geral

Este repositório contém um conjunto completo de ferramentas e scripts para implementar observabilidade em ambientes Kubernetes, incluindo monitoramento, logging, tracing e gerenciamento de aplicações.

## 🚀 Componentes Disponíveis

### Observabilidade Principal
- **[observabilidade/](observabilidade/)** - Solução completa de observabilidade
  - ArgoCD para GitOps
  - OpenTelemetry para telemetria
  - SigNoz para monitoramento
  - Kubernetes local
  - Scripts de gerenciamento

### Soluções Especializadas
- **[observabilidade-argocd/](observabilidade-argocd/)** - Instalação e configuração do ArgoCD
- **[observabilidade-k8s-local/](observabilidade-k8s-local/)** - Kubernetes local para desenvolvimento
- **[observabilidade-opentelemetry/](observabilidade-opentelemetry/)** - OpenTelemetry Collector
- **[observabilidade-signoz/](observabilidade-signoz/)** - SigNoz para observabilidade
- **[observabilidade-documentacao/](observabilidade-documentacao/)** - Documentação técnica completa

## 🛠️ Instalação Rápida

### Pré-requisitos
- Docker e Docker Compose
- kubectl configurado
- Helm 3.x
- Git

### Instalação Completa
```bash
# Clone o repositório
git clone <seu-repositorio>
cd SRE

# Execute a instalação completa
cd observabilidade/gerenciamento
./install-all.sh
```

### Instalação Individual
```bash
# ArgoCD
cd observabilidade-argocd
./install.sh

# OpenTelemetry
cd observabilidade-opentelemetry
./install.sh

# SigNoz
cd observabilidade-signoz
./install.sh
```

## 📚 Documentação

Cada componente possui sua própria documentação detalhada:

- [Documentação Completa](observabilidade-documentacao/DOCUMENTACAO-COMPLETA.md)
- [Especificações Técnicas](observabilidade-documentacao/ESPECIFICACOES-TECNICAS.md)
- [Mapeamento Técnico](observabilidade-documentacao/MAPEAMENTO-TECNICO.md)

## 🔧 Gerenciamento

### Scripts de Controle
```bash
cd observabilidade/gerenciamento

# Iniciar todos os serviços
./start.sh

# Parar todos os serviços
./stop.sh

# Verificar status
./status.sh
```

## 📊 Monitoramento

Após a instalação, acesse:
- **SigNoz**: http://localhost:3301
- **ArgoCD**: http://localhost:8080
- **Kubernetes Dashboard**: http://localhost:8001

## 🤝 Contribuição

1. Fork o repositório
2. Crie uma branch para sua feature
3. Faça commit das mudanças
4. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para detalhes.

## 🆘 Suporte

Para suporte e questões:
- Abra uma issue no repositório
- Consulte a documentação técnica
- Verifique os logs dos serviços