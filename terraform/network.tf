resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "devops-vpc"
  }
}

resource "aws_subnet" "devops-public-subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "devops-public-subnet"
  }
}

resource "aws_subnet" "devops-private-subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.0.128/25"
  availability_zone       = "ap-southeast-1a"
  tags = {
    Name = "devops-private-subnet"
  }
}

resource "aws_internet_gateway" "devops-igw" {
  vpc_id = aws_vpc.devops_vpc.id
  tags = {
    Name = "devops-igw"
  }
}

resource "aws_eip" "devops-eip" {
  domain = "vpc"
  tags = {
    Name = "devops-eip"
  }
}

resource "aws_nat_gateway" "devops-nat-gateway" {
  allocation_id = aws_eip.devops-eip.id
  subnet_id     = aws_subnet.devops-public-subnet.id
  tags = {
    Name = "devops-nat-gateway"
  }
}

resource "aws_route_table" "devops-public-route" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_internet_gateway.devops-igw.id
  }
  tags = {
    Name = "devops-public-route"
  }
}

resource "aws_route_table" "devops-private-route" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.devops-nat-gateway.id
  }
  tags = {
    Name = "devops-private-route"
  }
}

resource "aws_route_table_association" "devops-public-link" {
  subnet_id      = aws_subnet.devops-public-subnet.id
  route_table_id = aws_route_table.devops-public-route.id
}

resource "aws_route_table_association" "devops-private-link" {
  subnet_id      = aws_subnet.devops-private-subnet.id
  route_table_id = aws_route_table.devops-private-route.id
}