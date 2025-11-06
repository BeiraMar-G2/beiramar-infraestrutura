# ========================================================================
# Arquivo de Variáveis do Terraform - Exemplo
# ========================================================================
# Copie este arquivo para terraform.tfvars e ajuste os valores
# NUNCA commite o arquivo terraform.tfvars no Git (contém senhas)
# ========================================================================

# ------------------------------------------------------
# Email do Administrador (OBRIGATÓRIO)
# ------------------------------------------------------
# Email que receberá notificações sobre os backups
admin_email = "email"

# ------------------------------------------------------
# Configurações do Banco de Dados
# ------------------------------------------------------
# Tipo do banco: "mysql" ou "postgres"
db_type = "mysql"

# Nome do banco de dados
db_name = "beiramar"

# Usuário do banco de dados
db_user = "root"

# Senha do banco de dados (ALTERAR PARA SENHA REAL)
db_password = "#senha"

# Porta do banco de dados
# 3306 para MySQL/MariaDB
db_port = "3306"

# ------------------------------------------------------
# Horário do Backup
# ------------------------------------------------------
# Hora do dia para executar o backup (0-23, formato 24h)
# Recomendado: horário de baixa utilização do sistema
backup_hour = 1

# Minuto da hora (0-59)
backup_minute = 30


