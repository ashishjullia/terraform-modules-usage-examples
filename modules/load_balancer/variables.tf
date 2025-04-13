variable "vpc_id" {
  description = "The VPC ID where the ALB and Target Group will be created."
  type        = string
}

variable "lb_subnet_ids" {
  description = "A list of subnet IDs (usually public) for the Application Load Balancer."
  type        = list(string)
}

variable "alb_name" {
  description = "The name for the Application Load Balancer."
  type        = string
  default     = "app-alb"
}

variable "target_group_name" {
  description = "The name for the Target Group."
  type        = string
}

variable "target_group_port" {
  description = "The port on which targets receive traffic. This should match the container port."
  type        = number
}

variable "target_group_protocol" {
  description = "The protocol to use for routing traffic to the targets (e.g., HTTP, HTTPS)."
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "The type of target that needs to be specified when registering targets with this target group. Use 'ip' for Fargate."
  type        = string
  default     = "ip"
}

variable "health_check_path" {
  description = "The destination for the health check request."
  type        = string
  default     = "/"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the HTTPS listener."
  type        = string
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled."
  type        = bool
  default     = false
}

variable "create_http_redirect_listener" {
  description = "If true, create an HTTP listener on port 80 that redirects to HTTPS on port 443."
  type        = bool
  default     = true
}
