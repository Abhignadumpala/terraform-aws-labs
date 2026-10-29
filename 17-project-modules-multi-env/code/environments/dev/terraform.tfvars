region             = "eu-west-1"
environment        = "dev"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
ssh_cidr           = "203.0.113.10/32" # replace with YOUR IP: curl ifconfig.me, then add /32
instance_type      = "t3.micro"