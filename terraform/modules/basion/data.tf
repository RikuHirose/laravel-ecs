
# data {} blockを使って定義し、最新のAmazon-linux-2のAMIのIDをFetchする
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]

  # filterを使ってリソースを絞り込む
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}