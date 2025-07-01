# modules/load-balancer/outputs.tf
# Définition des valeurs de sortie du module load-balancer
# Ces outputs permettent aux autres modules et environnements d'utiliser l'ALB

# ========================================
# OUTPUTS DE L'APPLICATION LOAD BALANCER
# ========================================

# ARN unique de l'ALB - identifiant complet de la ressource dans AWS
# Utilisé pour: référencer l'ALB dans d'autres ressources, IAM policies, etc.
output "alb_arn" {
  description = "Amazon Resource Name (ARN) de l'Application Load Balancer"
  value       = aws_lb.main.arn
}

# Nom DNS de l'ALB - URL principale pour accéder à l'application
# Format: nom-alb-123456789.region.elb.amazonaws.com
# C'est l'URL que les utilisateurs utiliseront pour accéder au site
output "alb_dns_name" {
  description = "Nom DNS de l'Application Load Balancer (URL d'accès)"
  value       = aws_lb.main.dns_name
}

# Zone ID de l'ALB - nécessaire pour créer des enregistrements DNS (Route 53)
# Utilisé pour: associer un nom de domaine personnalisé à l'ALB
output "alb_zone_id" {
  description = "Zone ID de l'ALB pour les enregistrements DNS (Route 53)"
  value       = aws_lb.main.zone_id
}

# ID du Security Group de l'ALB - peut être référencé par d'autres ressources
# Utilisé pour: permettre à d'autres services de communiquer avec l'ALB
output "alb_security_group_id" {
  description = "ID du Security Group attaché à l'Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

# ========================================
# OUTPUTS DU TARGET GROUP
# ========================================

# ARN du Target Group - ESSENTIEL pour l'Auto Scaling Group
# L'ASG utilise cet ARN pour enregistrer automatiquement ses instances
output "target_group_arn" {
  description = "ARN du Target Group (nécessaire pour l'Auto Scaling Group)"
  value       = aws_lb_target_group.web.arn
}

# Nom du Target Group - utile pour l'administration et les logs
# Permet d'identifier facilement le target group dans la console AWS
output "target_group_name" {
  description = "Nom du Target Group créé"
  value       = aws_lb_target_group.web.name
}

# ========================================
# OUTPUTS DU LISTENER
# ========================================

# ARN du Listener HTTP - peut être utile pour des configurations avancées
# Utilisé pour: créer des règles de routage personnalisées
output "alb_listener_arn" {
  description = "ARN du Listener HTTP (port 80) de l'ALB"
  value       = aws_lb_listener.web.arn
}

# ========================================
# OUTPUTS PRATIQUES POUR LES UTILISATEURS
# ========================================

# URL complète pour accéder à l'application
# Format: http://nom-dns-alb - directement utilisable dans un navigateur
output "alb_url" {
  description = "URL complète pour accéder à l'application via l'ALB"
  value       = "http://${aws_lb.main.dns_name}"
}