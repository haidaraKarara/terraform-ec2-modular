# modules/networking/outputs.tf
# Définition des valeurs de sortie du module networking
# Ces outputs permettent aux autres modules d'utiliser les ressources créées

# ========================================
# OUTPUTS DU VPC
# ========================================

# ID unique du VPC créé - nécessaire pour attacher d'autres ressources
# Utilisé par: modules compute et load-balancer pour placer leurs ressources
output "vpc_id" {
  description = "Identifiant unique du VPC créé"
  value       = aws_vpc.main.id
}

# Bloc CIDR du VPC - utile pour configurer les règles de sécurité
# Permet de référencer la plage d'IPs du VPC dans d'autres ressources
output "vpc_cidr" {
  description = "Bloc CIDR du VPC (plage d'adresses IP)"
  value       = aws_vpc.main.cidr_block
}

# ========================================
# OUTPUTS DES SOUS-RÉSEAUX
# ========================================

# Liste des IDs de tous les sous-réseaux publics
# [*] = syntaxe pour récupérer l'attribut de TOUS les éléments de la liste
# Utilisé par: module compute pour placer les instances, load-balancer pour distribution
output "subnet_ids" {
  description = "Liste des identifiants des sous-réseaux publics"
  value       = aws_subnet.public[*].id
}

# Liste des blocs CIDR de tous les sous-réseaux
# Utile pour diagnostiquer les problèmes de réseau et configurer des VPN
output "subnet_cidrs" {
  description = "Liste des blocs CIDR des sous-réseaux publics"
  value       = aws_subnet.public[*].cidr_block
}

# ========================================
# OUTPUTS DES ZONES DE DISPONIBILITÉ
# ========================================

# Liste de toutes les zones de disponibilité disponibles dans la région
# Information utile pour comprendre la répartition géographique possible
output "availability_zones" {
  description = "Liste de toutes les zones de disponibilité de la région"
  value       = data.aws_availability_zones.available.names
}

# Zones de disponibilité où nos sous-réseaux sont effectivement déployés
# Confirme la répartition multi-AZ pour la haute disponibilité
output "subnet_availability_zones" {
  description = "Zones de disponibilité où sont déployés nos sous-réseaux"
  value       = aws_subnet.public[*].availability_zone
}

# ========================================
# OUTPUTS DE L'INTERNET GATEWAY
# ========================================

# ID de l'Internet Gateway - nécessaire pour des configurations réseau avancées
# Peut être utilisé pour créer des routes personnalisées
output "internet_gateway_id" {
  description = "Identifiant de la passerelle Internet (Internet Gateway)"
  value       = aws_internet_gateway.main.id
}

# ========================================
# OUTPUTS DU SECURITY GROUP
# ========================================

# ID du Security Group - ESSENTIEL pour attacher des instances EC2
# Sans cet ID, les instances ne pourraient pas utiliser ce firewall
output "security_group_id" {
  description = "Identifiant du groupe de sécurité (firewall) créé"
  value       = aws_security_group.ec2_sg.id
}

# Nom du Security Group - utile pour l'administration et le debugging
# Permet d'identifier facilement le security group dans la console AWS
output "security_group_name" {
  description = "Nom du groupe de sécurité créé"
  value       = aws_security_group.ec2_sg.name
}
