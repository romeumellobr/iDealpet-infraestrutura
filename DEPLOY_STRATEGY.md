# Estratégia de Deploy - iDealPet API Backend v2

## Problema Identificado

O commit `c9c547e` ("simplify cloudbuild pipeline") removeu o Terraform do processo de deploy, causando:
- **20+ falhas consecutivas** de deploy
- **Perda de integração** com load balancer
- **Abandono da infraestrutura como código**
- **Instabilidade** no ambiente de produção

## Solução Implementada

### Separação de Responsabilidades

#### 1. Repositório `iDealPet-API-Backend-v2`
**Responsabilidade**: Build e Push da imagem Docker

**Pipeline (.cloudbuild.yaml)**:
```yaml
steps:
  # Build da imagem Docker
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/api-backend-v2:$SHORT_SHA', '.']
  
  # Tag como latest
  - name: 'gcr.io/cloud-builders/docker'
    args: ['tag', 'gcr.io/$PROJECT_ID/api-backend-v2:$SHORT_SHA', 'gcr.io/$PROJECT_ID/api-backend-v2:latest']
  
  # Push das imagens
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/api-backend-v2:$SHORT_SHA']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/api-backend-v2:latest']
```

#### 2. Repositório `iDealPet-Infraestrutura`
**Responsabilidade**: Deploy via Terraform e atualização do Load Balancer

**Pipeline (.cloudbuild.yaml)**:
- Terraform Init/Validate/Plan/Apply
- Captura de outputs do Terraform
- Atualização automática do Load Balancer
- Integração com Secret Manager

## Configurações Otimizadas

### Recursos do Cloud Run
- **CPU**: 1 vCPU
- **Memória**: 1Gi (aumentado de 512Mi)
- **Instâncias mínimas**: 0 (economia de custos)
- **Instâncias máximas**: 10 (melhor escalabilidade)

### Variáveis de Ambiente
- Migração para Secret Manager (`BACKEND_V2_ENVIRONMENTS`)
- Remoção de variáveis hardcoded no pipeline

## Fluxo de Deploy

### 1. Desenvolvimento
```bash
# No repositório da API
git push origin main
# → Trigger automático do Cloud Build
# → Build e push da imagem Docker
```

### 2. Deploy de Infraestrutura
```bash
# No repositório de infraestrutura
cd applications/cloud_run/api-backend-v2
terraform init -backend-config=".environments/production/backend.hcl"
terraform plan -var-file=".environments/production/variables.auto.tfvars" -var-file=".environments/production/environment.auto.tfvars"
terraform apply
```

### 3. Automação via Cloud Build
```bash
# Trigger manual ou automático
gcloud builds submit --config=.cloudbuild.yaml \
  --substitutions=_SERVICE_NAME=api-backend-v2,_ENVIRONMENT=production
```

## Benefícios da Nova Estratégia

### ✅ Infraestrutura como Código
- Controle total via Terraform
- Versionamento de mudanças
- Rollback facilitado

### ✅ Integração com Load Balancer
- Atualização automática via script
- Configuração de SSL e domínios
- Políticas de segurança

### ✅ Separação de Responsabilidades
- API: foco no build da aplicação
- Infraestrutura: foco no deploy e configuração

### ✅ Escalabilidade e Performance
- Recursos otimizados
- Auto-scaling configurado
- Monitoramento integrado

## Comandos Úteis

### Verificar Status do Deploy
```bash
# Ver logs do Cloud Build
gcloud builds list --limit=10

# Ver status do Cloud Run
gcloud run services describe api-backend-v2 --region=us-central1

# Ver outputs do Terraform
terraform output
```

### Rollback
```bash
# Via Terraform (recomendado)
git checkout <commit-anterior>
terraform apply

# Via gcloud (emergência)
gcloud run services replace-traffic api-backend-v2 --to-revisions=<revision-anterior>=100
```

## Monitoramento

### Métricas Importantes
- **Latência**: < 500ms
- **Taxa de erro**: < 1%
- **Disponibilidade**: > 99.9%
- **Utilização de CPU**: < 80%
- **Utilização de memória**: < 80%

### Alertas Configurados
- Falhas de deploy
- Alta latência
- Erros 5xx
- Indisponibilidade do serviço

---

**Última atualização**: $(date)
**Responsável**: Equipe DevOps M2Labs