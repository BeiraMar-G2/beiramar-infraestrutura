# ------------------------------------------------------
# EC2 Front-End (Subnet Pública)
# ------------------------------------------------------
resource "aws_instance" "front1" {
  ami                    = "ami-00ca32bbc84273381" # Amazon Linux 2
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subrede_publica.id
  vpc_security_group_ids = [aws_security_group.sg_publica.id]
  key_name               = "vockey"

  associate_public_ip_address = true

  user_data = file("${path.module}/scripts/userdata-front.sh")

  tags = {
    Name = "frontend-1"
  }
}



resource "aws_instance" "front2" {
  ami                    = "ami-00ca32bbc84273381" # Amazon Linux 2
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subrede_publica.id
  vpc_security_group_ids = [aws_security_group.sg_publica.id]
  key_name               = "vockey"

  associate_public_ip_address = true

  user_data = file("${path.module}/scripts/userdata-front.sh")

  tags = {
    Name = "frontend-2"
  }
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
