terraform {
    backend "s3" {
      bucket = "dc1testing-tfstate-s3"
      key = "tfstate/terraform.tfstate"
      region = "ap-southeast-2"
      encrypt = true
    }
}

provider "aws" {
    region =  var.aws-region
    #profile = "user1test"
}


resource "aws_vpc" "main-vpc" {
    cidr_block = var.cidr-block
    tags = {
        Name = "main-vpc"
        vpc = "main-vpc"
    }
}

resource "aws_internet_gateway" "internet-gateway" {
    vpc_id = aws_vpc.main-vpc.id
    tags = {
        Name = "internet-gateway"
        internet-gateway = "internet-gateway"
    }
}

resource "aws_route_table" "vpc-route" {
    vpc_id = aws_vpc.main-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet-gateway.id
    }
}

resource "aws_route_table_association" "vpc-route-associate-1" {
    subnet_id = aws_subnet.container_subnet_1.id
    route_table_id = aws_route_table.vpc-route.id
}

resource "aws_route_table_association" "vpc-route-associate-2" {
    subnet_id = aws_subnet.container_subnet_2.id
    route_table_id = aws_route_table.vpc-route.id
}

resource "aws_security_group" "security-group" {
    vpc_id = aws_vpc.main-vpc.id
    name = "security-group"
    ingress {
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 80
        to_port = 80
    }
    ingress {
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 22
        to_port = 22
    }
    egress {
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 0
        to_port = 65535
    }
    tags = {
        security-group = "security-group"
    }
    
}

resource "aws_vpc_security_group_ingress_rule" "ingress-allow-all" {
    security_group_id = aws_security_group.security-group.id
    ip_protocol = "-1"
    cidr_ipv4 = "0.0.0.0/0" 
}

resource "aws_vpc_security_group_egress_rule" "egress-allow-all" {
    security_group_id = aws_security_group.security-group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_subnet" "container_subnet_1" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-southeast-2a"
    tags = {
        Name = "container_subnet_1"
        subnet = "container_subnet_1-web-server"
    }

}

resource "aws_subnet" "container_subnet_2" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-southeast-2b"
    tags = {
        Name = "container_subnet_2"
        subnet = "container_subnet_2-web-server"
    }
  
}

resource "aws_eip" "elastic-ip" {
    domain = "vpc"
    instance = aws_instance.main_ec2.id 
}
#test ec2 t
resource "aws_key_pair" "demoenvkey" {
  key_name   = "demoenvkey"
  public_key = var.public-key
}

resource "aws_instance" "main_ec2" {
    subnet_id = aws_subnet.container_subnet_1.id
    ami = var.ami
    instance_type = var.instance-type
    vpc_security_group_ids = [ aws_security_group.security-group.id ]
    key_name = aws_key_pair.demoenvkey.id
    user_data = "${file("install_nginx.sh")}"
    tags = {
        Name ="main-ec2" 
        server = "ec2-webserver"
    }

}



