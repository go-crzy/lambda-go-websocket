resource "aws_apigatewayv2_api" "websocket" {
  name                       = var.rx
  protocol_type              = "WEBSOCKET"
  description = "Websocket Gateway for ${var.rx}"
  route_selection_expression = "$request.body.action"

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

resource "aws_apigatewayv2_stage" "staging_websocket" {
  api_id      = aws_apigatewayv2_api.websocket.id
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

data "aws_iam_policy_document" "apigateway_rx" {
  statement {
    sid = "4"
    actions = [
      "execute-api:ManageConnections",
    ]
    resources = [
      "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.websocket.id}/${aws_apigatewayv2_stage.staging_websocket.name}/POST/@connections/*",
    ]
  }
}

resource "aws_iam_policy" "apigateway_rx" {
  name        = "apigateway_rx"
  path        = "/"
  description = "IAM policy interacting with API Gateway from a lambda"

  policy = data.aws_iam_policy_document.apigateway_rx.json
}

output wscat {
	value = "wscat --connect ${aws_apigatewayv2_stage.staging_websocket.invoke_url}"
}
