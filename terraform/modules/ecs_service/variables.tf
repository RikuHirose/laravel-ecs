variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {}

variable "https_listener_arn" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "subnet_ids" {}

variable "container_definitions" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}