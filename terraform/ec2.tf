data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

module "web_server" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "web-server"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.micro"
  subnet_id              = module.my_vpc.public_subnets[0]
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.public.id]
  key_name               = "wan-adri-key"
  create_eip             = true
  private_ip             = "10.0.0.5"
  iam_instance_profile   = aws_iam_instance_profile.web.name
  tags                   = { Name = "web-server" }
}

module "ansible_server" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "ansible-server"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.micro"
  subnet_id              = module.my_vpc.private_subnets[0]
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "wan-adri-key"
  private_ip             = "10.0.0.135"
  iam_instance_profile   = aws_iam_instance_profile.ansible.name
  tags                   = { Name = "ansible-server" }
}

module "monitoring_server" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 6.0"
  name                   = "monitoring-server"
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t3.micro"
  subnet_id              = module.my_vpc.private_subnets[0]
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "wan-adri-key"
  private_ip             = "10.0.0.136"
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name
  tags                   = { Name = "monitoring-server" }
}