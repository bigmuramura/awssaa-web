variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "ap-northeast-1"
}

# VPC作成
resource "aws_vpc" "awssaa-vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true # AWSのDNSサーバで名前解決有効
  enable_dns_hostnames = true # VPC内のリソースにパブリックDNSホスト名を自動割り当て有効
  tags = {
    Name = "awssaa-vpc"
  }
}

# サブネット作成 Public
resource "aws_subnet" "public-subnet-1a" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.10.0/24"
  map_public_ip_on_launch = true # インスタンスにパブリックIP自動割り当て有効
  availability_zone       = "ap-northeast-1a"
  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_subnet" "public-subnet-1c" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.11.0/24"
  map_public_ip_on_launch = true # インスタンスにパブリックIP自動割り当て有効
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "public-subnet-1c"
  }
}

# サブネット作成 Private
resource "aws_subnet" "private-subnet-1a" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.20.0/24"
  map_public_ip_on_launch = false # インスタンスにパブリックIP自動割り当てない
  availability_zone       = "ap-northeast-1a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "private-subnet-1c" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.21.0/24"
  map_public_ip_on_launch = false # インスタンスにパブリックIP自動割り当てない
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "private-subnet"
  }
}
# インターネットゲートウェイ作成
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-igw"
  }
}

# ルートテーブル作成 Public
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-public-rt"
  }
}

# ルーティング設定 Public
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public-rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# サブネットとルートテーブルの紐付け Public
resource "aws_route_table_association" "public-1a" {
  subnet_id      = aws_subnet.public-subnet-1a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-1c" {
  subnet_id      = aws_subnet.public-subnet-1c.id
  route_table_id = aws_route_table.public-rt.id
}

# NATゲートウェイ作成 Privateサブネット用
# 先にNATゲートウェイ用のEIPを作成する必要がある
resource "aws_eip" "nat-gateway-eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  # NATゲートウェイは暗黙的にIGWに依存している。
  # depends onでIGW作成後にNATゲートウェイ作成することを保証する
}

resource "aws_eip" "nat-gateway-eip2" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

# NATゲートウェイ作成
resource "aws_nat_gateway" "nat-gateway-1a" {
  allocation_id = aws_eip.nat-gateway-eip1.id
  subnet_id     = aws_subnet.public-subnet-1a.id # NATゲートウェイ自体はPublicに置かれる
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "awssaa-nat-gateway-1a"
  }
}
resource "aws_nat_gateway" "nat-gateway-1c" {
  allocation_id = aws_eip.nat-gateway-eip2.id
  subnet_id     = aws_subnet.public-subnet-1c.id # NATゲートウェイ自体はPublicに置かれる
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "awssaa-nat-gateway-1c"
  }
}
# ルートテーブル作成 Private
resource "aws_route_table" "private-rt1" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-private-rt1"
  }
}

resource "aws_route_table" "private-rt2" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-private-rt2"
  }
}
# ルーティング設定 Private
resource "aws_route" "private-1a" {
  route_table_id         = aws_route_table.private-rt1.id
  nat_gateway_id         = aws_nat_gateway.nat-gateway-1a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private-1c" {
  route_table_id         = aws_route_table.private-rt2.id
  nat_gateway_id         = aws_nat_gateway.nat-gateway-1c.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private-subnet-1a.id
  route_table_id = aws_route_table.private-rt1.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private-subnet-1c.id
  route_table_id = aws_route_table.private-rt2.id
}
