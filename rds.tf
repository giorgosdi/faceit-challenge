module "master" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-rds.git"

  identifier = local.rds_name

  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  port     = var.port

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.id
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  storage_encrypted       = true
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.rds_sec_group_name
  description = "Replica PostgreSQL example security group"
  vpc_id      = local.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = local.vpc_cidr_block
    },
  ]
}

module "dbpass" {
  source  = "git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  parameter_write = [
    {
      name        = var.parameter_path_dbpass
      value       = module.master.db_instance_password
      type        = "String"
      overwrite   = "true"
    }
  ]

}

module "dbendpoint" {
  source  = "git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  parameter_write = [
    {
      name        = var.parameter_path_dbendpoint
      value       = split(":", module.master.db_instance_endpoint)[0]
      type        = "String"
      overwrite   = "true"
    }
  ]
}


module "dbname" {
  source  = "git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  parameter_write = [
    {
      name        = var.parameter_path_dbname
      value       = module.master.db_instance_name
      type        = "String"
      overwrite   = "true"
    }
  ]
}

module "dbusername" {
  source  = "git@github.com:cloudposse/terraform-aws-ssm-parameter-store.git"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  parameter_write = [
    {
      name        = var.parameter_path_dbusername
      value       = module.master.db_instance_username
      type        = "String"
      overwrite   = "true"
    }
  ]
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet_group"
  subnet_ids = module.vpc.private_subnets
}

