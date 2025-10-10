resource "aws_subnet" "subrede_publica" {
  vpc_id            = aws_vpc.vpc_beira_mar.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subrede-publica"
  }
}

resource "aws_subnet" "subrede_privada" {
  vpc_id            = aws_vpc.vpc_beira_mar.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subrede-privada"
  }
}