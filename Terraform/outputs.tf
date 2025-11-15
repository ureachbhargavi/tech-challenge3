########################################
# Terraform Outputs                 #
########################################

# Outputs show important info after creation.
# Like: "what is my EC2 public IP?"
output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}
