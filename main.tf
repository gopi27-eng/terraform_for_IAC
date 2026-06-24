# 1. Create the Custom VPC (The isolated virtual datacenter)
resource "aws_vpc" "my_custom_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "MyProject-VPC"
  }
}

# 2. Create Public Subnet 1 (In Availability Zone A)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_custom_vpc.id # Links directly to the VPC above
  cidr_block              = var.subnet_1_cidr
  availability_zone       = "${var.aws_region}a"     # Evaluates to us-east-1a
  map_public_ip_on_launch = true                     # Automatically gives EC2 instances a public IP

  tags = {
    Name = "Public-Subnet-1"
  }
}

# 3. Create Public Subnet 2 (In Availability Zone B for High Availability)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_custom_vpc.id 
  cidr_block              = var.subnet_2_cidr
  availability_zone       = "${var.aws_region}b"     # Evaluates to us-east-1b
  map_public_ip_on_launch = true                     

  tags = {
    Name = "Public-Subnet-2"
  }
}

# 4. Create the Internet Gateway (The door allowing internet traffic inside our VPC)
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_custom_vpc.id

  tags = {
    Name = "MyProject-IGW"
  }
}

# 5. Create a Route Table (The map directing where network traffic goes)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_custom_vpc.id

  # This route says: Send ALL external traffic (0.0.0.0/0) straight to our Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Public-RouteTable"
  }
}

# 6. Associate Route Table with Subnet 1 (Applies the map to Subnet 1)
resource "aws_route_table_association" "rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. Associate Route Table with Subnet 2 (Applies the map to Subnet 2)
resource "aws_route_table_association" "rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 1. Create a Security Group (The Virtual Firewall)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.my_custom_vpc.id # Links to our custom VPC

  # Inbound Rule: Allow HTTP Web traffic (Port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound Rule: Allow SSH Terminal access (Port 22) from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rule: Allow the server to download packages from the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-Traffic-SG"
  }
}

# 2. Create Web Server 1 (Deploys in Subnet 1)
resource "aws_instance" "web_server_1" {
  ami                    = "ami-0199ac7c9fbf9ed83" # Ubuntu 22.04 LTS AMI ID (Change based on your region if needed)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id] # Attaches the firewall above

  # Inject the first bootstrap shell script
  user_data = file("${path.module}/user_data1.sh")

  tags = {
    Name = "WebServer-1"
  }
}

# 3. Create Web Server 2 (Deploys in Subnet 2 for High Availability)
resource "aws_instance" "web_server_2" {
  ami                    = "ami-0199ac7c9fbf9ed83" # Ubuntu 22.04 LTS AMI ID (Change based on your region if needed)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id] 

  # Inject the second bootstrap shell script
  user_data = file("${path.module}/user_data2.sh")

  tags = {
    Name = "WebServer-2"
  }
}

# 1. Create the Application Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-project-alb"
  internal           = false # Public-facing on the internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id] # Uses the firewall we created in Step 5
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # Spans both network zones

  tags = {
    Name = "MyProject-ALB"
  }
}

# 2. Create the Target Group (The logical routing container)
resource "aws_lb_target_group" "my_tg" {
  name     = "my-project-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_custom_vpc.id

  # Health Check config: Checks if the web servers are still alive every 30 seconds
  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 3. Attach Web Server 1 to the Target Group
resource "aws_lb_target_group_attachment" "attach_server_1" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

# 4. Attach Web Server 2 to the Target Group
resource "aws_lb_target_group_attachment" "attach_server_2" {
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# 5. Create the ALB Listener (Directs external port 80 traffic into our target group container)
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}