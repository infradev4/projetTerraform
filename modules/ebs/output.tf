#l'attribut suivant "id" sera exporté 
output "ebs-id" {
  description = "ID of EBS Volume"
  value       = aws_ebs_volume.myec2-data.id
}