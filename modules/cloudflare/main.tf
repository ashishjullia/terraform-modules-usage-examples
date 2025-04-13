resource "cloudflare_dns_record" "this" {
  zone_id = var.cloudflare_zone_id
  name    = var.record_name
  content = var.content
  type    = var.record_type
  ttl     = var.record_ttl
  proxied = var.proxied

  # lifecycle {
  #   ignore_changes = [
  #     name,
  #     content
  #   ]
  # }
}
