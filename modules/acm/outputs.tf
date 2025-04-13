output "certificate_arn" {
  description = "ARN of the requested ACM certificate"
  value       = aws_acm_certificate.app_cert.arn
}

output "domain_validation_options" {
  description = "DNS validation options for the certificate (name, value, type for CNAME records)"
  value       = aws_acm_certificate.app_cert.domain_validation_options
}
