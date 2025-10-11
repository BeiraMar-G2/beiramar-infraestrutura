#!/bin/bash

# Executa o Script de instalação do Docker
# ATENÇÃO: Este script é específico para Amazon Linux. Use o de ubuntu se o for o caso de sua instância
echo "Executando script de instalação do Docker..."
{{ file("scripts/instalar_docker_amazon_linux.sh") }}

# Executa o Script de instalação do NGINX
echo "Executando script de instalação do NGINX..."
{{ file("scripts/instalar_nginx.sh") }}

echo "Execução de todos os scripts concluída."