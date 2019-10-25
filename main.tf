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
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.10.0/24"
  map_public_ip_on_launch = true # インスタンスにパブリックIP自動割り当て有効
  availability_zone       = "ap-northeast-1a"
  tags = {
    Name = "public-subnet"
  }
}

# サブネット作成 Private
resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.awssaa-vpc.id
  cidr_block              = "172.16.20.0/24"
  map_public_ip_on_launch = false # インスタンスにパブリックIP自動割り当てない
  availability_zone       = "ap-northeast-1a"
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

# ルートテーブル作成
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-public-rt"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.awssaa-vpc.id
  tags = {
    Name = "awssaa-private-rt"
  }
}

# ルーティング設定
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public-rt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# サブネットとルートテーブルの紐付け
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt
}

