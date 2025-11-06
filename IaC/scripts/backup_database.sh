#!/bin/bash

# ========================================================================
# Script de Backup de Banco de Dados MySQL/PostgreSQL
# ========================================================================
# Este script realiza backup do banco de dados, envia para S3 e 
# notifica o administrador via email (SNS)
# ========================================================================

set -e  # Sair em caso de erro

# Configurações (estas variáveis serão injetadas pelo Terraform)
DB_TYPE="${DB_TYPE:-mysql}"  # mysql ou postgres
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-database}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD}"
BACKUP_BUCKET="${BACKUP_BUCKET}"
SNS_TOPIC_ARN="${SNS_TOPIC_ARN}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Diretórios
BACKUP_DIR="/tmp/backups"
mkdir -p "$BACKUP_DIR"

# Nome do arquivo com data no formato ISO
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup_${DB_NAME}_${DATE}.sql"
BACKUP_FILE_GZ="backup_${DB_NAME}_${TIMESTAMP}.sql.gz"
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

# Trap para garantir cleanup em caso de erro
trap cleanup EXIT

# ========================================================================
# 1. GERAR BACKUP DO BANCO DE DADOS
# ========================================================================
echo "Gerando backup do banco de dados $DB_NAME..." | tee -a "$LOG_FILE"

if [ "$DB_TYPE" == "mysql" ]; then
    # Backup MySQL/MariaDB
    if ! mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" \
        --single-transaction --routines --triggers --events \
        "$DB_NAME" > "$BACKUP_PATH" 2>> "$LOG_FILE"; then
        
        ERROR_MSG="ERRO: Falha ao gerar backup do MySQL para $DB_NAME em $(hostname)"
        echo "$ERROR_MSG" | tee -a "$LOG_FILE"
        send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
        exit 1
    fi
    
elif [ "$DB_TYPE" == "postgres" ]; then
    # Backup PostgreSQL
    export PGPASSWORD="$DB_PASSWORD"
    
    if ! pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
        -F plain -f "$BACKUP_PATH" "$DB_NAME" 2>> "$LOG_FILE"; then
        
        ERROR_MSG="ERRO: Falha ao gerar backup do PostgreSQL para $DB_NAME em $(hostname)"
        echo "$ERROR_MSG" | tee -a "$LOG_FILE"
        send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
        exit 1
    fi
    
    unset PGPASSWORD
else
    ERROR_MSG="ERRO: Tipo de banco de dados não suportado: $DB_TYPE"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
    exit 1
fi

echo "Backup gerado com sucesso: $BACKUP_PATH" | tee -a "$LOG_FILE"

# Comprimir o backup
echo "Comprimindo backup..." | tee -a "$LOG_FILE"
if ! gzip -c "$BACKUP_PATH" > "$BACKUP_PATH_GZ" 2>> "$LOG_FILE"; then
    ERROR_MSG="ERRO: Falha ao comprimir o backup"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    send_notification "❌ Falha no Backup do Banco de Dados" "$ERROR_MSG"
    exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_PATH_GZ" | cut -f1)
echo "Backup comprimido: $BACKUP_PATH_GZ (Tamanho: $BACKUP_SIZE)" | tee -a "$LOG_FILE"

# ========================================================================
# 2. ENVIAR BACKUP PARA S3
# ========================================================================
echo "Enviando backup para S3: s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ" | tee -a "$LOG_FILE"

if ! aws s3 cp "$BACKUP_PATH_GZ" "s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ" \
    --region "$AWS_REGION" 2>> "$LOG_FILE"; then
    
    ERROR_MSG="ERRO: Falha ao enviar backup para S3 (s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ)"
    echo "$ERROR_MSG" | tee -a "$LOG_FILE"
    send_notification "❌ Falha no Upload do Backup para S3" "$ERROR_MSG"
    exit 1
fi

echo "Backup enviado com sucesso para S3" | tee -a "$LOG_FILE"

# ========================================================================
# 3. ENVIAR NOTIFICAÇÃO DE SUCESSO
# ========================================================================
SUCCESS_MSG="✅ Backup do banco de dados realizado com SUCESSO!

Detalhes:
- Banco de Dados: $DB_NAME
- Data: $DATE
- Timestamp: $TIMESTAMP
- Arquivo: $BACKUP_FILE_GZ
- Tamanho: $BACKUP_SIZE
- Localização S3: s3://$BACKUP_BUCKET/backups/$BACKUP_FILE_GZ
- Servidor: $(hostname)
- IP: $(hostname -I | awk '{print $1}')

O backup foi comprimido e armazenado com sucesso no bucket S3."

echo "$SUCCESS_MSG" | tee -a "$LOG_FILE"
send_notification "✅ Backup do Banco de Dados - SUCESSO" "$SUCCESS_MSG"

# ========================================================================
# 4. LIMPEZA DE BACKUPS ANTIGOS (opcional - manter últimos 30 dias)
# ========================================================================
echo "Verificando backups antigos para limpeza..." | tee -a "$LOG_FILE"

# Listar e deletar backups com mais de 30 dias
aws s3 ls "s3://$BACKUP_BUCKET/backups/" --region "$AWS_REGION" | \
    while read -r line; do
        BACKUP_DATE=$(echo "$line" | awk '{print $1}')
        BACKUP_NAME=$(echo "$line" | awk '{print $4}')
        
        if [ -n "$BACKUP_DATE" ] && [ -n "$BACKUP_NAME" ]; then
            DAYS_OLD=$(( ($(date +%s) - $(date -d "$BACKUP_DATE" +%s)) / 86400 ))
            
            if [ "$DAYS_OLD" -gt 30 ]; then
                echo "Deletando backup antigo: $BACKUP_NAME ($DAYS_OLD dias)" | tee -a "$LOG_FILE"
                aws s3 rm "s3://$BACKUP_BUCKET/backups/$BACKUP_NAME" --region "$AWS_REGION" 2>> "$LOG_FILE"
            fi
        fi
    done

echo "Fim do backup: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

exit 0
