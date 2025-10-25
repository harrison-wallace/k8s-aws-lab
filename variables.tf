
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  description = "The AWS availability zone to deploy resources"
  type        = string
  default     = "us-east-1a"

}

variable "my_public_ip" {
  description = "Your public IP address for SSH access"
  type       = string
  validation {
    condition     = can(cidrhost(var.my_public_ip, 0))
    error_message = " Must be a valid IP address in CIDR notation."
  }
}
variable "ssh_public_key" {
  description = "SSH public key for accessing EC2 instances"
  type        = string
}

variable "state_bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
}