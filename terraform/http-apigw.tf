resource "aws_apigatewayv2_api" "http" {
  name                       = var.http
  protocol_type              = "HTTP"
  description = "HTTP Gateway for ${var.http}"
  route_selection_expression = "$request.method $request.path"

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

resource "aws_apigatewayv2_route" "http" {
  api_id           = aws_apigatewayv2_api.http.id
  route_key        = "ANY /"
  target = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_stage" "staging-http" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "staging"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_http" {
  statement_id  = "AllowHTTPFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*/"
}

output curl {
	value = "curl -XPOST -d'message' ${aws_apigatewayv2_stage.staging-http.invoke_url}/"
}