variable "aws_access_id" {
  type = "string"
}

variable "aws_secret_id" {
  type = "string"
}

variable "region" {
  default = "us-east-1"
  type = "string"
}

variable "cidr_blocks" {
  type = "map"

  default = {
    db_vpc_cidr = "10.0.0.0/16"
    db_subnet_pub = "10.0.1.0/24"
    db_subnet_priv = "10.0.2.0/24"
  }
}

variable "ip_addrs" {
  type = "map"

  default = {
    db_address = "10.0.2.55"
  }
}


variable "db_vpc_cidr" {
  default = "us-east-1"
  type = "string"
}