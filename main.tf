resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

    tags = {
        Name = var.vpc_name
    }   
}

resource "aws_subnet" "pub_subnet1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.pub_subnet1_cidr
  availability_zone = "${var.aws_region}a"

    tags = {
        Name = "pub-subnet1"
    }
}

resource "aws_subnet" "pub_subnet2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.pub_subnet2_cidr
  availability_zone = "${var.aws_region}b"

    tags = {
        Name = "pub-subnet-2"
    }
}

resource "aws_subnet" "priv_subnet1" {
  vpc_id            = aws_vpc.vpc.id 
  cidr_block        = var.priv_subnet1_cidr
  availability_zone = "${var.aws_region}a"

    tags = {
      Name = "priv-subnet-1"
    }
}

resource "aws_subnet" "priv_subnet2" {
  vpc_id            = aws_vpc.vpc.id 
  cidr_block        = var.priv-subnet2_cidr
  availability_zone = "${var.aws_region}b"

    tags = {
      Name = "priv-subnet-2"
    }
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "internet-igw"
    }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

    tags = {
        Name = "public-rt"
    }
}

resource "aws_route_table_association" "subnet1_assoc" {
  subnet_id      = aws_subnet.pub_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet2_assoc" {
  subnet_id      = aws_subnet.pub_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet3_assoc" {
  subnet_id      = aws_subnet.priv_subnet1.id
  route_table_id = aws_route_table.priv_route_table.id
}

resource "aws_route_table_association" "subnet4_assoc" {
  subnet_id      = aws_subnet.priv_subnet2.id
  route_table_id = aws_route_table.priv_route_table.id
}

resource "aws_eip" "my_eip" {
  domain   = "vpc"

  depends_on = [aws_internet_gateway.internet_gw]
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id         = aws_subnet.pub_subnet1.id
  allocation_id = aws_eip.my_eip.id
}

resource "aws_route_table" "priv_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-inst-security-group"
  description = "Allow traffic to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "instance_sg" {
  name        = "apach-instance-sg"
  description = "Allow traffic to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "apache_instance1" {
  ami           = "ami-0bce970415466784a"
  instance_type = var.instance_type  #use t4g.micro for cost effectiveness

  subnet_id     = aws_subnet.priv_subnet1.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello World from EC2!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.instance_name
  }
}

resource "aws_instance" "apache_instance2" {
  ami           = "ami-0bce970415466784a"
  instance_type = var.instance_type  #use t4g.micro for cost effectiveness

  subnet_id     = aws_subnet.priv_subnet2.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello World from EC2!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.instance_name
  }
}

/*
# We map our private subnet IDs into a local variable list to safely loop over them
locals {
  private_subnets = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_instance" "apache_instancer" {
  count = length(locals.private_subnets) # Creates exactly 2 instances dynamically
*/

resource "aws_lb" "instance_alb" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "instance_tg" {
  name        = "apache-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.instance_tg.arn
  target_id        = aws_instance.apache_instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.instance_tg.arn
  target_id        = aws_instance.apache_instance2.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.instance_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instance_tg.arn
  }
}