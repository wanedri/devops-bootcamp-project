module "my_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "devops-vpc"
  cidr = "10.0.0.0/24"
  azs  = ["ap-southeast-1a"]

  public_subnets  = ["10.0.0.0/25"]
  public_subnet_names = ["devops-public-subnet"]
  private_subnets = ["10.0.0.128/25"]
  private_subnet_names = ["devops-private-subnet"]

  private_route_table_tags = {
    Name= "devops-private-route"
  }
  public_route_table_tags = {
    Name= "devops-public-route"
  }

  enable_nat_gateway      = true
  single_nat_gateway      = true

  igw_tags = {
    Name = "devops-igw"
  }

  nat_gateway_tags = {
    Name = "devops-ngw"
  }
}