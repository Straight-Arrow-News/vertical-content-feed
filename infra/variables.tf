variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for storing videos"
  default     = "videos"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "videos_table_name" {
  type        = string
  description = "Name of the DynamoDB table for storing video metadata"
  default     = "videos"
}

