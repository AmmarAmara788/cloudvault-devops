# =============================================================================
# 🧩 modules/network — the VPC and its subnet tiers. TODO(student). No resources yet.
# =============================================================================
# This is the foundation of the three-trust-boundary design in
# docs/ARCHITECTURE_CHALLENGE.md.
#
# QUESTIONS TO ANSWER IN CODE:
#   - How many subnet TIERS does "public traffic / app services / data stores"
#     imply, and across how many Availability Zones (for HA)?  => how many subnets total?
#   - Which tier gets a route to an Internet Gateway? Which gets a route to a NAT?
#     Which gets NO internet route at all?
#   - The app tier needs OUTBOUND internet (pull images, reach APIs) but must be
#     UNREACHABLE from the internet. What component gives it exactly that?
#   - What should the data tier's route table look like?
#
# ACCEPTANCE CRITERIA:
#   done when: a diagram + this module agree; public subnets reach the internet,
#   app subnets have egress-only, data subnets are isolated; all across >= 2 AZs.
#
# Fair game: the official AWS VPC docs. Copying a full VPC module is not the point.
# TODO(student): implement resource "aws_vpc" / subnets / route tables / IGW / NAT here.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cloudvault-vpc"
  }
}

# 1. Internet Gateway for Public Tier
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cloudvault-igw"
  }
}

# 2. Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudvault-public-${count.index + 1}"
  }
}

resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "cloudvault-app-${count.index + 1}"
  }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "cloudvault-data-${count.index + 1}"
  }
}

# 3. Elastic IP & NAT Gateway for App Tier Egress-only internet
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "cloudvault-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "cloudvault-nat-gw"
  }
}

# 4. Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "cloudvault-public-rt"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "cloudvault-app-rt"
  }
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id
  # Isolated: No route to IGW or NAT Gateway

  tags = {
    Name = "cloudvault-data-rt"
  }
}

# 5. Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}