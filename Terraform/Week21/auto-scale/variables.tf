variable "aws_region" {
  description = " Region of deployment"
  default     = "us-east-1"
}

variable "instance_type" {
  description = " EC2 instancetype"
  default     = "t2.micro"
}

variable "min_size" {
  description = "The minimum number of instances in the Auto Scaling group"
  default     = 2
}

variable "max_size" {
  description = "The maximum number of instances in the Auto Scaling group"
  default     = 5
}

variable "backend_bucket_name" {
  description = "The name of the S3 bucket to use as the backend for storing Terraform state"
  default     = "Apache2023"
}