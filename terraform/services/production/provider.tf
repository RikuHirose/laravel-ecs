###############
## Provider ##
###############
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = var.aws_profile
}

// backendセクションを追加
terraform {
  backend "s3" {
    bucket  = "xroomes-production-terraform-state-bucket"
    region  = "ap-northeast-1"
    profile = "xrooms"
    key     = "terraform.tfstate"
    encrypt = true
  }
}

