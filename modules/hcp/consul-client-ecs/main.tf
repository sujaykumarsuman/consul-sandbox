# Terraform module to run a Consul client and payload service on ECS Fargate

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

data "aws_availability_zones" "available" {}

# Networking
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
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "hcp-public-subnet" }
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

resource "aws_security_group" "ecs" {
  name        = "consul-client-ecs-sg"
  description = "Allow Consul and payload access"
  vpc_id      = aws_vpc.main.id

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
  security_group_id = aws_security_group.ecs.id
  description       = "Payload port access"
}

# ECS resources
resource "aws_ecs_cluster" "this" {
  name = "${var.payload_id}-cluster"
}

data "aws_iam_policy_document" "task_execution" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.payload_id}-exec"
  assume_role_policy = data.aws_iam_policy_document.task_execution.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

locals {
  payload_container = {
    name      = var.payload_id
    image     = var.payload_image
    essential = true
    command   = var.payload_command
    portMappings = var.payload_port != 0 ? [
      {
        containerPort = var.payload_port
        hostPort      = var.payload_port
        protocol      = "tcp"
      }
    ] : []
  }

  consul_container = {
    name      = "consul-client"
    image     = "hashicorp/consul:1.18.0"
    essential = true
    command = [
      "agent",
      "-retry-join", var.consul_http_addr,
      "-datacenter", var.datacenter,
      "-client", "0.0.0.0"
    ]
    environment = [
      { name = "CONSUL_HTTP_TOKEN", value = var.consul_http_token },
      { name = "CONSUL_HTTP_ADDR", value = var.consul_http_addr }
    ]
    portMappings = [
      { containerPort = 8500, hostPort = 8500, protocol = "tcp" },
      { containerPort = 8502, hostPort = 8502, protocol = "tcp" },
      { containerPort = 8301, hostPort = 8301, protocol = "tcp" }
    ]
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.payload_id
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    local.consul_container,
    local.payload_container,
  ])
}

resource "aws_ecs_service" "this" {
  name            = var.payload_id
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
}

# HVN Peering

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

resource "aws_vpc_peering_connection_accepter" "peer_accept" {
  vpc_peering_connection_id = hcp_aws_network_peering.peer.provider_peering_id
  auto_accept               = true
}

resource "aws_route" "to_hcp_hvn" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.hcp_hvn.selected.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer_accept.id
}
