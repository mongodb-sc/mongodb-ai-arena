# Atlas accepts two kinds of credentials. Supply exactly one pair: either
# public_key/private_key (Programmatic API Key) or client_id/client_secret
# (Service Account, values prefixed with "mdb_sa").
variable "public_key" {
  description = "The public API key for MongoDB Atlas (Programmatic API Key authentication)"
  type        = string
  default     = ""

  validation {
    condition     = !contains(["public_key", "PUBLIC_KEY"], var.public_key)
    error_message = "❌ MongoDB Atlas public_key must be set in config.yaml. Replace 'PUBLIC_KEY' with your actual Atlas public API key."
  }
}

variable "private_key" {
  description = "The private API key for MongoDB Atlas (Programmatic API Key authentication)"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !contains(["private_key", "PRIVATE_KEY"], var.private_key)
    error_message = "❌ MongoDB Atlas private_key must be set in config.yaml. Replace 'PRIVATE_KEY' with your actual Atlas private API key."
  }
}

variable "client_id" {
  description = "The Service Account client id for MongoDB Atlas (starts with 'mdb_sa_id_')"
  type        = string
  default     = ""

  validation {
    condition     = !contains(["client_id", "CLIENT_ID"], var.client_id)
    error_message = "❌ MongoDB Atlas client_id must be set in config.yaml. Replace 'CLIENT_ID' with your actual Atlas Service Account client id."
  }

  validation {
    condition     = (var.public_key != "" && var.private_key != "") || (var.client_id != "" && var.client_secret != "")
    error_message = "❌ MongoDB Atlas credentials are incomplete in config.yaml. Set either mongodb.public_key + mongodb.private_key (Programmatic API Key) or mongodb.client_id + mongodb.client_secret (Service Account)."
  }
}

variable "client_secret" {
  description = "The Service Account client secret for MongoDB Atlas (starts with 'mdb_sa_sk_')"
  type        = string
  default     = ""
  sensitive   = true

  validation {
    condition     = !contains(["client_secret", "CLIENT_SECRET"], var.client_secret)
    error_message = "❌ MongoDB Atlas client_secret must be set in config.yaml. Replace 'CLIENT_SECRET' with your actual Atlas Service Account client secret."
  }
}

variable "project_name" {
  description = "The Atlas Project ID used to create the cluster"
  type        = string
  default     = "arena-customer"

  validation {
    condition     = var.project_name != "arena-customer" && var.project_name != "PROJECT_NAME" && length(var.project_name) > 0
    error_message = "❌ MongoDB Atlas project_name must be set in config.yaml. Replace 'PROJECT_NAME' with your actual Atlas project name."
  }
}

variable "cluster_name" {
  description = "The Atlas Project cluster name"
  type        = string
  default     = "arena"
}

variable "sample_database_name" {
  description = "Name of the sample database"
  type        = string
  default     = "sample_airbnb"
}

variable "common_database_name" {
  description = "Name of the sample database"
  type        = string
  default     = "arena_shared"
}

variable "cluster_region" {
  description = "The Atlas Project cluster region"
  type        = string
  default     = "US_EAST_2"
}

variable "cluster_type" {
  description = "The Atlas Project cluster type"
  type        = string
  default     = "REPLICASET"
}

variable "atlas_provider_name" {
  description = "The Atlas cloud provider name"
  type        = string
  default     = "AWS"
}

variable "atlas_provider_instance_size_name" {
  description = "The Atlas provider instance size name"
  type        = string
  default     = "M30"
}

variable "auto_scaling_disk_gb_enabled" {
  description = "auto scaling option"
  type        = bool
  default     = true
}

variable "atlas_provider_min_instance_size" {
  description = "The minimum Atlas provider instance size to auto-scale down to"
  type        = string
  default     = "M10"
}

variable "atlas_provider_max_instance_size" {
  description = "The maximum Atlas provider instance size to auto-scale up to"
  type        = string
  default     = "M80"
}

variable "mongo_db_major_version" {
  description = "the MongoDB Version"
  type        = string
  default     = "8.0"
}

variable "database_admin_password" {
  description = "MongoDB Atlas DB password"
  type        = string
  default     = "Mongo123/Admin"
}

variable "customer_user_password" {
  description = "MongoDB Customer DB password"
  type        = string
  default     = "Mongo123"
}

variable "user_list_path" {
  description = "Path to the User List CSV file"
  type        = string
  default     = "./user_list.csv"
  nullable    = true
}

variable "user_start_index" {
  description = "Starting index for additional database users (e.g., 1 means users start from clustername1, 10 means users start from clustername10)"
  type        = number
  default     = 0
}

variable "additional_users_count" {
  description = "Number of additional database users to create beyond those in the CSV file"
  type        = number
  default     = 0
}

variable "create_indexes" {
  description = "Whether to create indexes"
  type        = bool
  default     = false
}

variable "dedicated_project" {
  description = "Whether this is a dedicated MongoDB Atlas project. When true, the project is created and the maintenance window plus open IP access are enabled. When false, an existing project named var.project_name is used."
  type        = bool
  default     = false
}
