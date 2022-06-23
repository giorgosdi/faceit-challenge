locals {
  region = "eu-west-2"
  cluster_version = "1.22"
  name            = "faceit"


  cluster_name = format("%s-%s", local.name, var.cluster_name)
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  eks_sec_group_name = format("%s-%s", local.name, "eks")
  vpc_cidr_block = module.vpc.vpc_cidr_block
  rds_sec_group_name = format("%s-%s", local.name, "rds-sec-group")
  rds_name = format("%s-%s-master", local.name, "rds")
}
