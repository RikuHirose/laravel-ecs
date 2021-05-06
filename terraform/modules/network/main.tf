# VPC
# https://www.terraform.io/docs/providers/aws/r/vpc.html
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.name
  }
}

# Public Subnet
# https://www.terraform.io/docs/providers/aws/r/subnet.html
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = aws_vpc.this.id

  # Subnetを作成するAZ
  availability_zone = var.azs[count.index]
  cidr_block        = var.public_subnet_cidrs[count.index]

  tags = {
    Name = "${var.name}-public-${var.acd[count.index]}"
  }
}

# Internet Gateway
# https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.name
  }
}

# Elasti IP
# https://www.terraform.io/docs/providers/aws/r/eip.html
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  vpc = true

  tags = {
    Name = "eip-${var.name}-${var.acd[count.index]}"
  }
}

# NAT Gateway
# https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
resource "aws_nat_gateway" "this" {
  count = length(var.public_subnet_cidrs)

  # NAT Gatewayを配置するSubnetを指定
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  # 紐付けるElasti IP
  allocation_id = element(aws_eip.nat.*.id, count.index)

  tags = {
    Name = "natgw-${var.name}-${var.acd[count.index]}"
  }
}

# Route Table
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-${var.name}-public"
  }
}

# Route
# https://www.terraform.io/docs/providers/aws/r/route.html
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
}

# Association
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Protected Subnet
resource "aws_subnet" "protected" {
  count = length(var.protected_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  availability_zone = var.azs[count.index]
  cidr_block        = var.protected_subnet_cidrs[count.index]

  tags = {
    Name = "${var.name}-protected-${var.acd[count.index]}"
  }
}

resource "aws_route_table" "protected" {
  count = length(var.protected_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-${var.name}-protected-${var.acd[count.index]}"
  }
}

resource "aws_route" "protected" {
  count = length(var.protected_subnet_cidrs)

  destination_cidr_block = "0.0.0.0/0"

  route_table_id = element(aws_route_table.protected.*.id, count.index)
  nat_gateway_id = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "protected" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = element(aws_subnet.protected.*.id, count.index)
  route_table_id = element(aws_route_table.protected.*.id, count.index)
}

# Private Subnet
resource "aws_subnet" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.this.id

  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.name}-private-${var.acd[count.index]}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-${var.name}-private"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id_a" {
  value = aws_subnet.public[0].id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "protected_subnet_ids" {
  value = aws_subnet.protected.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}
