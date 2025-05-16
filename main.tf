provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "sinatra_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sinatra-vpc"
  }
}

resource "aws_subnet" "sinatra_subnet" {
  count = 2
  vpc_id                  = aws_vpc.sinatra_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.sinatra_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["us-east-2a", "us-east-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "sinatra-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "sinatra_igw" {
  vpc_id = aws_vpc.sinatra_vpc.id

  tags = {
    Name = "sinatra-igw"
  }
}

resource "aws_route_table" "sinatra_route_table" {
  vpc_id = aws_vpc.sinatra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sinatra_igw.id
  }

  tags = {
    Name = "sinatra-route-table"
  }
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.sinatra_subnet[count.index].id
  route_table_id = aws_route_table.sinatra_route_table.id
}

resource "aws_security_group" "sinatra_cluster_sg" {
  vpc_id = aws_vpc.sinatra_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sinatra-cluster-sg"
  }
}

resource "aws_security_group" "sinatra_node_sg" {
  vpc_id = aws_vpc.sinatra_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sinatra-node-sg"
  }
}

resource "aws_security_group" "sinatra_jump_sg" {
  name        = "sinatra-jump-sg"
  description = "Allow SSH and app ports for jump server"
  vpc_id      = aws_vpc.sinatra_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port 9000"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sinatra-jump-sg"
  }
}

resource "aws_instance" "sinatra_jump" {
  ami                    = "ami-04f167a56786e4b09" # Example Ubuntu 22.04 AMI for us-east-2, update as needed
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sinatra_subnet[0].id
  vpc_security_group_ids = [aws_security_group.sinatra_jump_sg.id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "sinatra-jump-server"
  }
}

resource "aws_eks_cluster" "sinatra" {
  name     = "sinatra-cluster"
  role_arn = aws_iam_role.sinatra_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.sinatra_subnet[*].id
    security_group_ids = [aws_security_group.sinatra_cluster_sg.id]
  }
}

resource "aws_eks_node_group" "sinatra" {
  cluster_name    = aws_eks_cluster.sinatra.name
  node_group_name = "sinatra-node-group"
  node_role_arn   = aws_iam_role.sinatra_node_group_role.arn
  subnet_ids      = aws_subnet.sinatra_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [aws_security_group.sinatra_node_sg.id]
  }
}

resource "aws_iam_role" "sinatra_cluster_role" {
  name = "sinatra-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sinatra_cluster_role_policy" {
  role       = aws_iam_role.sinatra_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "sinatra_node_group_role" {
  name = "sinatra-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sinatra_node_group_role_policy" {
  role       = aws_iam_role.sinatra_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "sinatra_node_group_cni_policy" {
  role       = aws_iam_role.sinatra_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "sinatra_node_group_registry_policy" {
  role       = aws_iam_role.sinatra_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}