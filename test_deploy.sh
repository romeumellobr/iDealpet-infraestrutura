#!/bin/bash

# Script de Teste do Deploy - iDealPet API Backend v2
# Valida se o deploy foi realizado com sucesso

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SERVICE_NAME="api-backend-v2"
REGION="us-central1"
PROJECT_ID=$(gcloud config get-value project)

echo -e "${BLUE}🚀 Iniciando testes do deploy para ${SERVICE_NAME}${NC}"
echo "=================================================="

# Função para log com timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Função para verificar se comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        log "${RED}❌ Comando $1 não encontrado${NC}"
        exit 1
    fi
}

# Verificar dependências
log "${BLUE}🔍 Verificando dependências...${NC}"
check_command "gcloud"
check_command "curl"
check_command "jq"

# 1. Verificar se o serviço existe
log "${BLUE}📋 Verificando se o serviço Cloud Run existe...${NC}"
if gcloud run services describe $SERVICE_NAME --region=$REGION &>/dev/null; then
    log "${GREEN}✅ Serviço $SERVICE_NAME encontrado${NC}"
else
    log "${RED}❌ Serviço $SERVICE_NAME não encontrado${NC}"
    exit 1
fi

# 2. Obter informações do serviço
log "${BLUE}📊 Obtendo informações do serviço...${NC}"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
SERVICE_IMAGE=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.spec.template.spec.containers[0].image)")
SERVICE_STATUS=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.conditions[0].status)")

log "🔗 URL: $SERVICE_URL"
log "🐳 Imagem: $SERVICE_IMAGE"
log "📊 Status: $SERVICE_STATUS"

# 3. Verificar se o serviço está rodando
log "${BLUE}🏃 Verificando se o serviço está ativo...${NC}"
if [ "$SERVICE_STATUS" = "True" ]; then
    log "${GREEN}✅ Serviço está ativo${NC}"
else
    log "${RED}❌ Serviço não está ativo${NC}"
    exit 1
fi

# 4. Teste de conectividade básica
log "${BLUE}🌐 Testando conectividade básica...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    log "${GREEN}✅ Endpoint /health respondeu com 200${NC}"
elif [ "$HTTP_STATUS" = "404" ]; then
    log "${YELLOW}⚠️  Endpoint /health não encontrado (404) - testando raiz${NC}"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/" || echo "000")
    if [ "$HTTP_STATUS" = "200" ]; then
        log "${GREEN}✅ Endpoint raiz respondeu com 200${NC}"
    else
        log "${RED}❌ Serviço não está respondendo (HTTP $HTTP_STATUS)${NC}"
    fi
else
    log "${RED}❌ Serviço não está respondendo (HTTP $HTTP_STATUS)${NC}"
fi

# 5. Verificar configurações de recursos
log "${BLUE}⚙️  Verificando configurações de recursos...${NC}"
CPU_LIMIT=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.spec.template.spec.containers[0].resources.limits.cpu)")
MEMORY_LIMIT=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.spec.template.spec.containers[0].resources.limits.memory)")
MIN_INSTANCES=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.metadata.annotations['autoscaling.knative.dev/minScale'])")
MAX_INSTANCES=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.metadata.annotations['autoscaling.knative.dev/maxScale'])")

log "💻 CPU: $CPU_LIMIT"
log "🧠 Memória: $MEMORY_LIMIT"
log "📉 Min Instâncias: $MIN_INSTANCES"
log "📈 Max Instâncias: $MAX_INSTANCES"

# 6. Verificar variáveis de ambiente
log "${BLUE}🔐 Verificando configuração de variáveis de ambiente...${NC}"
ENV_VARS=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.spec.template.spec.containers[0].env[].name)" | tr '\n' ' ')
log "🔧 Variáveis configuradas: $ENV_VARS"

# 7. Verificar conectividade com VPC
log "${BLUE}🌐 Verificando conectividade VPC...${NC}"
VPC_CONNECTOR=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(spec.template.metadata.annotations['run.googleapis.com/vpc-access-connector'])")
if [ -n "$VPC_CONNECTOR" ]; then
    log "${GREEN}✅ VPC Connector configurado: $VPC_CONNECTOR${NC}"
else
    log "${YELLOW}⚠️  VPC Connector não configurado${NC}"
fi

# 8. Verificar logs recentes
log "${BLUE}📝 Verificando logs recentes...${NC}"
RECENT_LOGS=$(gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" --limit=5 --format="value(timestamp,textPayload)" 2>/dev/null || echo "Nenhum log encontrado")
if [ "$RECENT_LOGS" != "Nenhum log encontrado" ]; then
    log "${GREEN}✅ Logs recentes encontrados${NC}"
    echo "$RECENT_LOGS" | head -3
else
    log "${YELLOW}⚠️  Nenhum log recente encontrado${NC}"
fi

# 9. Teste de performance básico
log "${BLUE}⚡ Executando teste de performance básico...${NC}"
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$SERVICE_URL/" 2>/dev/null || echo "0")
if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
    log "${GREEN}✅ Tempo de resposta: ${RESPONSE_TIME}s (< 2s)${NC}"
else
    log "${YELLOW}⚠️  Tempo de resposta: ${RESPONSE_TIME}s (> 2s)${NC}"
fi

# 10. Verificar integração com Load Balancer
log "${BLUE}🔄 Verificando integração com Load Balancer...${NC}"
DOMAIN_URL="https://api.ideepet.com.br"
LB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DOMAIN_URL/health" 2>/dev/null || echo "000")

if [ "$LB_STATUS" = "200" ]; then
    log "${GREEN}✅ Load Balancer está direcionando tráfego corretamente${NC}"
elif [ "$LB_STATUS" = "404" ]; then
    log "${YELLOW}⚠️  Load Balancer conectado, mas endpoint /health não encontrado${NC}"
else
    log "${RED}❌ Problema na integração com Load Balancer (HTTP $LB_STATUS)${NC}"
fi

# Resumo final
echo ""
echo "=================================================="
log "${BLUE}📋 RESUMO DO TESTE${NC}"
echo "=================================================="

if [ "$SERVICE_STATUS" = "True" ] && [ "$HTTP_STATUS" = "200" ]; then
    log "${GREEN}🎉 DEPLOY VALIDADO COM SUCESSO!${NC}"
    log "${GREEN}✅ Serviço está funcionando corretamente${NC}"
    echo ""
    log "${BLUE}🔗 URLs de acesso:${NC}"
    log "   Cloud Run: $SERVICE_URL"
    log "   Load Balancer: $DOMAIN_URL"
    echo ""
    exit 0
else
    log "${RED}❌ PROBLEMAS DETECTADOS NO DEPLOY${NC}"
    log "${RED}🔧 Verifique os logs e configurações acima${NC}"
    echo ""
    exit 1
fi