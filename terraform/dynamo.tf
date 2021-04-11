resource "aws_dynamodb_table" "websocket" {
  name           = var.lambda_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ConnectionID"

  attribute {
    name = "ConnectionID"
    type = "S"
  }

  attribute {
	  name = "ChannelID"
	  type = "S"
  }

  global_secondary_index {
    name               = "${var.lambda_table}ChannelIndex"
    hash_key           = "ChannelID"
    projection_type    = "INCLUDE"
    non_key_attributes = ["RequestTimeEpoch", "ConnectionID", "Endpoint"]
  }

  tags = {
    Name        = var.lambda_table
    Environment = "production"
  }
}

data "aws_iam_policy_document" "lambda_dynamo" {
  statement {
    sid = "2"
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      "dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem",
    ]
    resources = [
      aws_dynamodb_table.websocket.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_dynamo" {
  name        = "lambda_dynamo"
  path        = "/"
  description = "IAM policy to interact with dynamodb a lambda"

  policy = data.aws_iam_policy_document.lambda_dynamo.json
}
