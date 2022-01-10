#Ecrivez un module pour une ip publique
#Fournit une ressource IP Elastic
resource "aws_eip" "lb" {
  vpc      = true
  tags = {
    Name = "${var.product}.${var.environment}.${var.author}-eip"
  }
}