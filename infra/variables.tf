variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type    = string
  default = "videos"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "production_feed_url" {
  type    = string
  default = "https://example.com/feed.xml"
}

variable "zapier_secret_key" {
  type    = string
  default = "replace-with-actual-secret-key"
}

