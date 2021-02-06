# create new VPC in master region
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "master-vpc-jenkins"
  }
}

# create new VPC in worker region
resource "aws_vpc" "vpc_worker" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "worker-vpc-jenkins"
  }
}

# create IGW in master
resource "aws_internet_gateway" "igw-master" {
  vpc_id   = aws_vpc.vpc_master.id
  provider = aws.region-master
}

# create IGW in worker
resource "aws_internet_gateway" "igw-worker" {
  vpc_id   = aws_vpc.vpc_worker.id
  provider = aws.region-worker
}

# get all AZs
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# create subnet-1 in any AZ in master region
resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = element(data.aws_availability_zones.azs.names, 0)

  tags = {
    Name = "master-jenkins-subnet-1"
  }
}

# create subnet-2 in any AZ in master region
resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = element(data.aws_availability_zones.azs.names, 1)

  tags = {
    Name = "master-jenkins-subnet-2"
  }
}

# create subnet-1 in any AZ in worker region
resource "aws_subnet" "subnet_worker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "worker-jenkins-subnet-1"
  }
}

# Initiate connection request from us-east-1
resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
}


# accept VPC peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept               = true
}

# create route table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-master.id
  }

  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "master-region-route-table"
  }
}

# change default route table in master region to use our new RT
resource "aws_main_route_table_association" "master" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# create route table in us-west-2
resource "aws_route_table" "internet_route_worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker.id
  }

  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "worker-region-route-table"
  }
}

# change default route table in worker region to use our new RT
resource "aws_main_route_table_association" "worker" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker.id
  route_table_id = aws_route_table.internet_route_worker.id
}