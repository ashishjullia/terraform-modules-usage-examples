resource "aws_acm_certificate" "app_cert" {
  domain_name               = var.domain_name
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
