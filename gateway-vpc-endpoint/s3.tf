resource "random_string" "suffix" {
  length    = 16
  min_lower = 16
  special   = false
}

resource "aws_s3_bucket" "sample" {
  bucket = "my-sample-s3-bucket-${random_string.suffix.result}"
  acl    = "private"
}
