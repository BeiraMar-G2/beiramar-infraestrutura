#!/bin/bash

# ========================================================================
# Script de Inicialização da Instância de Banco de Dados
# ========================================================================
# Este script é executado no primeiro boot da instância EC2 e configura:
# - Instalação de dependências (MySQL/PostgreSQL, AWS CLI, Python, etc.)
# - Cópia dos scripts de backup
# - Configuração do Cron Job
# ========================================================================

set -e

echo "========================================="
echo "Iniciando configuração do servidor de backup"
echo "========================================="

# Configurações injetadas pelo Terraform
export DB_TYPE="${DB_TYPE}"
export DB_HOST="${DB_HOST}"
export DB_PORT="${DB_PORT}"
export DB_NAME="${DB_NAME}"
export DB_USER="${DB_USER}"
export DB_PASSWORD="${DB_PASSWORD}"
export BACKUP_BUCKET="${BACKUP_BUCKET}"
export SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"
export AWS_REGION="${AWS_REGION}"
export BACKUP_HOUR="${BACKUP_HOUR}"
export BACKUP_MINUTE="${BACKUP_MINUTE}"

# ------------------------------------------------------
# 1. Atualizar sistema (DESABILITADO para agilizar)
# ------------------------------------------------------
echo "Pulando atualização do sistema para agilizar inicialização..."
# sudo yum update -y

# ------------------------------------------------------
# 2. Instalar AWS CLI (se não estiver instalado)
# ------------------------------------------------------
if ! command -v aws &> /dev/null; then
    echo "Instalando AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Verificar instalação
aws --version

# ------------------------------------------------------
# 3. Instalar cliente do banco de dados
# ------------------------------------------------------
if [ "$DB_TYPE" == "mysql" ]; then
    echo "Instalando MySQL client..."
    sudo yum install -y mysql
elif [ "$DB_TYPE" == "postgres" ]; then
    echo "Instalando PostgreSQL client..."
    sudo amazon-linux-extras install postgresql14 -y
fi

# ------------------------------------------------------
# 4. Instalar Python 3 e dependências
# ------------------------------------------------------
echo "Instalando Python 3 e pip..."
sudo yum install -y python3 python3-pip

echo "Instalando boto3..."
sudo pip3 install boto3

# ------------------------------------------------------
# 5. Criar diretórios necessários
# ------------------------------------------------------
echo "Criando diretórios..."
sudo mkdir -p /usr/local/bin
sudo mkdir -p /var/log
sudo touch /var/log/backup_database.log
sudo chmod 666 /var/log/backup_database.log

# ------------------------------------------------------
# 6. Criar script de backup (versão Bash)
# ------------------------------------------------------
echo "Criando script de backup (Bash)..."
cat << 'BACKUP_SCRIPT_EOF' | sudo tee /usr/local/bin/backup_database.sh > /dev/null
#!/bin/bash

# ========================================================================
# Script de Backup de Banco de Dados
# ========================================================================

set -e

# Configurações
DB_TYPE="$DB_TYPE"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"
BACKUP_BUCKET="$BACKUP_BUCKET"
SNS_TOPIC_ARN="$SNS_TOPIC_ARN"
AWS_REGION="$AWS_REGION"

# Diretórios
BACKUP_DIR="/tmp/backups"
mkdir -p "$BACKUP_DIR"

# Nome do arquivo com data no formato ISO
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup_$${DB_NAME}_$${DATE}.sql"
BACKUP_FILE_GZ="backup_$${DB_NAME}_$${TIMESTAMP}.sql.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
BACKUP_PATH_GZ="$BACKUP_DIR/$BACKUP_FILE_GZ"

# Logs
LOG_FILE="/var/log/backup_database.log"
echo "========================================" >> "$LOG_FILE"
echo "Início do backup: $(date)" >> "$LOG_FILE"

# Função para enviar notificação SNS
send_notification() {
    local subject="$1"
    local message="$2"
    
    aws sns publish \
        --topic-arn "$SNS_TOPIC_ARN" \
        --subject "$subject" \
        --message "$message" \
        --region "$AWS_REGION" 2>&1 | tee -a "$LOG_FILE"
}

# Função de cleanup
cleanup() {
    echo "Limpando arquivos temporários..." | tee -a "$LOG_FILE"
    rm -f "$BACKUP_PATH" "$BACKUP_PATH_GZ"
}

trap cleanup EXIT

# Gerar backup
echo "Gerando backup do banco de dados $DB_NAME..." | tee -a "$LOG_FILE"

if [ "$DB_TYPE" == "mysql" ]; then
    if ! mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction --routines --triggers --events \
        "$DB_NAME" > "$BACKUP_PATH" 2>> "$LOG_FILE"; then
        
        ERROR_MSG="ERRO: Falha ao gerar backup do MySQL para $DB_NAME em $(hostname)"
        echo "$ERROR_MSG" | tee -a "$LOG_FILE"
        send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
        exit 1
    fi
elif [ "$DB_TYPE" == "postgres" ]; then
    export PGPASSWORD="$DB_PASSWORD"
    
    if ! pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -F plain -f "$BACKUP_PATH" "$DB_NAME" 2>> "$LOG_FILE"; then
        
        ERROR_MSG="ERRO: Falha ao gerar backup do PostgreSQL para $DB_NAME em $(hostname)"
        echo "$ERROR_MSG" | tee -a "$LOG_FILE"
        send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
        exit 1
    fi
    
    unset PGPASSWORD
fi

echo "Backup gerado: $BACKUP_PATH" | tee -a "$LOG_FILE"

# Comprimir
echo "Comprimindo backup..." | tee -a "$LOG_FILE"
gzip -c "$BACKUP_PATH" > "$BACKUP_PATH_GZ"

BACKUP_SIZE=$(du -h "$BACKUP_PATH_GZ" | cut -f1)
echo "Backup comprimido: $BACKUP_SIZE" | tee -a "$LOG_FILE"

# Upload para S3
echo "Enviando para S3..." | tee -a "$LOG_FILE"
if ! aws s3 cp "$BACKUP_PATH_GZ" "s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ" \
    --region "$AWS_REGION" 2>> "$LOG_FILE"; then
    
    ERROR_MSG="ERRO: Falha ao enviar para S3"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    send_notification "❌ Falha no Upload do Backup" "$ERROR_MSG"
    exit 1
fi

# Notificação de sucesso
SUCCESS_MSG="✅ Backup realizado com SUCESSO!

Detalhes:
- Banco: $DB_NAME
- Data: $DATE
- Arquivo: $BACKUP_FILE_GZ
- Tamanho: $BACKUP_SIZE
- S3: s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ
- Servidor: $(hostname)"

echo "Backup concluído!" | tee -a "$LOG_FILE"
send_notification "✅ Backup do Banco - SUCESSO" "$SUCCESS_MSG"

echo "Fim do backup: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

exit 0
BACKUP_SCRIPT_EOF

sudo chmod +x /usr/local/bin/backup_database.sh

# ------------------------------------------------------
# 7. Criar arquivo de variáveis de ambiente
# ------------------------------------------------------
echo "Criando arquivo de variáveis de ambiente..."
cat << ENV_EOF | sudo tee /etc/backup_env.sh > /dev/null
# Variáveis de ambiente para o script de backup
export DB_TYPE="$DB_TYPE"
export DB_HOST="$DB_HOST"
export DB_PORT="$DB_PORT"
export DB_NAME="$DB_NAME"
export DB_USER="$DB_USER"
export DB_PASSWORD="$DB_PASSWORD"
export BACKUP_BUCKET="$BACKUP_BUCKET"
export SNS_TOPIC_ARN="$SNS_TOPIC_ARN"
export AWS_REGION="$AWS_REGION"
export PATH="/usr/local/bin:/usr/bin:/bin"
ENV_EOF

sudo chmod 600 /etc/backup_env.sh

# ------------------------------------------------------
# 8. Configurar Cron Job
# ------------------------------------------------------
echo "Configurando Cron Job..."

# Criar cron job para executar no horário especificado
CRON_JOB="$BACKUP_MINUTE $BACKUP_HOUR * * * . /etc/backup_env.sh && /usr/local/bin/backup_database.sh >> /var/log/backup_database.log 2>&1"

# Remover entradas antigas (se existirem)
sudo crontab -l 2>/dev/null | grep -v backup_database.sh | sudo crontab - 2>/dev/null || true

# Adicionar novo cron job
(sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -

echo "Cron job configurado para executar às $BACKUP_HOUR:$BACKUP_MINUTE todos os dias"

# Verificar cron jobs
echo "Cron jobs atuais:"
sudo crontab -l

# ------------------------------------------------------
# 9. Teste inicial (opcional - comentar se não quiser)
# ------------------------------------------------------
# echo "Executando teste inicial do backup..."
# sudo -E /usr/local/bin/backup_database.sh

# ------------------------------------------------------
# Finalização
# ------------------------------------------------------
echo "========================================="
echo "✅ Configuração concluída com sucesso!"
echo "========================================="
echo ""
echo "Informações:"
echo "- Script de backup: /usr/local/bin/backup_database.sh"
echo "- Log: /var/log/backup_database.log"
echo "- Horário de execução: $BACKUP_HOUR:$BACKUP_MINUTE diariamente"
echo "- Bucket S3: $BACKUP_BUCKET"
echo "- SNS Topic: $SNS_TOPIC_ARN"
echo ""
echo "Para executar manualmente: sudo /usr/local/bin/backup_database.sh"
echo "Para ver logs: tail -f /var/log/backup_database.log"
echo "========================================="
