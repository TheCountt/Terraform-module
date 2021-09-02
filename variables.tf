variable "region" {}

variable "vpc_cidr" {}

variable "enable_dns_support" {}

variable "enable_dns_hostnames" {}

variable "enable_classiclink" {}

variable "enable_classiclink_dns_support" {}

variable "additional_tags" {
  default     = {}
  description = "Additional resource tags"
  type        = map(string)
}

variable "environment" {
  default = {}
}

variable "ami" {}

variable "instance_type" {}

variable "account_no" {}

variable "kms_arn" {
  type        = string
  default     = ""
  description = "The ARN of a KMS key used to encrypt and decrypt SecretString values"
}
