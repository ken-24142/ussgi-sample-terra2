# ====================================================
# VPC、サブネット、ルートテーブルなど
# ====================================================
# VPC
resource "aws_vpc" "samp_vpc" {
  cidr_block             = var.vpc_cidr
  enable_dns_support     = true
  enable_dns_hostnames   = true
  tags = {
    Name        = "${var.prefix}-vpc"
  }
}

# サブネット
resource "aws_subnet" "samp_subnet_pub"{
  vpc_id            = aws_vpc.samp_vpc.id
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.public_subnets_cidr)
  cidr_block        = element(var.public_subnets_cidr, count.index)
  tags = {
    Name        = "${var.prefix}-public-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_subnet" "samp_subnet_int"{
  vpc_id            = aws_vpc.samp_vpc.id
  availability_zone = element(var.availability_zones, count.index)
  count             = length(var.intra_subnets_cidr)
  cidr_block        = element(var.intra_subnets_cidr, count.index)
  tags = {
    Name        = "${var.prefix}-intra-${element(var.availability_zones, count.index)}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "samp_igw" {
  vpc_id = aws_vpc.samp_vpc.id
  tags = {
    Name        = "${var.prefix}-igw"
  }
}

# ルートテーブル
resource "aws_route_table" "samp_rt_pub" {
  vpc_id = aws_vpc.samp_vpc.id
  tags = {
    Name        = "${var.prefix}-rt-pub"
  }
}

resource "aws_route_table" "samp_rt_int" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.samp_vpc.id
  tags = {
    Name        = "${var.prefix}-rt-int-${element(var.availability_zones, count.index)}"
  }
}

## ルートをルートテーブルに追加
resource "aws_route" "samp_pub_igw" {
  route_table_id         = aws_route_table.samp_rt_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.samp_igw.id
}

# サブネットにルートテーブルを関連付け
resource "aws_route_table_association" "samp_pub" {
  count          = length(aws_subnet.samp_subnet_pub)
  subnet_id      = aws_subnet.samp_subnet_pub[count.index].id
  route_table_id = aws_route_table.samp_rt_pub.id
}

resource "aws_route_table_association" "samp_int" {
  count          = length(aws_subnet.samp_subnet_int)
  subnet_id      = aws_subnet.samp_subnet_int[count.index].id
  route_table_id = aws_route_table.samp_rt_int[count.index].id
}
