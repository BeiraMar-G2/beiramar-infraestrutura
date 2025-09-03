resource "aws_vpc" "vpc_beira_mar" {
  cidr_block = "10.0.0.0/27"
  tags = {
    Name = "vpc-beira-mar"
  }
}