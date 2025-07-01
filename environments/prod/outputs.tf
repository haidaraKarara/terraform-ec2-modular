# environments/prod/outputs.tf
# Valeurs de sortie de l'environnement de PRODUCTION
# Ces outputs fournissent les informations critiques après le déploiement
# IMPORTANT: Ces informations peuvent être sensibles - accès restreint!

# ========================================
# INFORMATIONS SUR LES INSTANCES EC2 PRODUCTION
# ========================================

# ID unique de l'instance EC2 (mode standalone - rare en production)
# En production, utilisez plutôt get_instance_ids_command pour l'ASG
output "instance_id" {
  description = "ID de l'instance EC2 (si mode standalone - rare en prod)"
  value       = module.compute.instance_id
}

# Adresse IP publique de l'instance (si EIP créée)
# En production, les utilisateurs accèdent via l'URL du Load Balancer
output "instance_public_ip" {
  description = "Adresse IP publique de l'instance EC2 (accès via ALB recommandé)"
  value       = module.compute.instance_public_ip
}

# Adresse IP privée de l'instance dans le VPC
# Utilisée pour la communication interne et le debugging
output "instance_private_ip" {
  description = "Adresse IP privée de l'instance dans le VPC de production"
  value       = module.compute.instance_private_ip
}

# ========================================
# INFORMATIONS DE SÉCURITÉ PRODUCTION
# ========================================

# ID du Security Group pour audit de sécurité et conformité
# Permet de vérifier les règles de firewall appliquées
output "security_group_id" {
  description = "ID du groupe de sécurité (audit et conformité)"
  value       = module.networking.security_group_id
}

# ========================================
# COMMANDES D'ACCÈS SÉCURISÉ PRODUCTION
# ========================================

# Commande AWS CLI pour accès sécurisé aux instances de production
# PRODUCTION: Accès restreint aux administrateurs autorisés uniquement
output "ssm_session_command" {
  description = "Commande AWS CLI pour accès sécurisé aux instances (admin seulement)"
  value       = module.compute.ssm_session_command
}

# Informations de connexion regroupées pour les administrateurs
# ATTENTION: Accès production - logs et auditabilité requis
output "connection_info" {
  description = "Informations de connexion pour administration (audité)"
  value = {
    ssm_command = module.compute.ssm_session_command
    instance_id = module.compute.instance_id
  }
}

# ========================================
# INFORMATIONS DU LOAD BALANCER PRODUCTION
# ========================================

# Nom DNS de l'ALB - URL technique de production
# Utilisez cette URL pour configurer des domaines personnalisés (Route 53)
output "alb_dns_name" {
  description = "Nom DNS de l'ALB production (pour configuration DNS)"
  value       = module.load_balancer.alb_dns_name
}

# URL complète de l'application de production
# URL PRINCIPALE que les utilisateurs finaux utiliseront
output "alb_url" {
  description = "URL DE PRODUCTION de l'application (utilisateurs finaux)"
  value       = module.load_balancer.alb_url
}

# ARN du Target Group - information technique pour l'administration
# Utilisé par l'Auto Scaling Group pour l'enregistrement automatique
output "target_group_arn" {
  description = "ARN du Target Group (information technique)"
  value       = module.load_balancer.target_group_arn
}

# ========================================
# INFORMATIONS AUTO SCALING GROUP PRODUCTION
# ========================================

# Type de déploiement actuel - doit être "autoscaling" en production
# Confirmation que l'architecture haute disponibilité est active
output "deployment_type" {
  description = "Type de déploiement actuel (doit être 'autoscaling' en prod)"
  value       = module.compute.deployment_type
}

# Nom de l'ASG - utile pour l'administration et le monitoring de production
# Permet les opérations de scaling manuel et surveillance
output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group de production"
  value       = module.compute.autoscaling_group_name
}

# ID du Launch Template - modèle pour créer les nouvelles instances
# Information technique pour les mises à jour et le debugging
output "launch_template_id" {
  description = "ID du Launch Template production"
  value       = module.compute.launch_template_id
}

# ========================================
# COMMANDES D'ADMINISTRATION PRODUCTION
# ========================================

# Commande pour lister les instances actives de production
# ESSENTIEL car les IDs changent avec l'Auto Scaling
output "get_instance_ids_command" {
  description = "Commande pour lister les instances de production actuelles"
  value       = module.compute.get_instance_ids_command
}