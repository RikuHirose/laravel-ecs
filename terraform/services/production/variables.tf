###############
## Variables ##
###############
variable "aws_region" {
  default = "ap-northeast-1"
}
variable "aws_profile" {}

variable "name" {
  type    = string
  default = "xrooms-production"
}

variable "key_name" {
  type    = string
  default = "xrooms"
}

variable "azs" {
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "acd" {
  default = ["a", "c", "d"]
}

variable "vpc_cidr" {
  default = "10.4.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.4.10.0/24", "10.4.11.0/24", "10.4.12.0/24"]
}

variable "protected_subnet_cidrs" {
  default = ["10.4.20.0/24", "10.4.21.0/24", "10.4.22.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.4.30.0/24", "10.4.31.0/24", "10.4.32.0/24"]
}

variable "domain" {
  type    = string
  default = "xrooms.jp"
}

variable "acm_id_for_cloudfront" {
  type    = string
}

variable "acm_id_for_elb" {
  type    = string
}

variable "s3_bucket_name" {
  type    = string
}
