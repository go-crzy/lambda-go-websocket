data "archive_file" "ws_zip" {
  type        = "zip"
  source_file = "bin/${var.rx_artifact}"
  output_path = "package/${var.rx_artifact}.zip"
}

resource "aws_lambda_function" "websocket" {
  function_name    = var.rx
  filename         = "package/ws-linux-amd64.zip"
  handler          = "ws-linux-amd64"
  source_code_hash = data.archive_file.ws_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda_websocket.arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      LAMDBA_TABLE = var.lambda_table
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs_websocket,
  ]
}

resource "aws_iam_role" "iam_for_lambda_websocket" {
  name = "iam_for_lambda_${var.rx}"

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
  name              = "/aws/lambda/${var.rx}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_logging_websocket" {
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

resource "aws_iam_policy" "lambda_logging_websocket" {
  name        = "lambda_logging_${var.rx}"
  path        = "/"
  description = "IAM policy for lambda ${var.rx} logging"

  policy = data.aws_iam_policy_document.lambda_logging_websocket.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs_websocket" {
  role       = aws_iam_role.iam_for_lambda_websocket.name
  policy_arn = aws_iam_policy.lambda_logging_websocket.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_websocket" {
  role       = aws_iam_role.iam_for_lambda_websocket.name
  policy_arn = aws_iam_policy.lambda_dynamo.arn
}

resource "aws_iam_role_policy_attachment" "lambda_apigateway_websocket" {
  role       = aws_iam_role.iam_for_lambda_websocket.name
  policy_arn = aws_iam_policy.apigateway_rx.arn
}

