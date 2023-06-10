provider "aws" {
  region = var.aws_region
}

#create a custom VPC
resource "aws_vpc" "apache_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = var.vpc_name
    Environment = "apache"
    Terraform   = "true"
  }

  enable_dns_hostnames = true
}

#create internet gateway to attach to custom VPC
resource "aws_internet_gateway" "apache-igw" {
  vpc_id = aws_vpc.apache_vpc.id

  tags = {
    Name = "apache-igw"
  }
}

##Deploy two public subnets for web server tier
##A public subnet will be launched in the AZ us-east-1a 

resource "aws_subnet" "apache-public-subnet-1" {
  vpc_id                  = aws_vpc.apache_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.us-az-west-1a
  map_public_ip_on_launch = true

  tags = {
    Name = "apache-public-subnet-1"
  }
}

##A public subnet will be launched in the AZ us-east-1b
resource "aws_subnet" "apache-public-subnet-2" {
  vpc_id                  = aws_vpc.apache_vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = var.us-az-west-1b
  map_public_ip_on_launch = true

  tags = {
    Name = "apache-public-subnet-2"
  }
}

#Deploy two private subnets for RDS tier
##A private subnet will be launched in the AZ us-east-1a
resource "aws_subnet" "apache-private-subnet-1" {
  vpc_id            = aws_vpc.apache_vpc.id
  cidr_block        = "10.10.3.0/24"
  availability_zone = var.us-az-west-1a

  tags = {
    Name = "apache-private-subnet-1"
  }
}

##A private subnet will be launched in the AZ us-west-1b
resource "aws_subnet" "apache-private-subnet-2" {
  vpc_id            = aws_vpc.apache_vpc.id
  cidr_block        = "10.10.4.0/24"
  availability_zone = var.us-az-west-1b

  tags = {
    Name = "apache-private-subnet-2"
  }
}

#create public route table with route for internet gateway 
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.apache_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.apache-igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

#create private route table with route for NAT gateway
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.apache_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.apache-nat_gateway.id
  }

  tags = {
    Name = "private-rt"
  }
}

#public route table with public subnet associations
resource "aws_route_table_association" "public-subnet-1" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.apache-public-subnet-1.id
}

resource "aws_route_table_association" "public-subnet-2" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.apache-public-subnet-2.id
}

#private route table with private subnet associations
resource "aws_route_table_association" "private-subnet-1" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.apache-private-subnet-1.id
}

resource "aws_route_table_association" "private-subnet-2" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.apache-private-subnet-2.id
}

#create an elastic IP to assign to NAT Gateway
resource "aws_eip" "apache-nat-eip" {
  vpc        = true #confirms if the EIP is in a VPC or not
  depends_on = [aws_internet_gateway.apache-igw]
  tags = {
    Name = "apache-nat-eip"
  }
}

#create a NAT Gateway for private subnets
resource "aws_nat_gateway" "apache-nat_gateway" {
  depends_on    = [aws_eip.apache-nat-eip]
  allocation_id = aws_eip.apache-nat-eip.id
  subnet_id     = aws_subnet.apache-public-subnet-1.id
  tags = {
    Name = "apache-nat_gateway"
  }
}

#security groups allowing inbound traffic from the internet
resource "aws_security_group" "apache-sg" {
  name        = "apache-sg"
  vpc_id      = aws_vpc.apache_vpc.id
  description = "Security group for Apache server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create EC2 instance launch template for auto scaling group
resource "aws_launch_template" "apache-instance" {
  name                   = "apache-instance"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = "my-kp"
  vpc_security_group_ids = [aws_security_group.apache-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "apache-instance"
    }
  }

  user_data = filebase64("apache.sh")
}

#auto scaling group to launch a minimum of 2 instances and a maximum of 3 instances
resource "aws_autoscaling_group" "apache2-asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.apache-public-subnet-1.id, aws_subnet.apache-public-subnet-2.id]

  launch_template {
    id = aws_launch_template.apache-instance.id
  }

  tag {
    key                 = "Name"
    value               = "apache-instance-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "mysql-security_group" {
  name        = "mysql-security_group"
  vpc_id      = aws_vpc.apache_vpc.id
  description = "Security group for MySQL server"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create RDS MySQL Instance
resource "aws_db_instance" "data-base-instance" {
  allocated_storage = 20
  db_name           = "data-base-instance"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"

  #credentials will be added as sensitive variables in Terraform Cloud
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.mysql-security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-grp.id
  skip_final_snapshot    = true
}

#subnet group for RDS instance
resource "aws_db_subnet_group" "db-subnet-grp" {
  name       = "db-subnet-grp"
  subnet_ids = [aws_subnet.apache-private-subnet-1.id, aws_subnet.apache-private-subnet-2.id]

  tags = {
    Name = "Database subnet group"
  }
}