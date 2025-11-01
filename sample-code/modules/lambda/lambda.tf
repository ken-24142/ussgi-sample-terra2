# ====================================================
# Lambda
# ====================================================
## スナップショット取得Function用IAMロール
resource "aws_iam_role" "lambda_snapshot_role" {
  name               = "${var.prefix}-lambda-snapshot-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

## CloudWatch Logs書き込み権限とAuroraスナップショット取得権限を付与
resource "aws_iam_role_policy" "lambda_snapshot_policy" {
  name   = "${var.prefix}-lambda-snapshot-policy"
  role   = aws_iam_role.lambda_snapshot_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "rds:CreateDBClusterSnapshot",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots",
          "rds:AddTagsToResource"
        ],
        Resource = "*"
      }
    ]
  })
}

## srcディレクトリ下のzipファイルをLambda関数としてデプロイする
### スナップショット取得Function zipファイル指定の準備
data "archive_file" "snapshot" {
  type        = "zip"
  source_file = "${path.module}/src/snapshot.py"
  output_path = "${path.module}/src/snapshot.zip"
}
### スナップショット取得Function
resource "aws_lambda_function" "snapshot" {
  function_name     = "${var.prefix}-snapshot"
  runtime           = var.runtime
  handler           = "snapshot.lambda_handler"
  role              = aws_iam_role.lambda_snapshot_role.arn
  timeout           = 30

  filename          = data.archive_file.snapshot.output_path
  source_code_hash  = data.archive_file.snapshot.output_base64sha256

  environment {
    variables = {
      DB_CLUSTER_IDENTIFIER = var.db_cluster_identifier
    }
  }

  depends_on        = [aws_iam_role_policy.lambda_snapshot_policy]
}

## 定期的に関数を実行するために、EventBridgeルールを作成
### IAMロールとポリシー
resource "aws_iam_role" "lambda_event_role" {
  name               = "${var.prefix}-lambda-event-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_event_policy" {
  name   = "${var.prefix}-lambda-event-policy"
  role   = aws_iam_role.lambda_event_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "*"
      }
    ]
  })
}

### EventBridgeルール、ターゲット
resource "aws_cloudwatch_event_rule" "lambda_snapshot_rule" {
  name                = "${var.prefix}-lambda-snapshot-rule"
  description         = "for Lambda function make snapshot"
  schedule_expression = var.snapshot_schedule
}

resource "aws_cloudwatch_event_target" "lambda_snapshot_target" {
  rule      = aws_cloudwatch_event_rule.lambda_snapshot_rule.name
  arn       = aws_lambda_function.snapshot.arn
  input     = jsonencode({})
  role_arn  = aws_iam_role.lambda_event_role.arn

  retry_policy {
    maximum_event_age_in_seconds = var.maximum_event_age_in_seconds
    maximum_retry_attempts       = var.maximum_retry_attempts
  }

  depends_on = [aws_lambda_function.snapshot]
}