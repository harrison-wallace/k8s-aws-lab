terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

# Default Tags
  default_tags {
    tags = {
      Project = "k8s_aws_lab"
      ManagedBy = "Terraform"
      DeployedBy = "Jenkins"
      StateBucket = var.state_bucket_name
    }
  }
}

# Fetch the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Networking Resources
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "k8s_vpc"
  }
}

resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "k8s_igw"
  }
}

resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
  tags = {
    Name = "k8s_route_table"
  }
}

resource "aws_route_table_association" "k8s_rta_public" {
  subnet_id      = aws_subnet.k8s_subnet_public.id
  route_table_id = aws_route_table.k8s_route_table.id
}

resource "aws_subnet" "k8s_subnet_public" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_availability_zone
  map_public_ip_on_launch = false
  tags = {
    Name = "k8s_subnet_public"
  }
}

resource "aws_security_group" "k8s_control_plane_sg" {
  name        = "k8s_control_plane_sg"
  description = "Security group for k8s control plane instances"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_public_ip}/32"]
  }

  # Kubernetes Control Plane Ports (from worker nodes and kubectl)
  ingress {
    description = "Kubernetes API Server, etcd, kubelet, etc."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

  tags = {
    Name = "k8s_control_plane_sg"
  }
}

resource "aws_security_group" "k8s_worker_sg" {
  name        = "k8s_worker_sg"
  description = "Security group for k8s worker instances"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH Access from Control Plane
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.k8s_control_plane_sg.id]
  }

  # Kubernetes Worker Node Ports
  ingress {
    description = "Kubelet and other worker node ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "k8s_worker_sg"
  }

}

# SSH Key Pair
resource "aws_key_pair" "k8s_key_pair" {
  key_name   = "k8s_key_pair"
  public_key = var.ssh_public_key

  tags = {
    Name = "k8s_key_pair"
  }
  
}

# EC2 Instances
resource "aws_instance" "control_plane" {
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = "t3.medium"
  subnet_id               = aws_subnet.k8s_subnet_public.id
  vpc_security_group_ids  = [aws_security_group.k8s_control_plane_sg.id]
  key_name                = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  user_data               = data.template_file.control_plane_bootstrap.rendered

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.control_plane_bootstrap.id,
      tls_private_key.internal_ssh_key.private_key_openssh
    ]
  }

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "worker" {
  count                 = 2
  ami                   = data.aws_ami.ubuntu.id
  instance_type         = "t3.medium"
  subnet_id             = aws_subnet.k8s_subnet_public.id
  vpc_security_group_ids = [aws_security_group.k8s_worker_sg.id]
  key_name              = aws_key_pair.k8s_key_pair.key_name
  associate_public_ip_address = true
  user_data             = data.template_file.worker_node_bootstrap.rendered

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.worker_node_bootstrap.id,
      tls_private_key.internal_ssh_key.private_key_openssh
    ]
  }

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

# Internal Key Pair for Node Communication
resource "tls_private_key" "internal_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096  
}

data "template_file" "control_plane_bootstrap" {
  template = file("bin/control-plane-bootstrap.sh.tpl")
  vars = {
    internal_ssh_private_key = tls_private_key.internal_ssh_key.private_key_openssh
  }
}

data "template_file" "worker_node_bootstrap" {
  template = file("bin/worker-node-bootstrap.sh.tpl")
  vars = {
    internal_ssh_public_key = tls_private_key.internal_ssh_key.public_key_openssh
  }
}

# Null Resources to trigger re-execution of user data scripts on changes
resource "null_resource" "control_plane_bootstrap" {
  triggers = {
    script_hash = filemd5("bin/control-plane-bootstrap.sh.tpl")
  }
}

resource "null_resource" "worker_node_bootstrap" {
  triggers = {
    script_hash = filemd5("bin/worker-node-bootstrap.sh.tpl")
  }
}