#!/bin/bash

# criando o diretório de html
# ATENÇÃO! se o usuário da EC2 for ubuntu, trocar ec2-user por ubuntu

mkdir /home/ec2-user/frontend
chown ec2-user:ec2-user /home/ec2-user/frontend
echo "<h1>Uh papai! NGINX via Docker Compose!</h1>" > /home/ec2-user/frontend/index.html
echo "Página inicial do nginx criada com sucesso."

sudo docker compose -f /home/ec2-user/compose.yaml up -d
echo "NGINX iniciado com sucesso."

