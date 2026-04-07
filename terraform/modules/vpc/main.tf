# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

# ----------------------
# Internet Gateway
# ----------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# ----------------------
# Public Subnets
# ----------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.additional_tags,
    {
      Name                     = "${var.name}-public-${count.index}"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

# ----------------------
# Private Subnets
# ----------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.additional_tags,
    {
      Name                            = "${var.name}-private-${count.index}"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

# ----------------------
# Public Route Table
# ----------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ----------------------
# Route Table Association (Public)
# ----------------------
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ----------------------
# NAT Gateway
# ----------------------
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  domain = "vpc"

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-nat-eip-${count.index}"
    }
  )
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-nat-${count.index}"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# ----------------------
# Private Route Table
# ----------------------
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.name}-private-rt-${count.index}"
    }
  )
}

resource "aws_route" "private_nat_access" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

# ----------------------
# Route Table Association (Private)
# ----------------------
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
