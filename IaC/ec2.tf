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

  tags = {
    Name = "database"
  }
}
