variable "aws_access_key" {}
variable "aws_secret_key" {}
  
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = "ap-northeast-1"
}

resource "aws_vpc" "awssaa-web-vpc" {
    cidr_block = "172.16.0.0/16"
    tags = {
        Name = "awssaa-web-vpc"
    }
}


