terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.12.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      environment = var.environment
    }
  }
}

resource "random_uuid" "random_uuid" {
}

# S3 Bucket for storing videos
resource "aws_s3_bucket" "videos" {
  bucket = "${var.s3_bucket_name}-${random_uuid.random_uuid.result}"
}

# S3 Bucket Public Access Block - Allow public access
resource "aws_s3_bucket_public_access_block" "videos" {
  bucket = aws_s3_bucket.videos.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Lifecycle Configuration - Delete objects after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "videos" {
  bucket = aws_s3_bucket.videos.id

  rule {
    id     = "delete-after-30-days"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# S3 Bucket Policy - Allow public read access
resource "aws_s3_bucket_policy" "videos" {
  bucket = aws_s3_bucket.videos.id

  depends_on = [aws_s3_bucket_public_access_block.videos]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.videos.arn}/*"
      }
    ]
  })
}

# DynamoDB Table for storing video metadata
resource "aws_dynamodb_table" "videos" {
  name         = var.videos_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "sent_time"
    type = "N"
  }
  attribute {
    name = "feed_type"
    type = "S"
  }

  global_secondary_index {
    name            = "FeedTypeTimestampIndex"
    hash_key        = "feed_type"
    range_key       = "sent_time"
    projection_type = "ALL"
  }

  tags = {
    Name = "Videos Table"
  }
}
