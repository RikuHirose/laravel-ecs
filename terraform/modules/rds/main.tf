locals {
  name              = var.name
  sg_name           = "${var.name}-rds-sg"
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

# SecurityGroup Rule for mysql
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "mysql" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  # cidr_blocks = [var.vpc_cidr]
  # cidr_blocks = ["0.0.0.0/0"]

  # fargateのセキュリティグループのidを指定する
  source_security_group_id = var.fargate_security_group_id
}

# SecurityGroup Rule for basion
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "basion" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  # cidr_blocks = [var.vpc_cidr]
  # cidr_blocks = ["0.0.0.0/0"]

  # basionのセキュリティグループのidを指定する
  source_security_group_id = var.basion_security_group_id
}

resource "aws_db_subnet_group" "this" {
  name        = local.subnet_group_name
  description = local.subnet_group_name
  subnet_ids  = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = local.name

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  engine = "aurora-mysql"
  port   = "3306"

  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  final_snapshot_identifier = local.name
  skip_final_snapshot       = true
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = local.name
  cluster_identifier = aws_rds_cluster.this.id

  engine = "aurora-mysql"

  instance_class = "db.t3.small"
}
