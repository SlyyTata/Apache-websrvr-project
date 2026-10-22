variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "vpc_name" {
  description = "Apache VPC Name"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "pub_subnet1_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "pub_subnet2_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
}

variable "priv_subnet1_cidr" {
  description = "Cidr block for the private subnet"
  type        = string
}

variable "priv-subnet2_cidr" {
  description = "Cidr block for the private subnet"
  type        = string
}

variable "instance_name" {
  description = "Apache Webserver Name"
  type        = string
}

variable "instance_type" {
  description = "Apache Webserver Name"
  type        = string
}

variable "load_balancer_name" {
  description = "Apache Webserver Name"
  type        = string
}