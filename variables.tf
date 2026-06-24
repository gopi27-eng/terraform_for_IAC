variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "ap-south-2" # You can change this to us-east-2 or us-west-2 later
}

variable "vpc_cidr" {
  description = "The overall network IP range for our custom VPC"
  type        = string
  default     = "10.0.0.0/16" 
}

variable "subnet_1_cidr" {
  description = "IP range for our first public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "subnet_2_cidr" {
  description = "IP range for our second public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "The size of the virtual machine"
  type        = string
  default     = "t3.micro" # Free tier eligible
}