resource "aws_security_group" "lambda" {
  name        = "log-retention-lambda-sg"
  description = "Security group for log retention Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Account     = "prod-us-east-1"
    Service     = "log-retention"
  }
}

resource "aws_lambda_function" "log_retention" {
  filename         = data.archive_file.log_retention.output_path
  function_name    = "log-retention"
  role             = aws_iam_role.log_retention.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300  # 5 minutes
  memory_size      = 256

  environment {
    variables = {
      PG_URL           = "postgresql://${var.postgres_username}:${var.postgres_password}@${var.postgres_host}:${var.postgres_port}/postgres"
      CLICKHOUSE_HOST  = var.clickhouse_host
      CLICKHOUSE_PORT  = var.clickhouse_port
      CLICKHOUSE_USER  = var.clickhouse_user
      CLICKHOUSE_PASSWORD = var.clickhouse_password
      CLICKHOUSE_DB    = var.clickhouse_db
      OBJECT_ID        = var.object_id
      OLDER_THAN_DAYS  = var.older_than_days
      TARGET_RECORDS   = var.target_records
      ITERATIONS       = var.iterations
    }
  }

  vpc_config {
    subnet_ids         = [
      var.main_vpc_private_subnet_1_id,
      var.main_vpc_private_subnet_2_id,
      var.main_vpc_private_subnet_3_id
    ]
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Environment = "production"
    Account     = "prod-us-east-1"
    Service     = "log-retention"
  }
}

data "archive_file" "log_retention" {
  type        = "zip"
  output_path = "${path.module}/log_retention.zip"
  source {
    content  = file("${path.module}/log_retention.py")
    filename = "log_retention.py"
  }
}

resource "aws_iam_role" "log_retention" {
  name = "log_retention_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
} 