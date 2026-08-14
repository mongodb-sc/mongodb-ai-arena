
data "aws_availability_zones" "available" {
  state = "available"

  dynamic "filter" {
    for_each = var.aws_region == "us-west-2" ? [1] : []
    content {
      name   = "zone-name"
      values = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
    }
  }
}

# VPC Configuration
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.cluster_name}-eks-vpc"
  }

}

resource "aws_subnet" "eks_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  # Two /22 subnets carved from the front of the VPC range, regardless of the
  # VPC prefix size (e.g. 10.0.0.0/16 -> 10.0.0.0/22 and 10.0.4.0/22).
  cidr_block              = cidrsubnet(var.vpc_cidr, 22 - tonumber(split("/", var.vpc_cidr)[1]), count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.cluster_name}-eks-subnet-${count.index}"
    "kubernetes.io/role/elb" = "1"
  }

  depends_on = [ 
    aws_vpc.eks_vpc 
  ]
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${local.cluster_name}-eks-igw"
  }

  depends_on = [ 
    aws_vpc.eks_vpc 
  ]
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${local.cluster_name}-eks-public-rt"
  }

  # Routes are managed by separate aws_route resources (e.g. aws_route.igw,
  # aws_route.atlas_peering). Mixing inline route blocks with standalone
  # aws_route resources causes route churn on every apply.
  lifecycle {
    ignore_changes = [route]
  }

  depends_on = [
    aws_vpc.eks_vpc,
    aws_internet_gateway.eks_igw
  ]
}

# Default route to the Internet Gateway (managed as a standalone resource so it
# can coexist with aws_route.atlas_peering on the same route table).
resource "aws_route" "igw" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id

  depends_on = [
    aws_route_table.rt,
    aws_internet_gateway.eks_igw
  ]
}

resource "aws_route_table_association" "rt_assoc" {
  count = 2
  subnet_id      = element(aws_subnet.eks_subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id

  depends_on = [ 
    aws_route_table.rt,
    aws_subnet.eks_subnet
  ]
}

# Create security groups
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.eks_vpc.id

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 53
    to_port     = 53
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
    Name = "${local.cluster_name}-eks-sg"
  }

  depends_on = [ 
    aws_vpc.eks_vpc 
  ]
}
