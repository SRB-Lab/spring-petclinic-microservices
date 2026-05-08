variable "aws_region" {
  description = "AWS region where ECR repositories will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten (MUTABLE) or not (IMMUTABLE)"
  type        = string
  default     = "MUTABLE"   # Keep MUTABLE so 'latest' tag can always be updated
}

variable "keep_last_n_images" {
  description = "Number of versioned images to retain per repository"
  type        = number
  default     = 10
}

variable "untagged_expiry_days" {
  description = "Days before untagged/dangling images are removed"
  type        = number
  default     = 7
}
