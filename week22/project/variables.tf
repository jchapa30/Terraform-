variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2"
  type        = string
  default     = "ami-0ca23709ed2a0fdf9"
}

variable "vpc_name" {
  description = "Name for Custom VPC"
  type        = string
  default     = "apache_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "us-az-west-1a" {
  description = "First AZ for public and private subnets"
  type        = string
  default     = "us-west-1a"
}

variable "us-az-west-1b" {
  description = "Second AZ for public and private subnets"
  type        = string
  default     = "us-west-1b"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  default     = "dbpassword"
  sensitive   = true
}