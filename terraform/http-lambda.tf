data "archive_file" "http_zip" {
  type        = "zip"
  source_file = "bin/${var.http_artifact}"
  output_path = "package/${var.http_artifact}.zip"
}

resource "aws_lambda_function" "http" {
  function_name    = var.http
  filename         = "package/http-linux-amd64.zip"
  handler          = "http-linux-amd64"
  source_code_hash = data.archive_file.http_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda_http.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      LAMDBA_TABLE = var.lambda_table
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_http,
  ]
}

resource "aws_iam_role" "iam_for_lambda_http" {
  name = "iam_for_lambda_${var.http}"

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

resource "aws_cloudwatch_log_group" "http" {
  name              = "/aws/lambda/${var.http}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_logging_http" {
  statement {
    sid = "1"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
    ]

    resources = [
	  "arn:aws:logs:*:*:log-group:/aws/lambda/*",
    ]
  }

  statement {
    sid = "2"

    actions = [
      "logs:PutLogEvents",
    ]

    resources = [
	  "arn:aws:logs:*:*:log-group:/aws/lambda/*:log-stream:*",
    ]
  }
}

resource "aws_iam_policy" "lambda_logging_http" {
  name        = "lambda_logging_${var.http}"
  path        = "/"
  description = "IAM policy for lambda ${var.http} logging"

  policy = data.aws_iam_policy_document.lambda_logging_http.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs_http" {
  role       = aws_iam_role.iam_for_lambda_http.name
  policy_arn = aws_iam_policy.lambda_logging_http.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_http" {
  role       = aws_iam_role.iam_for_lambda_http.name
  policy_arn = aws_iam_policy.lambda_dynamo.arn
}

resource "aws_iam_role_policy_attachment" "lambda_apigateway_http" {
  role       = aws_iam_role.iam_for_lambda_http.name
  policy_arn = aws_iam_policy.apigateway_rx.arn
}

