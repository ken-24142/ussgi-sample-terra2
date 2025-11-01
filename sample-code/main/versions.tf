# ====================================================
# 環境設定（共通）
# ====================================================
terraform {
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.11.0"
    }
  }

  backend "s3" {
    bucket         = "test-terraform-0123xxxx4567" # 前準備で作成したS3バケット名へ変更
    key            = "tf-test2-2025.tfstate"
    region         = "ap-northeast-1" # 前準備で作成したS3バケットのリージョンへ変更
    use_lockfile   = true
  }
}

provider "aws" {
  region = "ap-northeast-1"

  allowed_account_ids = [
    "0123xxxx4567" # 今回リソースを作成するAWSアカウントIDへ変更
  ]

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "samp2-pj"
    }
  }
}

