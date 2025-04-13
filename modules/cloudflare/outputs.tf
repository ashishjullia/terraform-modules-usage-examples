output "name" {
  description = "The fully qualified domain name of the created DNS record"
  value       = cloudflare_dns_record.this.name
}
