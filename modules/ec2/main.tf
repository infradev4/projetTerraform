resource "aws_instance" "myec2" {
  ami                    = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  availability_zone      = var.zone
  tags                   = var.aws_common_tag
  security_groups        = ["${var.security_group_name}"]
  #installation de Nginx
  user_data = <<-EOF
      #!/bin/bash
      sudo apt-get update -y
      sudo apt-get -y install nginx
      sudo systemctl enable nginx
      sudo systemctl start nginx
  EOF

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.ssh_key_path)
    host = self.public_ip
  }
  provisioner "local-exec" {
    command = "echo '${aws_instance.myec2.tags.Name} [PUBLIC IP : ${self.public_ip} , ID: ${self.id} , AZ: ${self.availability_zone}]' >> ip-ec2.txt"
  }
}

#J'utilisez la source "data" pour obtenir l'ID d'une AMI enregistrée à utiliser dans (resource "aws_instance") ligne1.
#la dernière version de ubuntu bionic 
data "aws_ami" "app_ami" {
  most_recent = true
  owners = ["099720109477"]
  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-bionic*"]
    }
  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

