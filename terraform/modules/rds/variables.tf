variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {}

variable "vpc_cidr" {
  type = string
}

variable "fargate_security_group_id" {
  type = string
}

variable "basion_security_group_id" {
  type = string
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}