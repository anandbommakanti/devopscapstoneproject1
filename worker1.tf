resource "aws_security_group" "w1_allow_ssh_http" {
    name = "allow_ssh_http"
    description = "To allow SSH HTTP"
    vpc_id = aws_default_vpc.default.id

    ingress {
        description = "SSH"
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "standard-http"
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "jenkins-http"
        from_port = "8080"
        to_port = "8080"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
}

resource "aws_instance" "worker1_instance" {
    
    ami = "ami-0c7217cdde317cfec"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = aws_key_pair.my_ec2_kp.key_name
    vpc_security_group_ids = [aws_security_group.w1_allow_ssh_http.id]

    tags = {
        Name = "worker1"
    }

    user_data = <<EOF
#!/bin/bash
apt update -y
apt install software-properties-common -y
add-apt-repository --yes --update ppa:ansible/ansible
apt install ansible -y
sudo apt install git -y
useradd ansible -m
git clone https://github.com/anandbommakanti/devopscapstoneproject1.git
    EOF

}

