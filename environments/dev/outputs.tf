# environments/dev/outputs.tf
# Valeurs de sortie de l'environnement de développement
# Ces outputs permettent de récupérer des informations importantes après le déploiement

# ========================================
# INFORMATIONS SUR LES INSTANCES EC2
# ========================================

# ID unique de l'instance EC2 (mode standalone uniquement)
# Utilisé pour: connexion SSH/SSM, debugging, monitoring
output "instance_id" {
  description = "ID de l'instance EC2 (si mode standalone activé)"
  value       = module.compute.instance_id
}

# Adresse IP publique de l'instance (si EIP créée)
# Permet l'accès direct à l'instance depuis Internet
output "instance_public_ip" {
  description = "Adresse IP publique de l'instance EC2"
  value       = module.compute.instance_public_ip
}

# Adresse IP privée de l'instance dans le VPC
# Utilisée pour la communication interne
output "instance_private_ip" {
  description = "Adresse IP privée de l'instance dans le VPC"
  value       = module.compute.instance_private_ip
}

# ========================================
# INFORMATIONS DE SÉCURITÉ
# ========================================

# ID du Security Group pour debugging et configuration
# Permet de vérifier les règles de firewall appliquées
output "security_group_id" {
  description = "ID du groupe de sécurité (firewall) des instances"
  value       = module.networking.security_group_id
}

# ========================================
# COMMANDES D'ACCÈS AUX INSTANCES
# ========================================

# Commande AWS CLI prête à utiliser pour se connecter aux instances
# Plus sécurisé que SSH : pas de clés à gérer, accès via IAM
output "ssm_session_command" {
  description = "Commande AWS CLI pour se connecter via Session Manager"
  value       = module.compute.ssm_session_command
}

# Regroupement des informations de connexion pour facilité d'usage
# Affiche toutes les infos nécessaires pour accéder aux instances
output "connection_info" {
  description = "Informations complètes de connexion aux instances"
  value = {
    ssm_command = module.compute.ssm_session_command
    instance_id = module.compute.instance_id
  }
}

# ========================================
# INFORMATIONS DU LOAD BALANCER
# ========================================

# Nom DNS de l'ALB - URL technique pour accéder à l'application
# Format: mon-app-dev-alb-123456789.us-east-1.elb.amazonaws.com
output "alb_dns_name" {
  description = "Nom DNS technique de l'Application Load Balancer"
  value       = module.load_balancer.alb_dns_name
}

# URL complète avec protocole - directement utilisable dans un navigateur
# C'est l'URL principale pour accéder à votre application web
output "alb_url" {
  description = "URL complète pour accéder à l'application (utilisez cette URL!)"
  value       = module.load_balancer.alb_url
}

# ARN du Target Group - information technique pour l'administration
# Utilisé par l'Auto Scaling Group pour enregistrer les instances
output "target_group_arn" {
  description = "ARN du Target Group (info technique)"
  value       = module.load_balancer.target_group_arn
}

# ========================================
# INFORMATIONS AUTO SCALING GROUP
# ========================================

# Indique le mode de déploiement actuel ("instance" ou "autoscaling")
# Aide à comprendre quelle architecture est active
output "deployment_type" {
  description = "Type de déploiement actuel (instance ou autoscaling)"
  value       = module.compute.deployment_type
}

# Nom de l'Auto Scaling Group - utile pour l'administration AWS
# Permet de gérer l'ASG via AWS CLI ou console
output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group (pour administration)"
  value       = module.compute.autoscaling_group_name
}

# ID du Launch Template - modèle utilisé pour créer les nouvelles instances
# Information technique pour le debugging
output "launch_template_id" {
  description = "ID du Launch Template utilisé par l'ASG"
  value       = module.compute.launch_template_id
}

# ========================================
# COMMANDES UTILES POUR L'ADMINISTRATION
# ========================================

# Commande AWS CLI pour lister toutes les instances de l'ASG
# Très utile car les IDs des instances changent avec l'Auto Scaling
output "get_instance_ids_command" {
  description = "Commande AWS CLI pour obtenir les IDs des instances actuelles"
  value       = module.compute.get_instance_ids_command
}