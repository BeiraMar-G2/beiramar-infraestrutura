#!/usr/bin/env python3
"""
========================================================================
Script Python para Backup de Banco de Dados
========================================================================
Este script realiza backup do banco de dados, envia para S3 e 
notifica o administrador via SNS
========================================================================
"""

import os
import sys
import subprocess
import gzip
import shutil
from datetime import datetime, timedelta
import boto3
from botocore.exceptions import ClientError
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/backup_database.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configurações do banco de dados
DB_TYPE = os.environ.get('DB_TYPE', 'mysql')
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '3306')
DB_NAME = os.environ.get('DB_NAME', 'database')
DB_USER = os.environ.get('DB_USER', 'root')
DB_PASSWORD = os.environ.get('DB_PASSWORD', '')

# Configurações AWS
BACKUP_BUCKET = os.environ.get('BACKUP_BUCKET')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

# Diretórios
BACKUP_DIR = '/tmp/backups'
os.makedirs(BACKUP_DIR, exist_ok=True)

# Clientes AWS
s3_client = boto3.client('s3', region_name=AWS_REGION)
sns_client = boto3.client('sns', region_name=AWS_REGION)


def send_notification(subject: str, message: str):
    """Envia notificação via SNS"""
    try:
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        logger.info(f"Notificação enviada: {response['MessageId']}")
    except ClientError as e:
        logger.error(f"Erro ao enviar notificação SNS: {e}")


def create_mysql_backup(backup_path: str) -> bool:
    """Cria backup do MySQL/MariaDB"""
    try:
        cmd = [
            'mysqldump',
            '-h', DB_HOST,
            '-P', DB_PORT,
            '-u', DB_USER,
            f'-p{DB_PASSWORD}',
            '--single-transaction',
            '--routines',
            '--triggers',
            '--events',
            DB_NAME
        ]
        
        with open(backup_path, 'w') as f:
            result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            logger.error(f"Erro no mysqldump: {result.stderr}")
            return False
        
        logger.info(f"Backup MySQL criado: {backup_path}")
        return True
    
    except Exception as e:
        logger.error(f"Erro ao criar backup MySQL: {e}")
        return False


def create_postgres_backup(backup_path: str) -> bool:
    """Cria backup do PostgreSQL"""
    try:
        env = os.environ.copy()
        env['PGPASSWORD'] = DB_PASSWORD
        
        cmd = [
            'pg_dump',
            '-h', DB_HOST,
            '-p', DB_PORT,
            '-U', DB_USER,
            '-F', 'plain',
            '-f', backup_path,
            DB_NAME
        ]
        
        result = subprocess.run(cmd, env=env, stderr=subprocess.PIPE, text=True)
        
        if result.returncode != 0:
            logger.error(f"Erro no pg_dump: {result.stderr}")
            return False
        
        logger.info(f"Backup PostgreSQL criado: {backup_path}")
        return True
    
    except Exception as e:
        logger.error(f"Erro ao criar backup PostgreSQL: {e}")
        return False


def compress_file(source: str, destination: str) -> bool:
    """Comprime arquivo usando gzip"""
    try:
        with open(source, 'rb') as f_in:
            with gzip.open(destination, 'wb', compresslevel=9) as f_out:
                shutil.copyfileobj(f_in, f_out)
        
        logger.info(f"Arquivo comprimido: {destination}")
        return True
    
    except Exception as e:
        logger.error(f"Erro ao comprimir arquivo: {e}")
        return False


def upload_to_s3(file_path: str, s3_key: str) -> bool:
    """Faz upload do arquivo para S3"""
    try:
        s3_client.upload_file(
            file_path,
            BACKUP_BUCKET,
            s3_key,
            ExtraArgs={'ServerSideEncryption': 'AES256'}
        )
        
        logger.info(f"Arquivo enviado para S3: s3://{BACKUP_BUCKET}/{s3_key}")
        return True
    
    except ClientError as e:
        logger.error(f"Erro ao enviar para S3: {e}")
        return False


def cleanup_old_backups(days: int = 30):
    """Remove backups antigos do S3"""
    try:
        cutoff_date = datetime.now() - timedelta(days=days)
        
        response = s3_client.list_objects_v2(
            Bucket=BACKUP_BUCKET,
            Prefix='backups/'
        )
        
        if 'Contents' not in response:
            logger.info("Nenhum backup encontrado no S3")
            return
        
        for obj in response['Contents']:
            if obj['LastModified'].replace(tzinfo=None) < cutoff_date:
                s3_client.delete_object(Bucket=BACKUP_BUCKET, Key=obj['Key'])
                logger.info(f"Backup antigo removido: {obj['Key']}")
    
    except ClientError as e:
        logger.error(f"Erro ao limpar backups antigos: {e}")


def get_file_size(file_path: str) -> str:
    """Retorna tamanho do arquivo em formato legível"""
    size_bytes = os.path.getsize(file_path)
    
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    
    return f"{size_bytes:.2f} TB"


def main():
    """Função principal"""
    logger.info("=" * 60)
    logger.info("Iniciando processo de backup")
    logger.info("=" * 60)
    
    # Gerar nomes de arquivo
    date_iso = datetime.now().strftime('%Y-%m-%d')
    timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    
    backup_file = f"backup_{DB_NAME}_{date_iso}.sql"
    backup_file_gz = f"backup_{DB_NAME}_{timestamp}.sql.gz"
    
    backup_path = os.path.join(BACKUP_DIR, backup_file)
    backup_path_gz = os.path.join(BACKUP_DIR, backup_file_gz)
    
    try:
        # 1. Criar backup
        logger.info(f"Criando backup do banco de dados: {DB_NAME}")
        
        if DB_TYPE == 'mysql':
            success = create_mysql_backup(backup_path)
        elif DB_TYPE == 'postgres':
            success = create_postgres_backup(backup_path)
        else:
            logger.error(f"Tipo de banco não suportado: {DB_TYPE}")
            send_notification(
                "❌ Falha no Backup do Banco de Dados",
                f"Tipo de banco de dados não suportado: {DB_TYPE}"
            )
            return 1
        
        if not success:
            send_notification(
                "❌ Falha no Backup do Banco de Dados",
                f"Erro ao gerar backup do banco {DB_NAME}"
            )
            return 1
        
        # 2. Comprimir backup
        logger.info("Comprimindo backup...")
        if not compress_file(backup_path, backup_path_gz):
            send_notification(
                "❌ Falha no Backup do Banco de Dados",
                "Erro ao comprimir o arquivo de backup"
            )
            return 1
        
        backup_size = get_file_size(backup_path_gz)
        
        # 3. Upload para S3
        s3_key = f"backups/{backup_file_gz}"
        logger.info(f"Enviando para S3: s3://{BACKUP_BUCKET}/{s3_key}")
        
        if not upload_to_s3(backup_path_gz, s3_key):
            send_notification(
                "❌ Falha no Upload do Backup para S3",
                f"Erro ao enviar backup para s3://{BACKUP_BUCKET}/{s3_key}"
            )
            return 1
        
        # 4. Enviar notificação de sucesso
        hostname = subprocess.run(['hostname'], capture_output=True, text=True).stdout.strip()
        
        success_message = f"""✅ Backup do banco de dados realizado com SUCESSO!

Detalhes:
- Banco de Dados: {DB_NAME}
- Tipo: {DB_TYPE}
- Data: {date_iso}
- Timestamp: {timestamp}
- Arquivo: {backup_file_gz}
- Tamanho: {backup_size}
- Localização S3: s3://{BACKUP_BUCKET}/{s3_key}
- Servidor: {hostname}

O backup foi comprimido e armazenado com sucesso no bucket S3.
        """
        
        logger.info("Backup concluído com sucesso!")
        send_notification("✅ Backup do Banco de Dados - SUCESSO", success_message)
        
        # 5. Limpar backups antigos
        logger.info("Limpando backups antigos...")
        cleanup_old_backups(days=30)
        
        # 6. Limpar arquivos temporários
        os.remove(backup_path)
        os.remove(backup_path_gz)
        logger.info("Arquivos temporários removidos")
        
        logger.info("=" * 60)
        logger.info("Processo de backup finalizado")
        logger.info("=" * 60)
        
        return 0
    
    except Exception as e:
        error_message = f"Erro inesperado durante o backup: {str(e)}"
        logger.error(error_message)
        send_notification("❌ Falha no Backup do Banco de Dados", error_message)
        return 1


if __name__ == '__main__':
    sys.exit(main())
