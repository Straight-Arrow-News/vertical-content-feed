# IAM role for Lambda execution
resource "aws_iam_role" "lambda_execution" {
  name = "vertical-content-feed-lambda-role"

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
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution.name
}

# Policy for DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "vertical-content-feed-lambda-dynamodb"
  role = aws_iam_role.lambda_execution.id

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
          aws_dynamodb_table.videos.arn,
          "${aws_dynamodb_table.videos.arn}/*"
        ]
      }
    ]
  })
}

# Policy for S3 access
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "vertical-content-feed-lambda-s3"
  role = aws_iam_role.lambda_execution.id

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
          aws_s3_bucket.videos.arn,
          "${aws_s3_bucket.videos.arn}/*"
        ]
      }
    ]
  })
}

# Lambda function using ECR image
resource "aws_lambda_function" "vertical_content_feed" {
  function_name = "vertical-content-feed"
  role          = aws_iam_role.lambda_execution.arn

  # Docker image configuration
  package_type = "Image"
  image_uri    = "${aws_ecr_repository.san_vertical_content_feed_aer.repository_url}:latest"

  # Function configuration
  timeout     = 60
  memory_size = 512

  # Environment variables
  environment {
    variables = {
      REGION_AWS        = var.aws_region
      VIDEOS_TABLE_NAME = aws_dynamodb_table.videos.name
      S3_BUCKET_NAME    = aws_s3_bucket.videos.id
      FEED_URL          = "https://example.com/feed.xml"
      ZAPIER_SECRET_KEY = "replace-with-actual-secret-key"
    }
  }

  # Ensure the ECR repository exists before creating the function
  depends_on = [
    aws_ecr_repository.san_vertical_content_feed_aer,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.lambda_dynamodb_policy,
    aws_iam_role_policy.lambda_s3_policy
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.vertical_content_feed.function_name}"
  retention_in_days = 14
}
