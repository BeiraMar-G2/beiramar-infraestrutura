# ------------------------------------------------------
# EC2 Front-End (Subnet Pública)
# ------------------------------------------------------
resource "aws_instance" "front1" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t3.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true

  tags = {
    Name = "front-end-1"
  }

  user_data = join("\n\n", [
    "#!/bin/bash",
    file("${path.module}/scripts/instalar_docker_amazon_linux.sh"),
    file("${path.module}/scripts/instalar_nginx.sh"),
    "cat << 'EOF' > /home/ec2-user/compose.yaml",
    file("${path.module}/scripts/compose-nginx.yaml"),
    "EOF"
  ])

  user_data_replace_on_change = true
}

resource "aws_instance" "front2" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t3.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_publica.id]
  associate_public_ip_address = true

  tags = {
    Name = "front-end-2"
  }
  
  user_data = join("\n\n", [
    "#!/bin/bash",
    file("${path.module}/scripts/instalar_docker_amazon_linux.sh"),
    file("${path.module}/scripts/instalar_nginx.sh"),
    "cat << 'EOF' > /home/ec2-user/compose.yaml",
    file("${path.module}/scripts/compose-nginx.yaml"),
    "EOF"
  ])

  user_data_replace_on_change = true
}

# ------------------------------------------------------
# EC2 Back-End (Subnet Privada)
# ------------------------------------------------------
resource "aws_instance" "back" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t3.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada.id]
  associate_public_ip_address = false

  tags = {
    Name = "back-end"
  }
}

# ------------------------------------------------------
# EC2 Banco de Dados (Subnet Privada)
# ------------------------------------------------------
resource "aws_instance" "database" {
  ami                         = "ami-00ca32bbc84273381"
  instance_type               = "t3.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.subrede_privada.id
  vpc_security_group_ids      = [aws_security_group.sg_privada.id]
  associate_public_ip_address = false
  # AWS Academy já fornece LabRole automaticamente - não precisa de iam_instance_profile

  tags = {
    Name = "database"
  }

  user_data = templatefile("${path.module}/scripts/setup_database_backup.sh", {
    DB_TYPE         = var.db_type
    DB_HOST         = "localhost"
    DB_PORT         = var.db_port
    DB_NAME         = var.db_name
    DB_USER         = var.db_user
    DB_PASSWORD     = var.db_password
    BACKUP_BUCKET   = aws_s3_bucket.backup.id
    SNS_TOPIC_ARN   = aws_sns_topic.backup_notifications.arn
    AWS_REGION      = "us-east-1"
    BACKUP_HOUR     = var.backup_hour
    BACKUP_MINUTE   = var.backup_minute
  })

  user_data_replace_on_change = true

  depends_on = [
    aws_s3_bucket.backup,
    aws_sns_topic.backup_notifications
  ]
}
