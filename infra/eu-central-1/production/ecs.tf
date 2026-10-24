resource "aws_ecs_cluster" "dbt_cluster" {
  name = "achs-data-cluster"
}

resource "aws_cloudwatch_log_group" "dbt" {
  name              = "/ecs/achs-dbt"
  retention_in_days = 30
}

# IAM Role for ECS Task Execution (Allows ECS to pull from ECR and read SSM)
resource "aws_iam_role" "ecs_execution_role" {
  name = "achs_ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach AWS managed policy for basic ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy to specifically allow reading the SSM parameters
resource "aws_iam_role_policy" "ssm_read_policy" {
  name = "achs_ssm_read_policy"
  role = aws_iam_role.ecs_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["ssm:GetParameters", "ssm:GetParameter"]
      Effect = "Allow"
      Resource = [
        aws_ssm_parameter.snowflake_ecs_dbt_user.arn,
        aws_ssm_parameter.snowflake_ecs_dbt_private_key.arn
      ]
    }]
  })
}

# ECS Task Definition for running dbt on Fargate
resource "aws_ecs_task_definition" "dbt_task" {
  family                   = "achs-dbt-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024 # 1 vCPU
  memory                   = 2048 # 2 GB
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "dbt-container"
      image     = "${aws_ecr_repository.achs_dbt_repo.repository_url}:latest"
      essential = true
      secrets = [
        {
          name      = "SNOWFLAKE_USER"
          valueFrom = aws_ssm_parameter.snowflake_ecs_dbt_user.arn
        },
        {
          name      = "SNOWFLAKE_PRIVATE_KEY"
          valueFrom = aws_ssm_parameter.snowflake_ecs_dbt_private_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dbt.name
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "dbt"
        }
      }
    }
  ])
}


resource "aws_vpc_security_group_egress_rule" "ecs_all_out" {
  security_group_id = "sg-0b65fc4de73b84f1a"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}