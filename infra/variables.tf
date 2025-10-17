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

variable "feed_url" {
  type = string
}

variable "zapier_secret_key" {
  type = string
}

variable "otel_exporter_otlp_endpoint" {
  type = string
}

variable "grafana_labs_token" {
  type = string
}
