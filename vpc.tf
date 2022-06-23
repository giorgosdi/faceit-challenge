module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git"

  name = "giorgos-test"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6 = false
  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "public"
    "kubernetes.io/cluster/faceit-faceit" = "shared"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    Name = "private"
    "kubernetes.io/cluster/faceit-faceit" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }

  vpc_tags = {
    Name = "giorgos-test"
  }
}
