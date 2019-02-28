
provider "aws" {
  version = "~> 1.0"

  access_key = "${var.aws_access_id}"
  secret_key = "${var.aws_secret_id}"
  region     = "${var.region}"
}

resource "aws_vpc" "db_vpc" {
  cidr_block       = "${var.cidr_blocks["db_vpc_cidr"]}"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "db_vpc"
    Stack = "webhooks-example"
  }
}

resource "aws_subnet" "db_sub_priv" {
  vpc_id     = "${aws_vpc.db_vpc.id}"
  cidr_block = "${var.cidr_blocks["db_subnet_priv"]}"

  tags = {
    Name = "db_sub_priv"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_subnet" "db_sub_pub" {
  vpc_id     = "${aws_vpc.db_vpc.id}"
  cidr_block = "${var.cidr_blocks["db_subnet_pub"]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "db_sub_pub"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_internet_gateway" "db_igw" {
  vpc_id = "${aws_vpc.db_vpc.id}"

  tags = {
    Name = "db_pub_gateway"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_route_table" "db_priv_routes" {
  subnet_id = "${aws_vpc.db_vpc.id}"

  tags = {
    Name = "db_priv_route_table"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_route_table" "db_pub_routes" {
  subnet_id = "${aws_vpc.db_vpc.id}"

  tags = {
    Name = "db_pub_route_table"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_route_table_association" "dp_priv_route" {
  subnet_id      = "${aws_subnet.db_sub_priv.id}"
  route_table_id = "${aws_route_table.db_priv_routes.id}"

  tags = {
    Name = "db_priv_route_assoc"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_subnet.db_sub_priv", "aws_route_table.db_priv_routes"]
}

resource "aws_route_table_association" "dp_pub_route" {
  subnet_id      = "${aws_subnet.db_sub_pub.id}"
  route_table_id = "${aws_route_table.db_pub_routes.id}"

  tags = {
    Name = "db_pub_route_assoc"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_subnet.db_sub_pub", "aws_route_table.db_pub_routes"]
}

resource "aws_eip" "db_natgat_eip" {
  domain = "vpc"

  tags = {
    Name = "db_natgat_eip"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_nat_gateway" "db_natgat" {
  allocation_id = "${aws_eip.db_natgat_eip.id}"
  subnet_id     = "${aws_subnet.db_sub_pub.id}"

  tags = {
    Name = "db_natgat"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_eip.db_natgat_eip", "aws_subnet.db_sub_pub"]
}

resource "aws_route" "db_priv_route" {
  route_table_id            = "${aws_route_table.db_priv_routes.id}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.db_natgat.id}"

  tags = {
    Name = "db_natgat"
    Stack = "webhooks-example"
  }

  depends_on                = ["aws_route_table.db_priv_routes", "aws_nat_gateway.db_natgat"]
}

resource "aws_route" "db_pub_route" {
  route_table_id            = "${aws_route_table.db_pub_routes.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.db_igw.id}"

  tags = {
    Name = "db_pub_route"
    Stack = "webhooks-example"
  }

  depends_on                = ["aws_route_table.db_pub_routes", "aws_internet_gateway.db_igw"]
}

resource "aws_security_group" "bastion_ssh" {
  name        = "bastion_ssh"
  description = "Bastion hosts - ssh"
  vpc_id      = "${aws_vpc.db_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "0.0.0.0/0"
  }

  tags = {
    Name = "bastion_ssh_group"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_default_security_group" "db_vpc_default_sg" {
  vpc_id = "${aws_vpc.db_vpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-0ac019f4fcb7cb7e6"
  instance_initiated_shutdown_behavior = "stop"
  instance_type = "t2.micro"
  key_name = "main"
  vpc_security_group_ids = ["aws_security_group.bastion_ssh", "aws_default_security_group.db_vpc_default_sg"]
  source_dest_check = true
  subnet_id = "${aws_subnet.db_sub_pub.id}"
  tags = {
    Name = "instance_bastion"
    Stack = "webhooks-example"
  }

  user_data = <<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install openssh-server -yq
service ssh start
EOF
}

resource "aws_instance" "timestreamdb" {
  ami           = "ami-0ac019f4fcb7cb7e6"
  instance_initiated_shutdown_behavior = "stop"
  instance_type = "t2.micro"
  key_name = "main"
  private_ip = "${var.ip_addrs["db_address"]}"
  vpc_security_group_ids = ["aws_default_security_group.db_vpc_default_sg"]
  source_dest_check = true
  subnet_id = "${aws_subnet.db_sub_priv.id}"

  tags = {
    Name = "instance_timestreamdb"
    Stack = "webhooks-example"
  }

  user_data = <<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install software-properties-common gnupg2 wget openssh-server -yq
sh -c \"echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' >> /etc/apt/sources.list.d/pgdg.list\"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
add-apt-repository -y ppa:timescale/timescaledb-ppa
apt-get update -yq && apt-get upgrade -yq
printf \"12\n5\n\" | apt-get install -y timescaledb-postgresql-11
timescaledb-tune --quiet --yes
sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '10.0.2.55'/g\" /etc/postgresql/11/main/postgresql.conf"
sed -i \"s/# IPv4 local connections:/host    all             all             10.0.2.0/24             md5/g\" /etc/postgresql/11/main/pg_hba.conf"
service postgresql restart
su - postgres -c \"psql -U postgres -d postgres -c \\\"alter user postgres with password 'p@ssw0rd';\\\"\"
su - postgres -c \"PGPASSWORD='p@ssw0rd' psql -U postgres -c \\\"CREATE DATABASE webhook;\\\"\"
su - postgres -c \"PGPASSWORD='p@ssw0rd' psql -U postgres -c \\\"CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;\\\" webhook\"
service ssh start"
EOF
}
