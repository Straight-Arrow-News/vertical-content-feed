
resource "aws_ecr_repository" "san_vertical_content_feed_aer" {
  name                 = "san/vertical-content-feed"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }
}
