data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

resource "aws_network_interface" "iface" {
  subnet_id = module.vpc.private_subnets[0]
}

resource "aws_iam_role" "instance-role" {
  name = "my-instance-role-2"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  inline_policy {
    name   = "inline"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
              "s3:Get*", "s3:List*", "s3:CreateBucket"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
  }
}

# Allow instance to be managed through AWS SSM (since it doesn't have a public IP)
resource "aws_iam_role_policy_attachment" "rolepolicy" {
  role       = aws_iam_role.instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "my-instance-role-profile-2"
  role = aws_iam_role.instance-role.name
}

resource "aws_instance" "instance" {
  ami                  = data.aws_ami.amazon-2.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.instance.name
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.iface.id
  }
}