locals {
  sg_name           = "${var.name}-elasticache-sg"
  subnet_group_name = "${var.name}-db-subnet-group"
}

resource "aws_security_group" "this" {
  name        = local.sg_name
  description = local.sg_name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.sg_name
  }
}

# SecurityGroup Rule for elasticache
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "elasticache" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"

  # fargateのセキュリティグループのidを指定する
  source_security_group_id = var.fargate_security_group_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group
resource "aws_elasticache_subnet_group" "this" {
  name        = local.subnet_group_name
  description = local.subnet_group_name
  subnet_ids  = var.subnet_ids
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group
# https://blog.manabusakai.com/2020/03/elasticache-for-redis-with-terraform/
resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = var.redis_name
  replication_group_description = var.redis_name
  node_type                     = "cache.t3.micro"
  number_cache_clusters         = 3
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  engine_version                = "5.0.6"
  parameter_group_name          = "default.redis5.0"
  port                          = 6379

  subnet_group_name   = aws_elasticache_subnet_group.this.name
  security_group_ids  = [aws_security_group.this.id]
}

output "endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}
