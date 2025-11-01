# ====================================================
# モジュールで使う変数
# ====================================================
variable "prefix" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

# Auroraを配置するサブネットID
variable "intra_subnet_ids" {
  type = list(string)
}

variable "db_name" {}
variable "engine_version" {}
variable "cluster_maintenance_window" {}
variable "instance_maintenance_window" {
  type = list(string)
}
variable "backup_window" {}
variable "instance_class" {}
