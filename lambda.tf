data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "archive_file" "ws_zip" {
  type        = "zip"
  source_file = "bin/ws-linux-amd64"
  output_path = "package/ws-linux-amd64.zip"
}

data "archive_file" "http_zip" {
  type        = "zip"
  source_file = "bin/http-linux-amd64"
  output_path = "package/http-linux-amd64.zip"
}

resource "aws_lambda_function" "websocket" {
  function_name    = "websocket"
  filename         = "package/ws-linux-amd64.zip"
  handler          = "ws-linux-amd64"
  source_code_hash = data.archive_file.ws_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      LAMDBA_TABLE = var.lambda_table
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}

resource "aws_lambda_function" "http" {
  function_name    = "http"
  filename         = "package/http-linux-amd64.zip"
  handler          = "http-linux-amd64"
  source_code_hash = data.archive_file.http_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      LAMDBA_TABLE = var.lambda_table
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "websocket" {
  name              = "/aws/lambda/${aws_lambda_function.websocket.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "http" {
  name              = "/aws/lambda/${aws_lambda_function.http.function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    sid = "1"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_dynamo.arn
}

resource "aws_iam_role_policy_attachment" "lambda_apigateway" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_apigateway.arn
}
