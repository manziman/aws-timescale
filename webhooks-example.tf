
provider "aws" {
  version = "~> 1.60.0"

  access_key = "${var.aws_access_id}"
  secret_key = "${var.aws_secret_id}"
  region     = "${var.region}"
}

resource "aws_key_pair" "main" {
  key_name   = "main"
  public_key = "${file(var.ssh_pub_key)}"
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

  depends_on = ["aws_key_pair.main"]
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
  vpc_id = "${aws_vpc.db_vpc.id}"

  tags = {
    Name = "db_priv_route_table"
    Stack = "webhooks-example"
  }
}

resource "aws_route_table" "db_pub_routes" {
  vpc_id = "${aws_vpc.db_vpc.id}"

  tags = {
    Name = "db_pub_route_table"
    Stack = "webhooks-example"
  }
}

resource "aws_route_table_association" "dp_priv_route" {
  subnet_id      = "${aws_subnet.db_sub_priv.id}"
  route_table_id = "${aws_route_table.db_priv_routes.id}"

  depends_on = ["aws_subnet.db_sub_priv", "aws_route_table.db_priv_routes"]
}

resource "aws_route_table_association" "dp_pub_route" {
  subnet_id      = "${aws_subnet.db_sub_pub.id}"
  route_table_id = "${aws_route_table.db_pub_routes.id}"

  depends_on = ["aws_subnet.db_sub_pub", "aws_route_table.db_pub_routes"]
}

resource "aws_eip" "db_natgat_eip" {
  vpc = true

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

  depends_on                = ["aws_route_table.db_priv_routes", "aws_nat_gateway.db_natgat"]
}

resource "aws_route" "db_pub_route" {
  route_table_id            = "${aws_route_table.db_pub_routes.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.db_igw.id}"

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_security_group"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}
resource "aws_security_group" "grafana_web" {
  name        = "grafana_web"
  description = "Grafana instance"
  vpc_id      = "${aws_vpc.db_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana_security_group"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc"]
}

resource "aws_default_security_group" "default" {
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
  vpc_security_group_ids = ["${aws_security_group.bastion_ssh.id}", "${aws_default_security_group.default.id}"]
  source_dest_check = true
  subnet_id = "${aws_subnet.db_sub_pub.id}"
  tags = {
    Name = "instance_bastion"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc", "aws_security_group.bastion_ssh", "aws_subnet.db_sub_pub"]

  user_data = "${file("user_data/user_data_bastion.sh")}"
}
resource "aws_instance" "grafana" {
  ami           = "ami-0ac019f4fcb7cb7e6"
  instance_initiated_shutdown_behavior = "stop"
  instance_type = "t2.micro"
  key_name = "main"
  vpc_security_group_ids = ["${aws_security_group.grafana_web.id}", "${aws_default_security_group.default.id}"]
  source_dest_check = true
  subnet_id = "${aws_subnet.db_sub_pub.id}"
  tags = {
    Name = "instance_grafana"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc", "aws_security_group.grafana_web", "aws_subnet.db_sub_pub", "aws_instance.timescaledb"]

  user_data = "${file("user_data/user_data_grafana.sh")}"
}
resource "aws_instance" "timescaledb" {
  ami           = "ami-0ac019f4fcb7cb7e6"
  instance_initiated_shutdown_behavior = "stop"
  instance_type = "t2.micro"
  key_name = "main"
  private_ip = "${var.ip_addrs["db_address"]}"
  vpc_security_group_ids = ["${aws_default_security_group.default.id}"]
  source_dest_check = true
  subnet_id = "${aws_subnet.db_sub_priv.id}"

  tags = {
    Name = "instance_timescaledb"
    Stack = "webhooks-example"
  }

  depends_on = ["aws_vpc.db_vpc", "aws_subnet.db_sub_priv"]

  user_data = "${file("user_data/user_data_db.sh")}"
}
output "db_subnet_id" {
  value = "${aws_subnet.db_sub_priv.id}"
}
output "db_internal_hostname" {
  value = "${aws_instance.timescaledb.private_dns}"
}
output "db_security_group_id" {
  value = "${aws_default_security_group.default.id}"
}
