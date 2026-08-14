
# Get AWS account ID
data "aws_caller_identity" "current" {}

# Look up the Atlas network container (auto-created with the cluster)
data "mongodbatlas_network_containers" "atlas" {
  project_id    = var.atlas_project_id
  provider_name = "AWS"
}

# Select the container that matches the EKS region
locals {
  atlas_region_name = replace(upper(var.aws_region), "-", "_") # e.g. "us-east-2" → "US_EAST_2"
  atlas_container = [
    for c in data.mongodbatlas_network_containers.atlas.results
    : c if c.region_name == local.atlas_region_name
  ][0]
}

# Create the peering request on the Atlas side
resource "mongodbatlas_network_peering" "eks" {
  project_id             = var.atlas_project_id
  container_id           = local.atlas_container.id
  provider_name          = "AWS"
  accepter_region_name   = var.aws_region
  aws_account_id         = data.aws_caller_identity.current.account_id
  route_table_cidr_block = aws_vpc.eks_vpc.cidr_block
  vpc_id                 = aws_vpc.eks_vpc.id

  depends_on = [
    aws_vpc.eks_vpc,
    data.mongodbatlas_network_containers.atlas
  ]
}

# Accept the peering on the AWS side
resource "aws_vpc_peering_connection_accepter" "atlas" {
  vpc_peering_connection_id = mongodbatlas_network_peering.eks.connection_id
  auto_accept               = true

  tags = {
    Name = "${local.cluster_name}-atlas-peering"
  }

  depends_on = [
    mongodbatlas_network_peering.eks
  ]
}

# Enable DNS resolution so Atlas hostnames resolve to private IPs
resource "aws_vpc_peering_connection_options" "atlas" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.atlas.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [
    aws_vpc_peering_connection_accepter.atlas
  ]
}

# Route Atlas traffic through the peering connection
resource "aws_route" "atlas_peering" {
  route_table_id            = aws_route_table.rt.id
  destination_cidr_block    = local.atlas_container.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.eks.connection_id

  depends_on = [
    aws_vpc_peering_connection_accepter.atlas,
    aws_route_table.rt
  ]
}

# Allow EKS VPC CIDR in Atlas IP access list (used once private_srv is available)
resource "mongodbatlas_project_ip_access_list" "eks_vpc" {
  project_id = var.atlas_project_id
  cidr_block = aws_vpc.eks_vpc.cidr_block
  comment    = "EKS VPC peering"

  depends_on = [
    aws_vpc_peering_connection_accepter.atlas
  ]
}

# Allow EKS node security group in Atlas IP access list.
# Atlas verifies the originating IP belongs to an EC2 instance in this security
# group (via the VPC peering connection), so nodes can connect via the standard
# public endpoint without 0.0.0.0/0 — and without needing private_srv.
resource "mongodbatlas_project_ip_access_list" "eks_sg" {
  project_id         = var.atlas_project_id
  aws_security_group = aws_security_group.eks_sg.id
  comment            = "EKS node security group"

  depends_on = [
    aws_vpc_peering_connection_accepter.atlas
  ]
}

# Read the cluster connection strings to get private_srv.
data "mongodbatlas_advanced_cluster" "cluster" {
  project_id = var.atlas_project_id
  name       = var.atlas_cluster_name

  depends_on = [
    mongodbatlas_project_ip_access_list.eks_vpc
  ]
}
