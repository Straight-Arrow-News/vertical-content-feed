# IAM role for Lambda execution
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

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "san_vertical_content_feed_airpa" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.san_vertical_content_feed_air.name
}

# Policy for DynamoDB access
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

# Policy for S3 access
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

# Lambda function using ECR image
resource "aws_lambda_function" "san_vertical_content_alf" {
  function_name = "san_vertical_content_${var.environment}_alf"
  role          = aws_iam_role.san_vertical_content_feed_air.arn

  # Docker image configuration
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.san_vertical_content_feed_aer.repository_url}:latest"

  # Function configuration
  timeout     = 60
  memory_size = 2048

  # Environment variables
  environment {
    variables = {
      REGION_AWS        = var.aws_region
      VIDEOS_TABLE_NAME = aws_dynamodb_table.san_vertical_content_feed_adt.name
      S3_BUCKET_NAME    = aws_s3_bucket.san_vertical_content_feed_asb.id
      FEED_URL          = "https://example.com/feed.xml"
      ZAPIER_SECRET_KEY = "replace-with-actual-secret-key"
    }
  }

  # Ensure the ECR repository exists before creating the function
  depends_on = [
    aws_ecr_repository.san_vertical_content_feed_aer,
    aws_iam_role_policy_attachment.san_vertical_content_feed_airpa,
    aws_iam_role_policy.san_vertical_content_airp_dynamodb,
    aws_iam_role_policy.san_vertical_content_airp_s3
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "san_vertical_content_aclg" {
  name              = "/aws/lambda/${aws_lambda_function.san_vertical_content_alf.function_name}"
  retention_in_days = 14
}
