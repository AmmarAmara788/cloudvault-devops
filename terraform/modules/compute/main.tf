# ==========================================
# 1. Security Groups (The Matrix) - مدعومة مجاناً
# ==========================================

resource "aws_security_group" "lb_sg" {
  name   = "cloudvault-lb-sg-${var.environment}"
  vpc_id = var.vpc_id
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

resource "aws_security_group" "app_sg" {
  name   = "cloudvault-app-sg-${var.environment}"
  vpc_id = var.vpc_id
  ingress {
    description     = "Allow traffic ONLY from Load Balancer SG"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id] 
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "services_sg" {
  name   = "cloudvault-services-sg-${var.environment}"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}

resource "aws_security_group" "data_sg" {
  name   = "cloudvault-data-sg-${var.environment}"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.services_sg.id]
  }
}

# ==========================================
# 2. Compute Instance (Direct EC2 instead of ASG) - مدعوم مجاناً
# ==========================================
resource "aws_instance" "app_server" {
  ami           = "ami-df5de72bdb3b" # Mock AMI
  instance_type = "t2.micro"
  
  # نزرع السيرفر في أول شبكة خاصة
  subnet_id = var.app_subnet_ids[0]

  # نربط السيرفر بهوية الـ IAM
  iam_instance_profile = var.app_instance_profile_name
  
  # نربط السيرفر بصلاحيات الجدار الناري
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "cloudvault-app-server-${var.environment}"
  }
}