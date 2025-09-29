resource "aws_apigatewayv2_api" "san_vertical_content_feed_aaa" {
  name          = "san_vertical_content_feed_${var.environment}_aaa"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "san_vertical_content_feed_aas" {
  api_id = aws_apigatewayv2_api.san_vertical_content_feed_aaa.id

  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.san_vertical_content_feed_aclg_gateway.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "san_vertical_content_feed_aai" {
  api_id = aws_apigatewayv2_api.san_vertical_content_feed_aaa.id

  integration_uri    = aws_lambda_function.vertical_content_feed.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "san_vertical_content_feed_aar" {
  api_id = aws_apigatewayv2_api.san_vertical_content_feed_aaa.id

  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.san_vertical_content_feed_aai.id}"
}

resource "aws_cloudwatch_log_group" "san_vertical_content_feed_aclg_gateway" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.san_vertical_content_feed_aaa.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "san_imagetool_alp" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vertical_content_feed.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.san_vertical_content_feed_aaa.execution_arn}/*/*"
}
