variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-04669a22aad391419"
}

variable "default_vpc" {
  type    = string
  default = "vpc-084e64897361d06e7"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "subnet-public1-us-west-1a" {
  default = "subnet-019315c7c7cd62cb2"
}

variable "subnet-public2-us-west-1b" {
  default = "subnet-0ac03fce498193d8b"
}