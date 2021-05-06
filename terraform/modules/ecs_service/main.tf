data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  # アカウントID
  account_id = data.aws_caller_identity.current.account_id

  # プロビジョニングを実行するリージョン
  region = data.aws_region.current.name

  # セキュリティグループの名前
  sg_name = "${var.name}-fargate-sg"
}

# ELB Target Group
# https://www.terraform.io/docs/providers/aws/r/lb_target_group.html
resource "aws_lb_target_group" "this" {
  name = var.name

  # ターゲットグループを作成するVPC
  vpc_id = var.vpc_id

  # ALBからECSタスクのコンテナへトラフィックを振り分ける設定
  port        = 80
  target_type = "ip"
  protocol    = "HTTP"

  # コンテナへの死活監視設定
  health_check {
    port = 80
  }
}

# Task Definition
# https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html
resource "aws_ecs_task_definition" "this" {
  family = var.name

  container_definitions = var.container_definitions

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu                      = "256"
  memory                   = "512"

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode             = "awsvpc"

  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]

  task_role_arn      = aws_iam_role.task_execution.arn
  execution_role_arn = aws_iam_role.task_execution.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/${var.name}/ecs"
  retention_in_days = "7"
}

resource "aws_iam_role" "task_execution" {
  name = "${var.name}-TaskExecution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task_execution" {
  role = aws_iam_role.task_execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:${local.region}:${local.account_id}:parameter/*",
        "arn:aws:secretsmanager:${local.region}:${local.account_id}:secret:*",
        "arn:aws:kms:${local.region}:${local.account_id}:key/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_exec" {
  role = aws_iam_role.task_execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3" {
  role = aws_iam_role.task_execution.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ALB Listener Rule
# https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html
resource "aws_lb_listener_rule" "this" {

  # ルールを追加するリスナー
  listener_arn = var.https_listener_arn

  # 受け取ったトラフィックをターゲットグループへ受け渡す
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  # ターゲットグループへ受け渡すトラフィックの条件
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# SecurityGroup
# https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "this" {
  name        = local.sg_name
  description = local.sg_name

  # セキュリティグループを配置するVPC
  vpc_id = var.vpc_id

  # セキュリティグループ内のリソースからインターネットへのアクセス許可設定
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
resource "aws_security_group_rule" "this_http" {
  security_group_id = aws_security_group.this.id

  # インターネットからセキュリティグループ内のリソースへのアクセス許可設定
  type = "ingress"

  # TCPでの80ポートへのアクセスを許可する
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  # 同一VPC内からのアクセスのみ許可
  # cidr_blocks = [var.vpc_cidr]
  # cidr_blocks = ["0.0.0.0/0"]

  # ALBのセキュリティグループのidを指定する
  source_security_group_id = var.alb_security_group_id
}

# ECS Service
# https://www.terraform.io/docs/providers/aws/r/ecs_service.html
resource "aws_ecs_service" "this" {
  name = var.name

  # 依存関係の記述。
  # "aws_lb_listener_rule.main" リソースの作成が完了するのを待ってから当該リソースの作成を開始する。
  # "depends_on" は "aws_ecs_service" リソース専用のプロパティではなく、Terraformのシンタックスのため他の"resource"でも使用可能
  depends_on = [aws_lb_listener_rule.this]

  # データプレーンとしてFargateを使用する
  launch_type = "FARGATE"

  # ECSタスクの起動数を定義
  desired_count = 1

  # 当該ECSサービスを配置するECSクラスターの指定
  cluster = var.cluster_name

  # 当該ECSサービスにてECS Execの機能を有効にする
  enable_execute_command = true

  # 起動するECSタスクのタスク定義
  task_definition = aws_ecs_task_definition.this.arn

  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    # タスクの起動を許可するサブネット
    subnets         = var.subnet_ids
    # タスクに紐付けるセキュリティグループ
    security_groups = [aws_security_group.this.id]
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "nginx"
    container_port   = "80"
  }
}

output "fargate_security_group_id" {
  value = aws_security_group.this.id
}
