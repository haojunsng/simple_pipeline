resource "aws_iam_role" "ecs_task_execution_role" {
  name = "role-name"

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

resource "aws_iam_role" "ecs_task_role" {
  name = "role-name-task"

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

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "gomu-ecs-cluster"
}

resource "aws_ecs_task_definition" "definition" {
  family                   = "gomu-task-definition"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<DEFINITION
[
  {
    "image": "${local.account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/${aws_ecr_repository.gomu_repo.name}:latest",
    "name": "gomu-gomu",
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region" : "${local.aws_region}",
                    "awslogs-group" : "${aws_cloudwatch_log_group.gomu_log_group.name}",
                    "awslogs-stream-prefix" : "gomu"
                }
    },
    "secrets": [
            {
                "name": "CLIENT_ID",
                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/client_id"
            },
            {
                "name": "CLIENT_SECRET",
                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/client_secret"
            },
            {
                "name": "REFRESH_TOKEN",
                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/refresh_token"
            },
            {
                "name": "AWS_ACCESS_KEY_ID",
                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/aws_access_key_id"
            },
            {
                "name": "AWS_SECRET_ACCESS_KEY",
                "valueFrom": "arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/aws_secret_access_key"
            }
    ],
    "environment": [
            {
                "name": "vpc_id",
                "value": "${local.vpc_id}"
            },
            {
                "name": "first_subnet_id",
                "value": "${local.first_subnet_id}"
            },
            {
                "name": "second_subnet_id",
                "value": "${local.second_subnet_id}"
            },
            {
                "name": "security_group_id",
                "value": "${local.security_group_id}"
            }
    ]
  }
]
DEFINITION
}
