# ====================================================
# ワークEC2インスタンスに必要なリソース
# ====================================================
// AmazonLinux 2023の最新AMI を取得
data "aws_ami" "amazonlinux_2023" {
  most_recent = true      #最新版を指定する設定
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023.8.*kernel-6.1-x86_64"]
  }
}

# IAMロール
## ロール作成と信頼ポリシー設定
resource "aws_iam_role" "work_ec2_role" {
  name = "work-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

## AmazonSSMManagedInstanceCore ポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "work_ec2_ssm_core" {
  role       = aws_iam_role.work_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

## インスタンスプロファイル作成、IAMロールを関連付け
resource "aws_iam_instance_profile" "work_ec2_profile" {
  name = "work-ec2-role-iprf"
  role = aws_iam_role.work_ec2_role.name
}

# セキュリティグループ
resource "aws_security_group" "work_ec2_sg" {
  name        = "work-ec2-sg"
  description = "Security group for work EC2"
  vpc_id      = var.vpc_id

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Allow all outbound traffic"
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      prefix_list_ids  = []
      self             = false
    }
  ]

  tags = {
    Name        = "work-ec2-sg"
  }
}

# EC2インスタンス
resource "aws_instance" "work_ec2" {
  ami                         = data.aws_ami.amazonlinux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = var.ec2_subnet_id
  vpc_security_group_ids      = [aws_security_group.work_ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.work_ec2_profile.name
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
    delete_on_termination = true
  }
  
  tags = {
    Name = "work-ec2"
  }
}