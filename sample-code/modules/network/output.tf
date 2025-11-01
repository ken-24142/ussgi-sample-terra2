# ====================================================
# リソースの情報をモジュール外部に出力
# ====================================================
output "samp_vpc_id" {
  value = aws_vpc.samp_vpc.id
}

output "samp_vpc_cidr" {
  value = aws_vpc.samp_vpc.cidr_block
}

output "samp_subnet_pub_id_0" {
  value = aws_subnet.samp_subnet_pub[0].id
}

output "samp_subnet_pub_id_1" {
  value = aws_subnet.samp_subnet_pub[1].id
}

output "samp_subnet_pub_id_2" {
  value = aws_subnet.samp_subnet_pub[2].id
}

output "samp_subnet_int_id_0" {
  value = aws_subnet.samp_subnet_int[0].id
}

output "samp_subnet_int_id_1" {
  value = aws_subnet.samp_subnet_int[1].id
}

output "samp_subnet_int_id_2" {
  value = aws_subnet.samp_subnet_int[2].id
}

output "samp_s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}