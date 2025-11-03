# VPC for agent pool
module "vpc" {
  count = var.reuse_vpc_id == null ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "flows-agent-pool"
  cidr = "10.1.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group = false
  manage_default_route_table    = false
  manage_default_network_acl    = false

  tags = {
    Purpose = "Agent pool networking"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security group for agents
resource "aws_security_group" "agent_pool" {
  name        = "flows-agent-pool-sg"
  description = "Security group for Flows agent pool"
  vpc_id      = var.reuse_vpc_id == null ? module.vpc[0].vpc_id : var.reuse_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
