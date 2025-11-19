#!/bin/bash
set -e  # Para em caso de erro
exec > >(tee /var/log/user-data.log) 2>&1  # Log completo

echo "=== Iniciando user-data ==="
yum update -y

# Instala Docker
echo "=== Instalando Docker ==="
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Instala Docker Compose V2
echo "=== Instalando Docker Compose ==="
mkdir -p /usr/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/lib/docker/cli-plugins/docker-compose
chmod +x /usr/lib/docker/cli-plugins/docker-compose

# Verifica instalação
docker --version
docker compose version

# Cria pasta do projeto
echo "=== Criando estrutura de diretórios ==="
mkdir -p /home/ec2-user/frontend
chown -R ec2-user:ec2-user /home/ec2-user/frontend

# Cria docker-compose.yml com cat (mais confiável)
echo "=== Criando docker-compose.yml ==="
cat > /home/ec2-user/docker-compose.yml << 'EOFCOMPOSE'
version: "3.9"
services:
  web_server:
    image: nginx:latest
    container_name: frontend_nginx
    ports:
      - "80:80"
    volumes:
      - /home/ec2-user/frontend:/usr/share/nginx/html
    restart: unless-stopped
EOFCOMPOSE

chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
chmod 644 /home/ec2-user/docker-compose.yml

# Verifica se o arquivo foi criado
echo "=== Verificando arquivo criado ==="
ls -la /home/ec2-user/docker-compose.yml
cat /home/ec2-user/docker-compose.yml

# Aguarda Docker estar completamente pronto
echo "=== Aguardando Docker ==="
sleep 5

# Inicia container
echo "=== Iniciando container ==="
cd /home/ec2-user
docker compose up -d

echo "=== User-data concluído com sucesso ==="
