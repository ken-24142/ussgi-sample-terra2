# ====================================================
# 各サービス用エンドポイント
# ====================================================
# 現在のリージョンを取得
data "aws_region" "current" {}

# エンドポイント
## S3用
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.samp_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    for route_table in aws_route_table.samp_rt_int : route_table.id
  ]

  tags = {
    Name        = "${var.prefix}-s3"
  }
}

# エンドポイント用のセキュリティグループ
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.prefix}-vpc-endpoint"
  vpc_id      = aws_vpc.samp_vpc.id

  ingress = [
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = [var.vpc_cidr]
      description      = "for AWS VPC Endpoint"
      ipv6_cidr_blocks = []
      security_groups  = []
      prefix_list_ids  = []
      self             = false
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = ""
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      prefix_list_ids  = []
      self             = false
    }
  ]

  tags = {
    Name        = "${var.prefix}-vpc-endpoint"
  }
}