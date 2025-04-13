variable "aws_region" {
  description = "AWS Region for the resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the VPC Endpoints and their Security Group will be created"
  type        = string
}

variable "vpc_endpoint_sg_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed for ingress traffic (HTTPS/443) to the interface endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "endpoints_config" {
  description = <<-EOT
  A map defining the VPC endpoints to create.
  Each key is an arbitrary friendly name for the endpoint.
  The value is an object with the following attributes:
    - service_name: The service suffix (e.g., 's3', 'ec2', 'kms', 'ecr.api').
    - endpoint_type: The type of endpoint, either "Interface" or "Gateway".
  EOT
  type = map(object({
    service_name  = string
    endpoint_type = string
  }))
  default = {}
  # Example usage from root module:
  # endpoints_config = {
  #   s3 = {
  #     service_name  = "s3"
  #     endpoint_type = "Gateway"
  #   }
  #   kms = {
  #     service_name  = "kms"
  #     endpoint_type = "Interface"
  #   }
  #   secretsmanager = {
  #     service_name  = "secretsmanager"
  #     endpoint_type = "Interface"
  #   }
  #   ecr_api = {
  #     service_name  = "ecr.api"
  #     endpoint_type = "Interface"
  #   }
  #   ecr_dkr = {
  #     service_name  = "ecr.dkr"
  #     endpoint_type = "Interface"
  #   }
  # }
}

variable "interface_endpoint_private_subnet_ids" {
  description = "List of private subnet IDs where the Interface VPC Endpoints will be attached. Required if creating Interface endpoints."
  type        = list(string)
  default     = null 
}

variable "gateway_endpoint_route_table_ids" {
  description = "List of Route Table IDs to associate with Gateway VPC Endpoints. Required if creating Gateway endpoints."
  type        = list(string)
  default     = null
}

variable "interface_endpoint_private_dns_enabled" {
  description = "Whether to enable private DNS for the interface endpoints"
  type        = bool
  default     = true
}

variable "interface_endpoint_extra_sg_ids" {
  description = "List of additional Security Group IDs to attach to Interface VPC Endpoints"
  type        = list(string)
  default     = []
}
