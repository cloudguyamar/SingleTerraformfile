#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
    access_key = "*****"
    secret_key = "*****"
    region = "ap-south-1"
}

terraform {
  required_version = "<= 1.13.4" #Forcing which version of Terraform needs to be used
  required_providers {
    aws = {
      version = "<= 5.0.0" #Forcing which version of plugin needs to be used.
      source = "hashicorp/aws"
    }
  }
}

resource "aws_vpc" "sample" {
    cidr_block = "10.10.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "sample"
	Owner = "amar"
	environment = "sample"
    }
}

resource "aws_internet_gateway" "sampleIGW" {
    vpc_id = "${aws_vpc.sample.id}"
	tags = {
        Name = "sampleIGW"
    }
}

resource "aws_subnet" "subnet1-public-sample" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.10.10.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "subnet1-public-sample"
    }
}


resource "aws_route_table" "terraform-publicsample" {
    vpc_id = "${aws_vpc.sample.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.sampleIGW.id}"
    }

    tags = {
        Name = "sampleroute"
    }
}

resource "aws_route_table_association" "terraform-publicsample" {
    subnet_id = "${aws_subnet.subnet1-public-sample.id}"
    route_table_id = "${aws_route_table.terraform-publicsample.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.sample.id}"
}
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "terraform_sg" {
  name        = "terraform allowall"
  description = "Allow HTTP and SSH access to web servers"
  vpc_id      = aws_vpc.sample.id # Reference to an existing VPC

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-sg"
  }
}

resource "aws_instance" "web-1" {
	  ami = "ami-00af95fa354fdb788"
      availability_zone = "ap-south-1a"
      instance_type = "t2.micro"
      key_name = "testKey"
      subnet_id = "${aws_subnet.subnet1-public-sample.id}"
      vpc_security_group_ids = ["${aws_security_group.terraform_sg.id}"]
      associate_public_ip_address = true	
      tags = {
          Name = "Server-1"
          Env = "Prod"
          Owner = "amar"
     }
 }
