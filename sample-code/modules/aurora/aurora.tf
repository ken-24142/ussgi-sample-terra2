# ====================================================
# Aurora MySQL DBクラスター
# ====================================================
# DBサブネットグループの作成
resource "aws_db_subnet_group" "samp_group" {
  name       = "${var.prefix}-aurora-db-subnet-group"
  subnet_ids = var.intra_subnet_ids

  tags = {
    Name = "${var.prefix}-aurora-db-subnet-group"
  }
}

# Aurora MySQL 8.0用パラメータグループ
resource "aws_rds_cluster_parameter_group" "samp_para_group" {
  name        = "${var.prefix}-aurora-mysql8-parameter-group"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 parameter group"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  tags = {
    Name = "${var.prefix}-aurora-mysql8-parameter-group"
  }
}

# Aurora MySQL 8.0用 DBパラメータグループ（インスタンス用）
resource "aws_db_parameter_group" "samp_db_para_group" {
  name        = "${var.prefix}-aurora-mysql8-db-parameter-group"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 DB parameter group"

  tags = {
    Name = "${var.prefix}-aurora-mysql8-db-parameter-group"
  }
}



# Aurora用セキュリティグループ
resource "aws_security_group" "aurora" {
  name        = "${var.prefix}-aurora-sg"
  description = "for Aurora MySQL"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL port from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-aurora-sg"
  }
}

# Aurora MySQL 8.0 クラスター
resource "aws_rds_cluster" "aurora" {
  cluster_identifier                  = "${var.prefix}-aurora-cluster"
  engine                              = "aurora-mysql"
  engine_version                      = var.engine_version
  database_name                       = var.db_name
  master_username                     = "admin"
  manage_master_user_password         = true
  db_subnet_group_name                = aws_db_subnet_group.samp_group.name
  vpc_security_group_ids              = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.samp_para_group.name
  skip_final_snapshot                 = true
  apply_immediately                   = true
  allow_major_version_upgrade         = false
  deletion_protection                 = false
  storage_encrypted                   = true
  copy_tags_to_snapshot               = true
  port                                = 3306
  iam_database_authentication_enabled = false
  backup_retention_period             = 7
  enabled_cloudwatch_logs_exports     = [
                                        "audit",
                                        "error",
                                        "general",
                                        "slowquery"
                                        ]
  # メンテナンスウィンドウ
  preferred_maintenance_window        = var.cluster_maintenance_window
  # バックアップウィンドウ
  preferred_backup_window             = var.backup_window

  lifecycle {
    ignore_changes = [
      cluster_identifier,
      master_username,
      master_password,
      database_name,
      preferred_maintenance_window,
      preferred_backup_window
    ]
  }

  tags = {
    Name = "${var.prefix}-aurora-cluster"
  }
}

# 各サブネットのAZ情報を取得
data "aws_subnet" "azs" {
  count = length(var.intra_subnet_ids)
  id    = var.intra_subnet_ids[count.index]
}

# 3AZ構成でAuroraインスタンス
resource "aws_rds_cluster_instance" "aurora_instances" {
  count                        = 3
  identifier                   = "${var.prefix}-aurora-instance-${count.index + 1}"
  cluster_identifier           = aws_rds_cluster.aurora.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.aurora.engine
  engine_version               = aws_rds_cluster.aurora.engine_version
  publicly_accessible          = false
  auto_minor_version_upgrade   = false
  db_subnet_group_name         = aws_db_subnet_group.samp_group.name
  db_parameter_group_name      = aws_db_parameter_group.samp_db_para_group.name
  availability_zone            = data.aws_subnet.azs[count.index].availability_zone
  preferred_maintenance_window = var.instance_maintenance_window[count.index]

  lifecycle {
    ignore_changes = [
      identifier,
      availability_zone,
      preferred_maintenance_window
    ]
  }

  tags = {
    Name = "${var.prefix}-aurora-instance-${count.index + 1}"
  }
}


