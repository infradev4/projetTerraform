variable "instance_type" {
  type        = string
  description = "Set aws instance type"
  default     = "t2.nano"
}
variable "product" {
  type        = string
  description = "Set type of product"
  default     = "Nginx"
}
variable "environment" {
  type        = string
  description = "Set env"
  default     = "dev"
}
variable "zone" {
  type        = string
  description = "Set availability zone"
  default     = "us-east-1a"
}
variable "key_name" {
  type        = string
  description = "Set key name"
  default = "oussama-kp-ajc"
}
variable "aws_common_tag" {
  type        = map
  description = "Set aws tag"
  default = {
    Name = "ec2-oussama"
  }
}
variable "security_group_name" {
  type        = string
  description = "Set Security group name"
}
variable "ssh_key_path" {
  type        = string
  description = "Set ssh key path"
  default = "M:/DevOps/terraform/oussama-kp-ajc.pem"
}
