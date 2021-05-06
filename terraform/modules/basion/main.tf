locals {
  name              = var.name
  sg_name           = "${var.name}-basion-sg"
  instance_name     = "${var.name}-basion-instance"
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

# SecurityGroup Rule
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group_rule" "this" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  # cidr_blocks = [var.vpc_cidr]
  cidr_blocks = ["0.0.0.0/0"]
}

# EC2
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "this" {
  ami           = data.aws_ami.amazon_linux_2.id # <-----ローカル変数image_idの値をアクセス
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.this.id]

  tags = {
    terraform = "true"
    Name = local.instance_name
  }
}