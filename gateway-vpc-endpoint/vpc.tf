# We use the Terraform AWS VPC module to avoid having to specify too many details
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-with-a-gateway-endpoint"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Interface VPC endpoint to access the EC2 API
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = module.vpc.private_route_table_ids
}

# VPC endpoint policy allowing s3:Put, s3:Get, s3:List
resource "aws_vpc_endpoint_policy" "policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["s3:Put*", "s3:Get*", "s3:List*"],
        "Resource" : "*"
      }
    ]
  })
}
