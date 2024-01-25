provider "aws" {
    region = "us-east-1"
    access_key = "AKIAT7G5PJOZ7QOBOFPN"
    secret_key = "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"
}

resource "aws_key_pair" "my_ec2_kp" {
    key_name = "my_ec2_kp"
    public_key = var.ssh_private_key
}

resource "aws_default_vpc" "default" {
    tags = {
        Name = "Default VPC"
    }
}




output "worker1_publicip" {
    value = aws_instance.worker1_instance.public_ip
}
