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

resource "aws_s3_bucket" "san_vertical_content_feed_asb" {
  bucket = "san-vertical-content-${var.environment}-${random_uuid.random_uuid.result}"
}

resource "aws_s3_bucket_public_access_block" "san_vertical_content_feed_asbpab" {
  bucket = aws_s3_bucket.san_vertical_content_feed_asb.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_lifecycle_configuration" "san_vertical_content_feed_asblc" {
  bucket = aws_s3_bucket.san_vertical_content_feed_asb.id

  rule {
    id     = "delete-after-30-days"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "san_vertical_content_feed_asbp" {
  bucket = aws_s3_bucket.san_vertical_content_feed_asb.id

  depends_on = [aws_s3_bucket_public_access_block.san_vertical_content_feed_asbpab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.san_vertical_content_feed_asb.arn}/*"
      }
    ]
  })
}

resource "aws_dynamodb_table" "san_vertical_content_feed_adt" {
  name         = "san_vertical_content_feed_${var.environment}_adt"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "sent_time"

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
    Name = "Vertical Content Feed Table"
  }
}
