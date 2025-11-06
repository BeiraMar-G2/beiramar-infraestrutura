variable "cidr_qualquer_ip" {
  description = "Qualquer IP do mundo"
  type        = string
  default     = "0.0.0.0/0"
  
}

# ========================================================================
# Variáveis para Backup do Banco de Dados
# ========================================================================

variable "admin_email" {
  description = "Email do administrador para receber notificações de backup"
  type        = string
  default     = "admin@example.com"  # ALTERAR para o email real
}

variable "db_type" {
  description = "Tipo do banco de dados (mysql ou postgres)"
  type        = string
  default     = "mysql"
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
  default     = "beira_mar_db"
}

variable "db_user" {
  description = "Usuário do banco de dados"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
  default     = "senha_segura_123"  # ALTERAR para senha real
}

variable "db_port" {
  description = "Porta do banco de dados"
  type        = string
  default     = "3306"
}

variable "backup_hour" {
  description = "Hora do dia para executar o backup (formato 24h)"
  type        = number
  default     = 2  # 2:00 AM
}

variable "backup_minute" {
  description = "Minuto da hora para executar o backup"
  type        = number
  default     = 0
}