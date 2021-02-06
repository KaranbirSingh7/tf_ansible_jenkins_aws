terraform {
  required_version = ">= 0.12"
  backend "s3" {
    region  = "us-east-1"
    bucket  = "terraformstatebucket67"
    profile = "default"
    key     = "terraformstatefile"
  }

}
