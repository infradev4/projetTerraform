provider "aws" {
  region     = "us-east-1"
  access_key = "XXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXX"
}
#call of the backend
#block storage service
terraform {
  backend "s3" {
    bucket = "oussama-bucket-tp5"
    key    = "oussama-dev.tfstate"
    region = "us-east-1"
    access_key = "XXXXXXXXXXXXXXXXX"
    secret_key = "XXXXXXXXXXXXXXXXX"
  }
}

#call of the ebs_volume module 
module "ebs_volume" {
  source = "./modules/ebs"
  zone   = "us-east-1a"
}

#call of the ec2 instance module 
module "ec2" {
  source              = "./modules/ec2"
  instance_type       = "t2.nano"
  product             = "Nginx"
  environment         = "dev"
  security_group_name = module.securitygroup.sg-name
  aws_common_tag = {
    Name = "ec2-oussama-dev"
  }
}

#call of the network module 
module "network" {
  source      = "./modules/network"
  product     = "app"
  environment = "dev"
  #details     = "Allow IP Elastic resource"
}

#call of the security group module 
module "securitygroup" {
  source      = "./modules/securitygroup"
  product     = "app"
  environment = "dev"
  #details     = "Allow inbound and outbound traffic"
}


resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdh"
  volume_id   = module.ebs_volume.ebs-id
  instance_id = module.ec2.ec2-id
}
resource "aws_eip_association" "eip_association" {
  instance_id   = module.ec2.ec2-id
  allocation_id = module.network.eip-id
}

