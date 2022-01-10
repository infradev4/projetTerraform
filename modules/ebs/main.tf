
# Ecrivez un module pour créer un volume ebs dont lataille sera variabilisée
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