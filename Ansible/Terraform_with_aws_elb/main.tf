
provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" { #teraform does not create this but only addppots it meaning this is only perculiar to aws and terraform cannot destroy it

}


//HTTP SERVER assesed on port 80, send TCP request to port 80, connect the tcp instance using SSH on port 22, allow access from everywhere by specify CIDR block [0.0.0.0]
//Security group creatiion

resource "aws_security_group" "http_server_sg" {
  name = "http_server_sg"
  #vpc_id = "vpc-03a46b591d969950b"
  vpc_id = aws_default_vpc.default.id
  ingress = [{ //allow traffic from anywhere
    description      = "TCP "
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    self             = false
    prefix_list_ids  = []
    security_groups  = []
    },
    { //allow traffic from anywhere
      description      = "Allow all incoming Traffic "
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      self             = false
      prefix_list_ids  = []
      security_groups  = []
  }]
  egress = [{
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/1"]
    ipv6_cidr_blocks = []
    self             = false
    prefix_list_ids  = []
    security_groups  = []
  }]
  tags = {
    name = "http_server_sg"
  }

}


resource "aws_security_group" "elb_sg" {
  name = "elb_sg"
  #vpc_id = "vpc-03a46b591d969950b"
  vpc_id = aws_default_vpc.default.id
  ingress = [{ //allow traffic from anywhere
    description      = "TCP "
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    self             = false
    prefix_list_ids  = []
    security_groups  = []
    },
    { //allow traffic from anywhere
      description      = "Allow all incoming Traffic "
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      self             = false
      prefix_list_ids  = []
      security_groups  = []
  }]
  egress = [{
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/1"]
    ipv6_cidr_blocks = []
    self             = false
    prefix_list_ids  = []
    security_groups  = []
  }]

}

resource "aws_elb" "elb" {
  name            = "elb"
  subnets         = data.aws_subnets.default_subnets.id
  security_groups = [aws_security_group.elb_sg.id]
  instances       = values(aws_instance.http_servers).*.id #this means which are the instances in which the load balancers should be distributing the load to
  #aws_instance.http_servers is a map so why we get the values like that, and then * means all of the values, . their ids

  listener { #which port on the load balancer should redirect to the port on the ec2 instance
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"

  }
}

resource "aws_instance" "http_servers" {
  # ami="ami-0715c1897453cabd1" 
  ami                    = data.aws_ami.aws_linux_2_latest.id
  key_name               = "default-ec2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  #subnet_id              = data.aws_subnets.default_subnets.ids[1]
  for_each  = toset(data.aws_subnets.default_subnets.ids) #since we have to execute before the terraform can get this value, we have to first of all apply with -target=data.aws_subnets.default_subnets   
  subnet_id = each.value                                  #To create multiple ec2 instances because there are about 5 or 6 subnets so we want to create an instance with each subnet

  tags = {
    name : "http_server_${each.value}"
  }
  connection { //to launch up a website
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)

  }

  provisioner "remote-exec" {
    inline = [
      "yum install httpd -y",
      "sudo service httpd start",
      # "echo welcome gbambor - virtual server is at ${self.public_dns} | sudo tee /var/www/html/index.html"
    ]

  }


}