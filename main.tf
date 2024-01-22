provider "aws" {
    region = "us-east-1"
    access_key = "AKIAXZ4N6QFBSZZT4VLA"
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
