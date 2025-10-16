# Configuração do Cloud Build - iDealPet

## Triggers Necessários

### 1. Trigger para API Backend v2 (Build de Imagem)

```bash
# Criar trigger para build da imagem Docker
gcloud builds triggers create github \
  --repo-name="iDealPet-API-Backend-v2" \
  --repo-owner="MELOZ-TECH" \
  --branch-pattern="^main$" \
  --build-config=".cloudbuild.yaml" \
  --name="api-backend-v2-build" \
  --description="Build e push da imagem Docker para api-backend-v2"
```

### 2. Trigger para Infraestrutura (Deploy via Terraform)

```bash
# Criar trigger para deploy da infraestrutura
gcloud builds triggers create github \
  --repo-name="iDealPet-Infraestrutura" \
  --repo-owner="MELOZ-TECH" \
  --branch-pattern="^main$" \
  --build-config=".cloudbuild.yaml" \
  --name="infrastructure-deploy" \
  --description="Deploy da infraestrutura via Terraform" \
  --substitutions="_SERVICE_NAME=api-backend-v2,_ENVIRONMENT=production,_VARFILES=variables.auto.tfvars,environment.auto.tfvars"
```

## Configuração Manual via Console

### 1. Acesse o Cloud Build
```
https://console.cloud.google.com/cloud-build/triggers
```

### 2. Conecte os Repositórios GitHub
- Clique em "Connect Repository"
- Selecione GitHub
- Autorize o acesso
- Conecte ambos os repositórios:
  - `MELOZ-TECH/iDealPet-API-Backend-v2`
  - `MELOZ-TECH/iDealPet-Infraestrutura`

### 3. Configurar Trigger da API

**Nome**: `api-backend-v2-build`
**Evento**: Push to branch
**Repositório**: `MELOZ-TECH/iDealPet-API-Backend-v2`
**Branch**: `^main$`
**Configuração**: Cloud Build configuration file (yaml or json)
**Localização**: `.cloudbuild.yaml`

### 4. Configurar Trigger da Infraestrutura

**Nome**: `infrastructure-deploy`
**Evento**: Push to branch
**Repositório**: `MELOZ-TECH/iDealPet-Infraestrutura`
**Branch**: `^main$`
**Configuração**: Cloud Build configuration file (yaml or json)
**Localização**: `.cloudbuild.yaml`

**Variáveis de Substituição**:
- `_SERVICE_NAME`: `api-backend-v2`
- `_ENVIRONMENT`: `production`
- `_VARFILES`: `variables.auto.tfvars,environment.auto.tfvars`

## Permissões Necessárias

### Service Account do Cloud Build

```bash
# Obter email do service account
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Adicionar permissões necessárias
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/storage.admin"
```

## Teste dos Triggers

### 1. Teste do Build da API
```bash
# Fazer um commit simples na API
cd /path/to/iDealPet-API-Backend-v2
echo "# Test trigger" >> README.md
git add README.md
git commit -m "test: trigger cloud build"
git push origin main
```

### 2. Teste do Deploy da Infraestrutura
```bash
# Fazer um commit simples na infraestrutura
cd /path/to/iDealPet-Infraestrutura
echo "# Test infrastructure trigger" >> README.md
git add README.md
git commit -m "test: trigger infrastructure deploy"
git push origin main
```

### 3. Verificar Execução
```bash
# Ver builds em execução
gcloud builds list --limit=10

# Ver logs de um build específico
gcloud builds log <BUILD_ID>
```

## Deploy Manual (Emergência)

### Build da Imagem
```bash
cd /path/to/iDealPet-API-Backend-v2
gcloud builds submit --config=.cloudbuild.yaml
```

### Deploy da Infraestrutura
```bash
cd /path/to/iDealPet-Infraestrutura
gcloud builds submit --config=.cloudbuild.yaml \
  --substitutions=_SERVICE_NAME=api-backend-v2,_ENVIRONMENT=production,_VARFILES="variables.auto.tfvars,environment.auto.tfvars"
```

## Monitoramento

### Webhooks (Opcional)
Configure webhooks para notificações:
- Slack
- Discord
- Email
- PagerDuty

### Métricas Importantes
- **Build Success Rate**: > 95%
- **Build Duration**: < 10 minutos
- **Deploy Success Rate**: > 98%
- **Deploy Duration**: < 15 minutos

## Troubleshooting

### Problemas Comuns

#### 1. Permissões Insuficientes
```bash
# Verificar permissões do service account
gcloud projects get-iam-policy $(gcloud config get-value project) \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:${SERVICE_ACCOUNT}"
```

#### 2. Falha no Terraform
```bash
# Ver logs detalhados
gcloud builds log <BUILD_ID> --stream

# Verificar estado do Terraform
cd applications/cloud_run/api-backend-v2
terraform show
```

#### 3. Falha no Docker Build
```bash
# Verificar Dockerfile
docker build -t test-image .

# Verificar dependências
docker run --rm test-image npm list
```

---

**Última atualização**: $(date)
**Responsável**: Equipe DevOps M2Labs