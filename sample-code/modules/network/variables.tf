# ====================================================
# モジュールで使う変数
# ====================================================
variable "prefix" {}
variable "vpc_cidr" {}
variable "availability_zones" {
  type = list(string)
}

variable "public_subnets_cidr" {
  type = list(string)
}

variable "intra_subnets_cidr" {
  type = list(string)
}
