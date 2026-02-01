variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair to enable SSH access"
  type        = string
}
