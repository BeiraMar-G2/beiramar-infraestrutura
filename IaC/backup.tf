# ========================================================================
# RECURSOS PARA BACKUP DO BANCO DE DADOS
# ========================================================================

# ------------------------------------------------------
# Bucket S3 para Backups
# ------------------------------------------------------
resource "aws_s3_bucket" "backup" {
  bucket = "backup-database-beira-mar"

  tags = {
    Name        = "Backup Database Bucket"
    Environment = "Production"
    Purpose     = "Database Backups"
  }
}

# Habilitar versionamento para proteção adicional
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configurar lifecycle para remover versões antigas
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {
      prefix = ""  # Aplica a todos os objetos
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Criptografia do bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acesso público
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------
# SNS Topic para Notificações
# ------------------------------------------------------
resource "aws_sns_topic" "backup_notifications" {
  name         = "database-backup-notifications"
  display_name = "Database Backup Notifications"

  tags = {
    Name        = "Backup Notifications"
    Environment = "Production"
  }
}

# Subscription do SNS (adicione o email do administrador)
resource "aws_sns_topic_subscription" "backup_email" {
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol  = "email"
  endpoint  = var.admin_email  # Será definido em variable.tf
}

# ------------------------------------------------------
# NOTA: IAM não disponível na conta AWS Academy
# ------------------------------------------------------
# A AWS Academy não permite criar IAM Roles/Policies
# As credenciais são fornecidas via LabRole automático
# O acesso a S3 e SNS já está configurado no LabRole

# ------------------------------------------------------
# Outputs para uso nos scripts
# ------------------------------------------------------
output "backup_bucket_name" {
  description = "Nome do bucket de backup"
  value       = aws_s3_bucket.backup.id
}

output "sns_topic_arn" {
  description = "ARN do SNS Topic para notificações"
  value       = aws_sns_topic.backup_notifications.arn
}

output "backup_configuration" {
  description = "Configuração do backup"
  value = {
    bucket     = aws_s3_bucket.backup.id
    sns_topic  = aws_sns_topic.backup_notifications.arn
    region     = "us-east-1"
  }
}
