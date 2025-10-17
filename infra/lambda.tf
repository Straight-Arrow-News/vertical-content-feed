resource "aws_iam_role" "san_vertical_content_feed_air" {
  name = "san_vertical_content_feed_${var.environment}_air"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "san_vertical_content_feed_airpa" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.san_vertical_content_feed_air.name
}

resource "aws_iam_role_policy" "san_vertical_content_airp_dynamodb" {
  name = "san_vertical_content_${var.environment}_airp_dynamodb"
  role = aws_iam_role.san_vertical_content_feed_air.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.san_vertical_content_feed_adt.arn,
          "${aws_dynamodb_table.san_vertical_content_feed_adt.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "san_vertical_content_airp_s3" {
  name = "san_vertical_content_${var.environment}_airp_s3"
  role = aws_iam_role.san_vertical_content_feed_air.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.san_vertical_content_feed_asb.arn,
          "${aws_s3_bucket.san_vertical_content_feed_asb.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "san_vertical_content_alf" {
  function_name = "san_vertical_content_${var.environment}_alf"
  role          = aws_iam_role.san_vertical_content_feed_air.arn
  description   = "Function powering the vertical content feed from TikTok"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.san_vertical_content_feed_aer.repository_url}:latest"

  timeout     = 60
  memory_size = 2048
  environment {
    variables = {
      REGION_AWS                  = var.aws_region
      VIDEOS_TABLE_NAME           = aws_dynamodb_table.san_vertical_content_feed_adt.name
      S3_BUCKET_NAME              = aws_s3_bucket.san_vertical_content_feed_asb.id
      FEED_URL                    = var.feed_url
      ZAPIER_SECRET_KEY           = var.zapier_secret_key
      OTEL_DEPLOYMENT_ENVIRONMENT = var.environment
      OTEL_EXPORTER_OTLP_ENDPOINT = var.otel_exporter_otlp_endpoint
      GRAFANA_LABS_TOKEN          = var.grafana_labs_token
    }
  }

  depends_on = [
    aws_ecr_repository.san_vertical_content_feed_aer,
    aws_iam_role_policy_attachment.san_vertical_content_feed_airpa,
    aws_iam_role_policy.san_vertical_content_airp_dynamodb,
    aws_iam_role_policy.san_vertical_content_airp_s3
  ]

  lifecycle {
    ignore_changes = [image_uri]
  }
}

resource "aws_cloudwatch_log_group" "san_vertical_content_aclg" {
  name              = "/aws/lambda/${aws_lambda_function.san_vertical_content_alf.function_name}"
  retention_in_days = 14
}
