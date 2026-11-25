provider "aws" {
  region     = "var.aws_region"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  s3_use_path_style = true

  endpoints {
    dynamodb = "http://127.0.0.1:4566"
    ec2      = "http://127.0.0.1:4566"
    iam      = "http://127.0.0.1:4566"
    s3       = "http://127.0.0.1:4566"
    elb      = "http://127.0.0.1:4566"
    sts      = "http://127.0.0.1:4566"
    sqs      = "http://localhost:4566"
  }

  default_tags {
    tags = local.common_tags
  }
}