# We use the Terraform AWS VPC module to avoid having to specify too many details
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-with-an-interface-endpoint"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Interface VPC endpoint to access the EC2 API
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc-endpoint.id]
  service_name        = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
}

# VPC endpoint policy allowing ec2:*
resource "aws_vpc_endpoint_policy" "policy" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["ec2:Create*", "ec2:Describe*"],
        "Resource" : "*"
      }
    ]
  })
}

# Security group for the VPC endpoint
# We allow anything in our private subnets to hit it (this is generally the case)
resource "aws_security_group" "vpc-endpoint" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}
