resource "random_pet" "this" {
  length = 2
}

module "simple_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.0.1"

  bucket = "simple-${terraform.workspace}-${random_pet.this.id}"

  force_destroy = true

  lifecycle_rule = [
    {
      id                                     = "lifecycle-rule-1"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
      ]

      noncurrent_version_expiration = {
        days = 300
      }
    }
  ]
}
