resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}"
  }
}

resource "aws_subnet" "private" {

  count  = var.private_subnets_count > 0 ? var.private_subnets_count : 0
  vpc_id = aws_vpc.vpc.id
  # 8? because giving /16 and we need /24 sized subnets
  cidr_block = cidrsubnet("${var.cidr_block}", 8, count.index)

  availability_zone = format("${var.aws_region}%s", element(var.azs, count.index))

  map_public_ip_on_launch = var.map_public_ip_on_launch_private_subnet

  tags = {
    Name = format("${values(var.tags)[0]}-${values(var.tags)[1]}-${var.vpc_name}-private-${var.aws_region}%s", element(var.azs, count.index))
  }
}

resource "aws_subnet" "public" {

  count  = var.public_subnets_count > 0 ? var.public_subnets_count : 0
  vpc_id = aws_vpc.vpc.id
  # 8? because giving /16 and we need /24 sized subnets
  # https://developer.hashicorp.com/terraform/language/functions/cidrsubnet
  cidr_block = cidrsubnet("${var.cidr_block}", 8, count.index + var.private_subnets_count)
  # cidr_block = format("%s", element(var.private_subnets, count.index))

  availability_zone = format("${var.aws_region}%s", element(var.azs, count.index))

  map_public_ip_on_launch = var.map_public_ip_on_launch_public_subnet

  tags = {
    Name = format("${values(var.tags)[0]}-${values(var.tags)[1]}-${var.vpc_name}-public-${var.aws_region}%s", element(var.azs, count.index))
  }
}

# Public Route Table
resource "aws_route_table" "public_subnet_route_table" {

  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]


  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}-public"
  }
}

# Private Route Table
resource "aws_route_table" "nat_route_table" {
  count = var.eip_nat_count > 0 ? var.eip_nat_count : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}-private-nat"
  }
}

# Create one private route table per AZ where private subnets exist, regardless of NAT Gateway presence.
resource "aws_route_table" "private_route_table" {
  # Create if private_subnets_count > 0. Create one per private subnet/AZ requested.
  count = var.private_subnets_count > 0 ? var.private_subnets_count : 0

  vpc_id = aws_vpc.vpc.id

  tags = {
    # Name indicating it's private and associated with a specific AZ
    Name = format("${values(var.tags)[0]}-${values(var.tags)[1]}-private-%s", element(var.azs, count.index))
  }
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Private route via NAT Gateway (Conditional)
# Only create this route if NAT Gateways are requested.
resource "aws_route" "nat_route" {
  # Create only if nat_gateway_count > 0. Assumes nat_gateway_count matches the number of private AZs needing NAT.
  count = var.nat_gateway_count > 0 ? var.nat_gateway_count : 0

  # Associate with the corresponding private route table created above
  route_table_id = element(aws_route_table.private_route_table[*].id, count.index)

  destination_cidr_block = "0.0.0.0/0"

  # Associate with the corresponding NAT Gateway
  nat_gateway_id = element(aws_nat_gateway.nat_gateway[*].id, count.index)
}

# Associate Private Subnets with Private Route Tables
# Always associate private subnets with their corresponding route tables if they exist.
resource "aws_route_table_association" "private" {
  # Associate if private_subnets_count > 0
  count = var.private_subnets_count > 0 ? var.private_subnets_count : 0

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  # Associate with the corresponding private route table (based on index/AZ)
  route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
}

resource "aws_route_table_association" "public" {
  count = var.public_subnets_count > 0 ? var.public_subnets_count : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_nat_gateway" "nat_gateway" {
  count = var.nat_gateway_count > 0 ? var.nat_gateway_count : 0

  allocation_id = element(aws_eip.eip_nat[*].id, count.index)

  subnet_id = element(aws_subnet.public[*].id, count.index)

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}"
  }
}

resource "aws_internet_gateway" "igw" {

  depends_on = [
    aws_vpc.vpc
  ]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}"
  }
}

resource "aws_eip" "eip_nat" {
  count  = var.eip_nat_count > 0 ? var.eip_nat_count : 0
  domain = "vpc"

  tags = {
    Name = "${values(var.tags)[0]}-${values(var.tags)[1]}"
  }
}
