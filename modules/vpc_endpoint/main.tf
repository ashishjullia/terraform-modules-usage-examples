resource "aws_security_group" "vpc_endpoint_sg" {
  # Check if any interface endpoints are defined before creating the SG
  count       = length([for ep in var.endpoints_config : ep if ep.endpoint_type == "Interface"]) > 0 ? 1 : 0
  description = "Allow HTTPS from within VPC to Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_endpoint_sg_ingress_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "interface" {
  # Only iterate over endpoints marked as "Interface"
  for_each = {
    for k, v in var.endpoints_config : k => v if v.endpoint_type == "Interface"
  }

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.${each.value.service_name}"
  vpc_endpoint_type = "Interface" 

  subnet_ids = length(coalesce(var.interface_endpoint_private_subnet_ids, [])) > 0 ? var.interface_endpoint_private_subnet_ids : tolist([])
  security_group_ids = concat(
      length(aws_security_group.vpc_endpoint_sg) > 0 ? [aws_security_group.vpc_endpoint_sg[0].id] : [], 
      var.interface_endpoint_extra_sg_ids
  )

  private_dns_enabled = var.interface_endpoint_private_dns_enabled
}

resource "aws_vpc_endpoint" "gateway" {
  # Only iterate over endpoints marked as "Gateway"
  for_each = {
    for k, v in var.endpoints_config : k => v if v.endpoint_type == "Gateway"
  }

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.${each.value.service_name}"
  vpc_endpoint_type = "Gateway" 

  route_table_ids = length(coalesce(var.gateway_endpoint_route_table_ids, [])) > 0 ? var.gateway_endpoint_route_table_ids : tolist(null)
}
