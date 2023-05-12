provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_security_group" "example" {
  name_prefix = "example-"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "example" {
  name = "example-profile"

  role = aws_iam_role.example.name
}

resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_launch_configuration" "example" {
  name_prefix   = "example-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.example.id]
  iam_instance_profile = aws_iam_instance_profile.example.name
  user_data = <<EOF
#!/bin/bash
echo "You're doing really Great" > index.html
nohup python -m SimpleHTTPServer 80 &
EOF
}

resource "aws_autoscaling_group" "example" {
  name                 = "example-asg"
  launch_configuration = aws_launch_configuration.example.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_subnet.example.id]
}
