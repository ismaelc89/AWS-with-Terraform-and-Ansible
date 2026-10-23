resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "demo_vpc"
  }
}

resource "aws_internet_gateway" "demo_ig" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo_ig"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_ec2_instance_type_offerings.t3_micro.locations[0]

  tags = {
    Name = "demo_public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.demo_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_ec2_instance_type_offerings.t3_micro.locations[0]

  tags = {
    Name = "demo_private_subnet"
  }
}

resource "aws_route_table" "demo_public_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_ig.id
  }

  tags = {
    Name = "demo_rt"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.demo_public_rt.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_security_group" "public_ec2_sg" {
  name        = "web_ec2_sg"
  description = "SG for public ec2"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = {
    Name = "web_ec2_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "allow_prometheus" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9090
  to_port           = 9090
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_exporter" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9100
  to_port           = 9100
}

resource "aws_vpc_security_group_ingress_rule" "allow_grafana" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  to_port           = 3000
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "private_ec2_sg" {
  name        = "private_ec2_sg"
  description = "SG for private EC2"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = {
    Name = "private_ec2_sg"
  }

}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_publicsg" {
  security_group_id            = aws_security_group.private_ec2_sg.id
  referenced_security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_publicsg" {
  security_group_id            = aws_security_group.private_ec2_sg.id
  referenced_security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_exporter_from_publicsg" {
  security_group_id            = aws_security_group.private_ec2_sg.id
  referenced_security_group_id = aws_security_group.public_ec2_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 9100
  to_port                      = 9100
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.private_ec2_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "public_web" {
  ami                    = data.aws_ami.amazon_ami.id
  key_name               = "MyEC2KeyPair"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_ec2_sg.id]

  tags = {
    Name        = "DemoPublicWebInstance"
    Environment = var.instance_env
    Role        = "web_proxy"
  }
}

resource "aws_instance" "private_app" {
  ami                    = data.aws_ami.amazon_ami.id
  key_name               = "MyEC2KeyPair"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  tags = {
    Name        = "DemoPrivateWebInstance"
    Environment = var.instance_env
    Role        = "app_server"
  }
}


