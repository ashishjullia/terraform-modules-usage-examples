variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC for easier instance identification."
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Enable DNS resolution within the VPC."
  type        = bool
  default     = false
}

variable "private_subnets_count" {
  description = "Number of private subnets to create within the VPC."
  type        = number
  default     = 0
}

variable "public_subnets_count" {
  description = "Number of public subnets to create within the VPC."
  type        = number
  default     = 0
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways to create. Typically one per availability zone for redundancy."
  type        = number
  default     = 0
}

variable "eip_nat_count" {
  description = "Number of Elastic IPs to allocate for NAT gateways."
  type        = number
  default     = 0
}

variable "azs" {
  description = "A list of availability zones to spread the subnets across. Typically set to at least two for high availability."
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "The AWS region where the VPC and related resources will be created."
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Name prefix for the VPC and associated resources."
  type        = string
  default     = "my-vpc"
}

variable "map_public_ip_on_launch_public_subnet" {
  description = "Whether to automatically assign a public IP to instances launched in public subnets."
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch_private_subnet" {
  description = "Whether to automatically assign a public IP to instances launched in private subnets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to resources. Typically includes project and environment information."
  type        = map(string)
  default     = {
    Project     = ""
    Environment = ""
  }
}
