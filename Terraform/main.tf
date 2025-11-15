########################################
# 1. Tell Terraform which cloud to use #
########################################

# This block says:
# "Hey Terraform, I want to work with AWS,
#    in the region us-east-2"
provider "aws" {
  region = "us-east-2"
}


########################################
# 2. Create an S3 bucket               #
########################################

# S3 bucket = a storage folder in the cloud.
# We give it a UNIQUE name (bucket names must be globally unique).
resource "aws_s3_bucket" "my_bucket" {
  bucket = "tech-challenge3-demo-bucket-12345"
}


#################################################
# 3. Create an IAM Role for our EC2 instance    #
#################################################

# IAM Role = permission card
# This lets the EC2 instance talk to AWS systems like SSM.

resource "aws_iam_role" "ec2_role" {
  name = "ec2_basic_role"

  # "assume_role_policy" = who is allowed to use this role?
  # Here we say: EC2 servers can use this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach a basic policy so EC2 can appear in AWS SSM
# This is SAFE and REQUIRED.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 instance profile = a “holder” for the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_basic_profile"
  role = aws_iam_role.ec2_role.name
}



########################################
# 4. Create a Security Group           #
########################################

# Security group = a firewall.
# It controls who can enter your EC2 machine.

resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  # Allow SSH (so Ansible can connect)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (so people can visit the website)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic (normal)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



########################################
# 5. Get the default VPC information   #
########################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


########################################
# 6. Create the EC2 instance           #
########################################

# This creates our virtual computer.
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id   # The OS image
instance_type = "t3.micro"

  subnet_id = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  key_name               = "tech-challenge3-key"  # This is your .pem key NAME in AWS
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # EC2 tags = name label for easier identification
  tags = {
    Name = "tech-challenge3-webserver"
  }
}


##################################################
# 7. Choose the correct Amazon Linux 2023 AMI    #
##################################################

# This block finds the AMI ID automatically
data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}



