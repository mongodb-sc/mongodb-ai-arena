terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 2.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.35.1"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.22"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

locals {
  atlas_standard_srv   = try(var.atlas_standard_srv, "")
  atlas_private_srv    = coalesce(try(data.mongodbatlas_advanced_cluster.cluster.connection_strings.private_srv, ""), local.atlas_standard_srv)
  atlas_user_list      = var.atlas_user_list
  atlas_user_password  = try(var.atlas_user_password, "")
  atlas_admin_user     = try(var.atlas_admin_user, "")
  atlas_admin_password = try(var.atlas_admin_password, "")

  cluster_name = "${lower(var.customer_name)}-arena-eks"
  aws_route53_record_name = "${lower(var.customer_name)}.${trimsuffix(var.aws_route53_hosted_zone, ".")}"
  current_timestamp = timestamp()
  expire_timestamp  = formatdate("YYYY-MM-DD", timeadd(local.current_timestamp, "168h"))
  domain_user = split("@", var.domain_email)[0]
}

output "aws_route53_record_name" {
  value = local.aws_route53_record_name
}

output "debug_atlas_private_srv" {
  value = local.atlas_private_srv
}
