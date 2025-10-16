#!/bin/bash

# Variáveis fixas
PROJECT_ID="pet-hero-423816"

echo "Iniciando o script..."

if [[ -z "$BACKEND_SERVICE_ID" || -z "$HOST" || -z "$PATH_MATCHER_NAME" || -z "$GCP_PROJECT_ENVIRONMENT" ]]; then
  echo "Erro: Uma ou mais variáveis de ambiente necessárias não estão definidas."
  exit 1
fi

# Pegar os outputs do Terraform
echo "Iniciando o script com as seguintes variáveis:"
echo "BACKEND_SERVICE_ID=$BACKEND_SERVICE_ID"
echo "HOST=$HOST"
echo "PATH_MATCHER_NAME=$PATH_MATCHER_NAME"
echo "GCP_PROJECT_ENVIRONMENT=$GCP_PROJECT_ENVIRONMENT"

# Verificar se os valores foram obtidos corretamente
if [ -z "$BACKEND_SERVICE_ID" ] || [ -z "$HOST" ] || [ -z "$PATH_MATCHER_NAME" ] || [ -z "$GCP_PROJECT_ENVIRONMENT" ]; then
  echo "Erro: Um ou mais outputs do Terraform estão vazios."
  echo "BACKEND_SERVICE_ID=$BACKEND_SERVICE_ID"
  echo "HOST=$HOST"
  echo "PATH_MATCHER_NAME=$PATH_MATCHER_NAME"
  echo "GCP_PROJECT_ENVIRONMENT=$GCP_PROJECT_ENVIRONMENT"
  echo "Verifique se 'terraform apply' foi executado com sucesso no diretório atual."
  exit 1
fi
echo "Outputs obtidos com sucesso:"
echo "BACKEND_SERVICE_ID=$BACKEND_SERVICE_ID"
echo "HOST=$HOST"
echo "PATH_MATCHER_NAME=$PATH_MATCHER_NAME"
echo "GCP_PROJECT_ENVIRONMENT=$GCP_PROJECT_ENVIRONMENT"

# Definir o nome do url_map
URL_MAP_NAME="idealpet-${GCP_PROJECT_ENVIRONMENT}"
echo "Nome do URL Map: $URL_MAP_NAME"

# Configurar o projeto no gcloud
echo "Configurando o projeto $PROJECT_ID no gcloud..."
gcloud config set project "$PROJECT_ID" --quiet
if [ $? -ne 0 ]; then
  echo "Erro ao configurar o projeto no gcloud."
  exit 1
fi

# Verificar a conta ativa
echo "Conta ativa: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"

# Função para forçar a atualização do url_map
force_update_url_map() {
  echo "Verificando se o URL Map '$URL_MAP_NAME' existe..."
  DESCRIPTION=$(gcloud compute url-maps describe "$URL_MAP_NAME" --project="$PROJECT_ID" 2>&1)
  if [ $? -ne 0 ]; then
    echo "Erro: Não foi possível acessar o URL Map '$URL_MAP_NAME'. Detalhes:"
    echo "$DESCRIPTION"
    echo "Verifique se a conta ativa tem permissões suficientes (ex.: roles/compute.loadBalancerAdmin)."
    exit 1
  fi
  echo "URL Map encontrado."

  # Exportar o url_map para um arquivo YAML temporário com formato correto
  echo "Exportando configuração do URL Map para análise..."
  EXPORT_OUTPUT=$(gcloud compute url-maps describe "$URL_MAP_NAME" --project="$PROJECT_ID" --format=yaml 2>&1)
  if [ $? -ne 0 ]; then
    echo "Erro ao exportar o URL Map. Detalhes:"
    echo "$EXPORT_OUTPUT"
    echo "Verifique permissões ou tente executar o comando manualmente para depuração."
    exit 1
  fi
  echo "$EXPORT_OUTPUT" > /tmp/url_map.yaml
  echo "Configuração exportada com sucesso para /tmp/url_map.yaml."

  # Verificar se o path_matcher já existe
  echo "Verificando se o path_matcher '$PATH_MATCHER_NAME' já existe..."
  PATH_MATCHER_EXISTS=$(grep -A 1 "name: $PATH_MATCHER_NAME" /tmp/url_map.yaml)
  if [ -n "$PATH_MATCHER_EXISTS" ]; then
    echo "Path matcher '$PATH_MATCHER_NAME' encontrado. Removendo para forçar a atualização..."
    gcloud compute url-maps remove-path-matcher "$URL_MAP_NAME" \
      --project="$PROJECT_ID" \
      --path-matcher-name="$PATH_MATCHER_NAME" \
      --quiet
    if [ $? -ne 0 ]; then
      echo "Erro ao remover o path_matcher existente."
      rm -f /tmp/url_map.yaml
      exit 1
    fi
    echo "Path matcher '$PATH_MATCHER_NAME' removido com sucesso."
  else
    echo "Path matcher '$PATH_MATCHER_NAME' não existe. Prosseguindo para adicionar."
  fi

  # Limpar arquivo temporário
  rm -f /tmp/url_map.yaml

  # Adicionar o novo path_matcher
  echo "Adicionando o novo path_matcher '$PATH_MATCHER_NAME' ao URL Map '$URL_MAP_NAME'..."
  gcloud compute url-maps add-path-matcher "$URL_MAP_NAME" \
    --project="$PROJECT_ID" \
    --path-matcher-name="$PATH_MATCHER_NAME" \
    --default-service="$BACKEND_SERVICE_ID" \
    --new-hosts="$HOST" \
    --path-rules="/*=$BACKEND_SERVICE_ID" \
    --quiet
  if [ $? -eq 0 ]; then
    echo "URL Map atualizado com sucesso!"
  else
    echo "Erro ao adicionar o novo path_matcher. Verifique permissões ou estado do recurso."
    exit 1
  fi
}

# Executar a atualização forçada
echo "Executando a função de atualização forçada..."
force_update_url_map
echo "Script concluído!"