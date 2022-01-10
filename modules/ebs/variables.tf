variable "zone" {
  type        = string
  description = "Set availability zone"
  default     = "us-east-1a"
}
variable "ebs_size" {
  type        = number
  description = "Set size of the drive in GiBs"
  default = 1
  }
variable "product" {
  type        = string
  description = "Set type of product"
  default     = "nginx"
}
variable "environment" {
  type        = string
  description = "Set environment"
  default     = "dev"
}