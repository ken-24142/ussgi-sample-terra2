# ====================================================
# 管理（作成）するリソースたち
# ====================================================
### 共通で使う値はここで定義する
locals {  
  prefix                 = "samp02"
}

### VPC、サブネット
module "network" {
  source                 = "../modules/network"
  prefix                 = local.prefix
  vpc_cidr               = "172.23.0.0/16"
  availability_zones     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  public_subnets_cidr    = ["172.23.0.0/24", "172.23.1.0/24", "172.23.2.0/24"]
  intra_subnets_cidr     = ["172.23.20.0/24", "172.23.21.0/24", "172.23.22.0/24"]
}

### EC2
# module "ec2" {
#   source                 = "../modules/ec2"
#   prefix                 = local.prefix
#   vpc_id                 = module.network.samp_vpc_id
#   ec2_subnet_id          = module.network.samp_subnet_pub_id_0
# }

### Aurora MySQL
# module "aurora" {
#   source                      = "../modules/aurora"
#   prefix                      = local.prefix
#   vpc_id                      = module.network.samp_vpc_id
#   vpc_cidr                    = module.network.samp_vpc_cidr
#   intra_subnet_ids            = [
#                                  module.network.samp_subnet_int_id_0,
#                                  module.network.samp_subnet_int_id_1,
#                                  module.network.samp_subnet_int_id_2
#                                ]
#   db_name                     = "samp2_db"
#   engine_version              = "8.0.mysql_aurora.3.10.0"
#   cluster_maintenance_window  = "sat:15:00-sat:15:30"
#   instance_maintenance_window = [
#                                 "sat:15:30-sat:16:00", 
#                                 "sat:16:00-sat:16:30",
#                                 "sat:16:30-sat:17:00"
#                               ]
#   backup_window               = "20:00-20:30"
#   instance_class              = "db.t3.medium"
# }

### Lambda
# module "lambda" {
#   source                       = "../modules/lambda"
#   prefix                       = local.prefix
#   runtime                      = "python3.13"
#   db_cluster_identifier        = module.aurora.aurora_cluster_id
#   snapshot_schedule            = "cron(0 18 L * ? *)" # 毎月1日 午前3時JST（JST=UTC+9）
#   maximum_event_age_in_seconds = 1800
#   maximum_retry_attempts       = 0
# }