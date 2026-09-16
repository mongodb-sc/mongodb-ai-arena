terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      # 2.12 is the floor for Service Account (client_id/client_secret) auth.
      version = "~> 2.12"
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

locals {
  # Atlas authenticates either with a Programmatic API Key (public/private key)
  # or with a Service Account (client id/secret, values prefixed "mdb_sa").
  # Service Account values left in the public/private key inputs are picked up
  # too, since the provider rejects them there.
  atlas_use_service_account = var.atlas_client_id != "" || startswith(var.atlas_public_key, "mdb_sa")

  atlas_credential_id     = local.atlas_use_service_account && var.atlas_client_id != "" ? var.atlas_client_id : var.atlas_public_key
  atlas_credential_secret = local.atlas_use_service_account && var.atlas_client_secret != "" ? var.atlas_client_secret : var.atlas_private_key
}

provider "mongodbatlas" {
  public_key    = local.atlas_use_service_account ? null : local.atlas_credential_id
  private_key   = local.atlas_use_service_account ? null : local.atlas_credential_secret
  client_id     = local.atlas_use_service_account ? local.atlas_credential_id : null
  client_secret = local.atlas_use_service_account ? local.atlas_credential_secret : null
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
