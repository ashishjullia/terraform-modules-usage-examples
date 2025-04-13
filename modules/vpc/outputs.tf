# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.vpc.arn
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with the VPC"
  value       = aws_vpc.vpc.main_route_table_id
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled for the VPC"
  value       = aws_vpc.vpc.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled for the VPC"
  value       = aws_vpc.vpc.enable_dns_hostnames
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for private subnets"
  value       = aws_subnet.private[*].cidr_block
}

# Route Table Outputs
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_subnet_route_table.id
}

output "private_route_table_ids" {
  description = "A list of the IDs of the created private route tables."
  value       = aws_route_table.private_route_table[*].id
}

# Optional: Outputting a map of AZ -> Route Table ID
output "private_route_table_ids_by_az" {
  description = "A map of Availability Zone suffixes to the IDs of the created private route tables."
  value = {
    # Loop through the created route tables and map the AZ suffix (from var.azs) to the route table ID
    for i, rt in aws_route_table.private_route_table : element(var.azs, i) => rt.id
  }
  # This output will be an empty map if no private route tables are created.
}

output "public_route_table_associations" {
  description = "List of associations between public subnets and the public route table"
  value       = aws_route_table_association.public[*].id
}

output "private_route_table_associations" {
  description = "List of associations between private subnets and the NAT route table"
  value       = aws_route_table_association.private[*].id
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "List of NAT gateway IDs"
  value       = aws_nat_gateway.nat_gateway[*].id
}

output "nat_gateway_elastic_ips" {
  description = "List of Elastic IP addresses for NAT gateways"
  value       = aws_eip.eip_nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of Allocation IDs for NAT gateway EIPs"
  value       = aws_eip.eip_nat[*].allocation_id
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "The ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}

# Route Outputs
output "public_route_id" {
  description = "The ID of the public route to the internet gateway"
  value       = aws_route.public_internet_route.id
}

output "nat_route_ids" {
  description = "List of NAT route IDs"
  value       = aws_route.nat_route[*].id
}

# Elastic IP Outputs
output "elastic_ip_ids" {
  description = "List of Elastic IP allocation IDs"
  value       = aws_eip.eip_nat[*].id
}

output "elastic_ip_addresses" {
  description = "List of Elastic IP addresses"
  value       = aws_eip.eip_nat[*].public_ip
}
