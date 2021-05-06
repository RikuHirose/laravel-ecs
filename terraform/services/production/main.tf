#########################
# VPC
#   VPC, PublicSubnet, PrivateSubnet, IGW, RouteTable, NAT GW
#########################
module "network" {
  source = "../../modules/network"

  name     = var.name
  azs      = var.azs
  acd      = var.acd
  vpc_cidr = var.vpc_cidr

  public_subnet_cidrs    = var.public_subnet_cidrs
  protected_subnet_cidrs = var.protected_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
}

# #########################
# # ACM
# #########################
# module "acm" {
#   source = "../../modules/acm"

#   name   = var.name
#   domain = var.domain
# }

# #########################
# # ACM for cloudfront
# #########################
# module "acm_for_cloudfront" {
#   source = "../../modules/acm_for_cloudfront"

#   route53_validation_record = module.acm.route53_validation_record

#   name      = var.name
#   domain    = var.domain
#   providers = {
#     aws = "aws.virginia"
#   }
# }

#########################
# ELB
#########################
module "elb" {
  source = "../../modules/elb"
  name   = var.name

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  domain            = var.domain
  acm_id            = var.acm_id_for_elb
}

#########################
# Cloudfront
#########################
module "cloudfront" {
  source = "../../modules/cloudfront"

  name         = var.name
  domain       = var.domain
  acm_id       = var.acm_id_for_cloudfront
  alb_dns_name = module.elb.alb_dns_name
}

#########################
# ECS
#########################
module "ecs_cluster" {
  source = "../../modules/ecs_cluster"

  name = var.name
}

data "aws_caller_identity" "current" {}

data "template_file" "container_definitions" {
  template = file("../../container_definitions.json")

  vars = {
    tag = "latest"

    name = var.name

    account_id = data.aws_caller_identity.current.account_id
    region     = var.aws_region

    db_host = module.rds.endpoint
    db_name = data.aws_ssm_parameter.db_name.value

    redis_host = module.elasticache.endpoint
  }
}

module "ecs_service" {
  source = "../../modules/ecs_service"

  name           = var.name
  vpc_cidr       = var.vpc_cidr
  # appからs3にfileをuploadするbucket
  s3_bucket_name = var.s3_bucket_name

  cluster_name          = module.ecs_cluster.cluster_name
  container_definitions = data.template_file.container_definitions.rendered

  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.protected_subnet_ids
  https_listener_arn    = module.elb.https_listener_arn
  alb_security_group_id = module.elb.alb_security_group_id
}

#########################
# Basion
#########################
module "basion" {
  source = "../../modules/basion"
  name   = var.name

  vpc_id            = module.network.vpc_id
  public_subnet_id  = module.network.public_subnet_id_a

  key_name = var.key_name
}

#########################
# RDS
#########################
data "aws_ssm_parameter" "db_name" {
  name = "/${var.name}/db/name"
}

data "aws_ssm_parameter" "db_username" {
  name = "/${var.name}/db/username"
}

data "aws_ssm_parameter" "db_password" {
  name = "/${var.name}/db/password"
}

module "rds" {
  source = "../../modules/rds"

  name = var.name

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  vpc_cidr   = var.vpc_cidr

  fargate_security_group_id = module.ecs_service.fargate_security_group_id
  basion_security_group_id  = module.basion.basion_security_group_id

  database_name   = data.aws_ssm_parameter.db_name.value
  master_username = data.aws_ssm_parameter.db_username.value
  master_password = data.aws_ssm_parameter.db_password.value
}

#########################
# ElastiCache for Redis (cluster mode disabled
#########################
data "aws_ssm_parameter" "redis_name" {
  name = "/${var.name}/redis/name"
}

module "elasticache" {
  source = "../../modules/elasticache"

  name = var.name

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
  redis_name = data.aws_ssm_parameter.redis_name.value

  fargate_security_group_id = module.ecs_service.fargate_security_group_id

}
