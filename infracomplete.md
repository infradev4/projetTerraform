# Mini-projet

## Déployez une infracomplète
```txt
◦ Ecrivez un module pour créer une instance ec2 utilisant la dernière version de ubuntu bionic (qui s’attachera l’ebs et l’ip publique) dont la taille et le tag seront variabilisés

◦ Ecrivez un module pour créer un volume ebs dont la taille sera variabilisée

◦ Ecrivez un module pour une ip publique 

◦ Ecrivez un module pour créer une security qui ouvrira le 80 et 443

◦ Créez un dossier app qui vautiliser les 4 modules pour déployer une ec2,bien-sûr vous allez surcharger les variables afinde rendre votre application plus dynamique

◦ A la fin du déploiement, installez nginx et enregistrez l’ippublique dans un fichier nommé ip_ec2.txt (ces éléments sont àintégrer dans le module ec2)

◦ A la fin de votre travail,poussez votre rôle sur github, rédigez un rapport détaillé de vos travaux et envoyez nous ce rapportà travers l’intranet de votreétablissementet nous vous dirons si votre solution respecte les bonnes pratiques
```

# Création du module EC2
## Ecrivez un module pour créer une instance avec la dernière version de ubuntu bionic 

```ruby
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
```
![Screenshot](images\a.jpg)
![Screenshot](images\h.jpg)
# Création du module Network
## Ecrivez un module pour une ip publique
```ruby
#Fournit une ressource IP Elastic
resource "aws_eip" "lb" {
  vpc      = true
  tags = {
    Name = "${var.product}.${var.environment}.${var.author}-eip"
  }
}
```
![Screenshot](images\g.jpg)


# Création du module Security Group
## Ecrivez un module pour créer une security qui ouvrira le 80 et 443
```ruby
#Fournit une ressource de groupe de sécurité
resource "aws_security_group" "myec2-sg" {
  name        = "${var.product}.${var.environment}-myec2-sg"
  description = "Allow ssh http https traffic"
  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all port"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Si Terraform ne peut pas effectuer de mise à jour, son comportement par défaut consiste à détruire d'abord la ressource, puis à la recréer. 
  # Il créera d'abord la ressource mise à jour, puis supprimera l'ancienne.

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.product}.${var.environment}-myec2-sg"
  }
}
```
![Screenshot](images\c.jpg)

# Création du module EBS
## Ecrivez un module pour créer un volume ebs dont la taille sera variabilisée
```ruby
# Gère un volume EBS
resource "aws_ebs_volume" "myec2-data" {
  #La zone de disponibilité où le volume EBS existera
  #us-east-1a
  availability_zone = var.zone
  #La taille du lecteur en Gio (1Gb)
  size              = var.ebs_size

  tags = {
    Name = "${var.product}.${var.environment}-myec2-data"
  }
}
```
![Screenshot](images\d.jpg)

# Appel des modules dans main.tf 
```ruby
provider "aws" {
  region     = "us-east-1"
  access_key = "XXXXXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXX"
}
#call of the backend
#block storage service
terraform {
  backend "s3" {
    bucket = "oussama-bucket-tp5"
    key    = "oussama-dev.tfstate"
    region = "us-east-1"
    access_key = "XXXXXXXXXXXXXXXXXXXXX"
    secret_key = "XXXXXXXXXXXXXXXXXXXXX"
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

#Fournit un rattachement de volume AWS EBS en tant que ressource pour attacher des volumes à des instances AWS.
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdh"
  volume_id   = module.ebs_volume.ebs-id
  instance_id = module.ec2.ec2-id
}
resource "aws_eip_association" "eip_association" {
  instance_id   = module.ec2.ec2-id
  allocation_id = module.network.eip-id
}
```
![Screenshot](images\e.jpg)
![Screenshot](images\f.jpg)





- terraform.exe init
- terraform.exe plan
- terraform apply -auto-approve

```ruby
Plan: 3 to add, 0 to change, 0 to destroy.
module.ec2.aws_instance.myec2: Creating...
module.ec2.aws_instance.myec2: Still creating... [10s elapsed]
module.ec2.aws_instance.myec2: Still creating... [20s elapsed]
module.ec2.aws_instance.myec2: Creation complete after 27s [id=i-00a93508ced71b2b3]
aws_eip_association.eip_assoc: Creating...
aws_volume_attachment.ebs_att: Creating...
aws_eip_association.eip_assoc: Creation complete after 2s [id=eipassoc-00c46a24f2ee8d235]
aws_volume_attachment.ebs_att: Still creating... [10s elapsed]
aws_volume_attachment.ebs_att: Still creating... [20s elapsed]
aws_volume_attachment.ebs_att: Creation complete after 23s [id=vai-982945743]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

![Screenshot](images\nginx.jpg)