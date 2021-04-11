resource "aws_apigatewayv2_api" "websocket" {
  name                       = "websocket"
  protocol_type              = "WEBSOCKET"
  description = "Websocket Gateway"
  route_selection_expression = "$request.body.action"

}

resource "aws_apigatewayv2_api" "http" {
  name                       = "http"
  protocol_type              = "HTTP"
  description = "HTTP Gateway"
  route_selection_expression = "$request.method $request.path"

}

resource "aws_apigatewayv2_integration" "websocket" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.websocket.invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}


resource "aws_apigatewayv2_integration" "http" {
  api_id           = aws_apigatewayv2_api.http.id
  integration_type = "AWS_PROXY"

  connection_type           = "INTERNET"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.http.invoke_arn
  payload_format_version    = "2.0"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id           = aws_apigatewayv2_api.websocket.id
  route_key        = "$connect"
  target = "integrations/${aws_apigatewayv2_integration.websocket.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id           = aws_apigatewayv2_api.websocket.id
  route_key        = "$disconnect"
  target = "integrations/${aws_apigatewayv2_integration.websocket.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id           = aws_apigatewayv2_api.websocket.id
  route_key        = "$default"
  target = "integrations/${aws_apigatewayv2_integration.websocket.id}"
}

resource "aws_apigatewayv2_route" "http" {
  api_id           = aws_apigatewayv2_api.http.id
  route_key        = "ANY /"
  target = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_stage" "staging-websocket" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "staging"
  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "staging-http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "staging"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_connect" {
  statement_id  = "AllowConnectFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "apigw_disconnect" {
  statement_id  = "AllowDisconnectFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$disconnect"
}

resource "aws_lambda_permission" "apigw_default" {
  statement_id  = "AllowDefaultFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.websocket.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/$default"
}

resource "aws_lambda_permission" "apigw_http" {
  statement_id  = "AllowHTTPFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*/"
}

data "aws_iam_policy_document" "lambda_apigateway" {
  statement {
    sid = "4"
    actions = [
      "execute-api:ManageConnections",
    ]
    resources = [
      "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.websocket.id}/${aws_apigatewayv2_stage.staging-websocket.name}/POST/@connections/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_apigateway" {
  name        = "lambda_apigateway"
  path        = "/"
  description = "IAM policy interacting with API Gateway from a lambda"

  policy = data.aws_iam_policy_document.lambda_apigateway.json
}

output wscat {
	value = "wscat --connect ${aws_apigatewayv2_stage.staging-websocket.invoke_url}"
}

output curl {
	value = "curl -XPOST -d'message' ${aws_apigatewayv2_stage.staging-http.invoke_url}/"
}