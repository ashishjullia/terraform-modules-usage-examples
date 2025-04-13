variable "cloudflare_zone_id" {
  description = "The Zone ID for the domain in Cloudflare"
  type        = string
}

variable "record_name" {
  description = "The name of the DNS record (without the zone name)"
  type        = string
}

variable "record_type" {
  description = "The type of the DNS record (e.g., CNAME)"
  type        = string
}

variable "record_ttl" {
  description = "TTL for the DNS record"
  type        = number
  default     = 60 # Low TTL suitable for validation
}

variable "proxied" {
  description = "Whether the record should be proxied by Cloudflare (MUST be false for ACM validation)"
  type        = bool
  default     = false
}

variable "content" {
  description = "this should be url of alb"
  type = string
}
