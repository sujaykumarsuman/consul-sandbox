# This Terraform module sets up a Consul client instance in AWS
# that is connected to an HCP Consul cluster. It creates a VPC, subnets,
# security groups, and an EC2 instance that runs the Consul client with payloads.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.108.0"
    }
  }
}

data "aws_caller_identity" "current" {}

# use ubuntu 22.04 ami
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# create a key for SSH access
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# create aws key pair using the generated SSH key
resource "aws_key_pair" "hcp_key" {
  key_name   = "hcp-consul-client-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# create a VPC for the Consul client and payload instance
# This VPC will be peered with the HCP HVN
# Ensure that the CIDR block does not overlap with the HCP HVN CIDR block
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "hcp-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "hcp-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "consul_sg" {
  name        = "consul-client-sg"
  description = "Allow SSH and Consul"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = [var.hcp_cidr_block]
  }

  ingress {
    from_port   = 8502
    to_port     = 8502
    protocol    = "tcp"
    cidr_blocks = [var.hcp_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "payload_ingress" {
  count             = var.payload_port != 0 ? 1 : 0
  type              = "ingress"
  from_port         = var.payload_port
  to_port           = var.payload_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul_sg.id
  description       = "Payload port access"
}

resource "aws_instance" "consul_client_hcp" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.hcp_key.key_name

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.consul_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../../../shared/data-scripts/hcp/user-data-client.sh", {
    consul_ent_license = var.consul_ent_license
    payload_binary     = var.payload_binary
    payload_id         = var.payload_id
    payload_port       = var.payload_port
    datacenter         = var.datacenter
  })

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/../../../shared"
    destination = "/home/ubuntu/shared"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /ops",
      "sudo mv /home/ubuntu/shared /ops/shared",
      "sudo chmod -R 755 /ops/shared"
    ]
  }

  tags = {
    Name       = "consul-client"
    ServerType = "hcp"
  }
}

data "aws_arn" "peer" {
  arn = aws_vpc.main.arn
}

data "hcp_hvn" "selected" {
  project_id = var.hcp_project_id
  hvn_id     = var.hcp_hvn_id
}

resource "hcp_aws_network_peering" "peer" {
  hvn_id          = data.hcp_hvn.selected.hvn_id
  peering_id      = "hcp-to-aws"
  peer_vpc_id     = aws_vpc.main.id
  peer_account_id = data.aws_caller_identity.current.account_id
  peer_vpc_region = data.aws_arn.peer.region
}

resource "hcp_hvn_route" "to-aws-vpc" {
  hvn_link         = data.hcp_hvn.selected.self_link
  hvn_route_id     = "hcp-to-aws-vpc"
  destination_cidr = aws_vpc.main.cidr_block
  target_link      = hcp_aws_network_peering.peer.self_link
}

resource "aws_route" "to_hcp_hvn" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.hcp_hvn.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accept.id
}

resource "aws_vpc_peering_connection_accepter" "peer_accept" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}
