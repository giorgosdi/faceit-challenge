variable "namespaces" {
  default = ["flux-system", "test", "monitoring"]
  type = set(string)
}

variable "cluster_name" {
  default = "faceit"
  type = string
}

variable "cluster_version" {
  default = "1.22"
  type = string
}

variable "ebs_kms_key" {
  type = string
}

variable "instance_type" {
  default = "m5.large"
  type = string
}

variable "asg_min_size" {
  default = 1
  type = number
}

variable "asg_max_size" {
  default = 5
  type = number
}

variable "asg_desired_size" {
  default = 2
  type = number
}

variable "engine" {
  default = "postgres"
  type = string
}

variable "engine_version" {
  default = "14.1"
  type = string
}

variable "family" {
  default = "postgres14"
  type = string
}

variable "major_engine_version" {
  default = "14"
  type = string
}

variable "instance_class" {
  default = "db.t4g.large"
  type = string
}

variable "allocated_storage" {
  default = 20
  type = number
}


variable "max_allocated_storage" {
  default = 100
  type = number
}


variable "port" {
  default = 5432
  type = number
}


variable "vpc_cidr_block" {
  default = "100.64.0.0/16"
  type = string
}

variable "multi_az" {
  default = false
  type = bool
}

variable "db_name" {
  default = "replicaPostgresql"
  type = string
}

variable "db_username" {
  default = "replica_postgresql"
  type = string
}


variable "parameter_path_dbpass" {
  default = "/giorgos/postgres/database/master_password"
  type = string
}


variable "parameter_path_dbendpoint" {
  default = "/giorgos/postgres/database/endpoint"
  type = string
}


variable "parameter_path_dbname" {
  default = "/giorgos/postgres/database/name"
  type = string
}


variable "parameter_path_dbusername" {
  default = "/giorgos/postgres/database/username"
  type = string
}

variable "flux_sync_repo" {
  type = string
}


variable "flux_sync_branch" {
  default = "main"
  type = string
}

variable "flux_sync_pull_interval" {
  default = "1m"
  type = string
}

variable "flux_sync_apply_interval" {
  default = "1m"
  type = string
}

variable "eso_scoped_namespace" {
  default = "test"
  type = string
}

variable "ca_max_size" {
  default = "10"
  type = string
}

variable "ca_min_size" {
  default = "2"
  type = string
}
