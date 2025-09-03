resource "aws_internet_gateway" "igw_beira_mar" {
  vpc_id = aws_vpc.vpc_beira_mar.id
  tags = {
    Name = "beira-mar-igw"
  }
}