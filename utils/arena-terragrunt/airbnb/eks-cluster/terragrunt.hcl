include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "atlas" {
  config_path = "../atlas-cluster"

  mock_outputs = {
    standard_srv  = "mongodb+srv://mongodb-arena.abcdef.mongodb.net"
    user_list     = ["mockUserA","mockUserB"]
    user_password = "superSecret123"
    admin_user = "superSecret123"
    admin_password = "superSecret123"
    project_id = "mock-project-id-123"
  }
}

terraform {
  source = "../../../eks-cluster"
  include_in_copy = [
    "**/.helmignore",
    ".helmignore",
  ]
  exclude_from_copy = [
    ".terragrunt-source-manifest",
    "**/.terragrunt-source-manifest",
  ]

  # Clean up .terragrunt-source-manifest files that break Helm
  before_hook "cleanup_terragrunt_manifest" {
    commands = ["apply", "plan"]
    execute  = ["bash", "-c", "find . -name '.terragrunt-source-manifest' -type f -delete 2>/dev/null || true"]
  }
}

locals {
  config = include.root.locals.config

  # Optional override: when aws.vpc_cidr is absent from config.yaml the key is
  # left out of inputs entirely, so the eks-cluster module default applies.
  vpc_cidr_input = try(local.config.aws.vpc_cidr, null) == null ? {} : {
    vpc_cidr = local.config.aws.vpc_cidr
  }
}

inputs = merge(local.vpc_cidr_input, {
  atlas_standard_srv  = dependency.atlas.outputs.standard_srv
  atlas_user_list     = dependency.atlas.outputs.user_list
  atlas_user_password = dependency.atlas.outputs.user_password
  atlas_admin_user = dependency.atlas.outputs.admin_user
  atlas_admin_password = dependency.atlas.outputs.admin_password
  atlas_project_id   = dependency.atlas.outputs.project_id
  atlas_cluster_name = local.config.mongodb.cluster_name

  # Atlas takes either a Programmatic API Key pair or a Service Account pair,
  # so config.yaml only has to define the one it uses.
  atlas_public_key    = try(local.config.mongodb.public_key, "")
  atlas_private_key   = try(local.config.mongodb.private_key, "")
  atlas_client_id     = try(local.config.mongodb.client_id, "")
  atlas_client_secret = try(local.config.mongodb.client_secret, "")

  customer_name = local.config.customer.name
  domain_email = local.config.domain.email
  aws_region = local.config.aws.region
  aws_profile = local.config.aws.profile
  scenario_config = local.config.scenario
})
