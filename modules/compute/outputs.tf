# ========================================================================================================
# SORTIES (OUTPUTS) DU MODULE COMPUTE - INFORMATIONS POUR L'UTILISATEUR
# ========================================================================================================
#
# Les outputs permettent d'exposer des informations importantes après le déploiement.
# Ils peuvent être utilisés par d'autres modules ou affichés à l'utilisateur.
#
# LOGIQUE CONDITIONNELLE DANS LES OUTPUTS :
# - Si enable_auto_scaling = false : Affiche les infos de l'instance standalone
# - Si enable_auto_scaling = true : Affiche les infos de l'Auto Scaling Group
# - Utilise value = condition ? valeur_si_vrai : valeur_si_faux
# ========================================================================================================

# ========================================================================================================
# SECTION 1 : OUTPUTS POUR MODE STANDALONE (instance unique)
# ========================================================================================================

# ID DE L'INSTANCE EC2 STANDALONE
# L'ID d'instance est nécessaire pour se connecter via Session Manager
# LOGIQUE : Retourne l'ID seulement si enable_auto_scaling = false
output "instance_id" {
  description = "ID de l'instance EC2 standalone - nécessaire pour la connexion Session Manager (null si mode ASG)"
  value       = var.enable_auto_scaling ? null : aws_instance.web_server[0].id
}

# ADRESSE IP PUBLIQUE DE L'INSTANCE
# IP publique dynamique attribuée par AWS (change à chaque redémarrage)
# ALTERNATIVE : Utiliser une Elastic IP pour une adresse fixe
output "instance_public_ip" {
  description = "Adresse IP publique de l'instance standalone - change à chaque redémarrage (null si mode ASG)"
  value       = var.enable_auto_scaling ? null : aws_instance.web_server[0].public_ip
}

# ADRESSE IP PRIVÉE DE L'INSTANCE
# IP privée dans le VPC, utilisée pour la communication interne
# STABLE : Ne change pas tant que l'instance existe
output "instance_private_ip" {
  description = "Adresse IP privée de l'instance dans le VPC - stable tant que l'instance existe (null si mode ASG)"
  value       = var.enable_auto_scaling ? null : aws_instance.web_server[0].private_ip
}

# NOM DNS PUBLIC DE L'INSTANCE
# Nom DNS résolvable publiquement (ex: ec2-1-2-3-4.eu-west-1.compute.amazonaws.com)
# UTILISATION : Pour accéder à l'instance via navigateur web
output "instance_public_dns" {
  description = "Nom DNS public de l'instance - utilisable dans un navigateur web (null si mode ASG)"
  value       = var.enable_auto_scaling ? null : aws_instance.web_server[0].public_dns
}

# ELASTIC IP (SI CONFIGURÉE)
# Adresse IP publique fixe, ne change jamais
# DISPONIBLE SEULEMENT : Si create_eip = true ET enable_auto_scaling = false
output "elastic_ip" {
  description = "Adresse Elastic IP fixe (si configurée) - IP publique qui ne change jamais (null si pas configurée ou mode ASG)"
  value       = var.create_eip && !var.enable_auto_scaling ? aws_eip.web_server[0].public_ip : null
}

# ========================================================================================================
# SECTION 2 : COMMANDES D'ACCÈS ET DE GESTION
# ========================================================================================================

# COMMANDE SESSION MANAGER POUR CONNEXION
# Commande prête à utiliser pour se connecter à l'instance
# AVANTAGE : Pas besoin de connaître les IPs ou d'ouvrir le port SSH
output "ssm_session_command" {
  description = "Commande AWS CLI prête à utiliser pour se connecter via Session Manager - accès sécurisé sans SSH"
  value       = var.enable_auto_scaling ? "aws ssm start-session --target <instance-id> --region ${data.aws_region.current.name}" : "aws ssm start-session --target ${aws_instance.web_server[0].id} --region ${data.aws_region.current.name}"
}

# COMMANDE POUR LISTER LES INSTANCES ASG
# Permet de trouver les IDs des instances créées par l'Auto Scaling Group
# UTILISATION : En mode ASG, les instances sont créées/détruites dynamiquement
output "get_instance_ids_command" {
  description = "Commande AWS CLI pour obtenir les IDs des instances ASG - nécessaire car les instances ASG changent dynamiquement"
  value       = var.enable_auto_scaling ? "aws ec2 describe-instances --filters \"Name=tag:Project,Values=${var.project_name}\" \"Name=tag:Environment,Values=${var.environment}\" \"Name=instance-state-name,Values=running\" --query 'Reservations[*].Instances[*].InstanceId' --output text --region ${data.aws_region.current.name}" : null
}

# ========================================================================================================
# SECTION 3 : OUTPUTS POUR MODE AUTO SCALING GROUP
# ========================================================================================================

# ID DU LAUNCH TEMPLATE
# Identifiant unique du Launch Template créé pour l'ASG
# UTILISATION : Pour référencer le template dans d'autres ressources ou scripts
output "launch_template_id" {
  description = "ID du Launch Template utilisé par l'ASG - référence unique du template (null si mode standalone)"
  value       = var.enable_auto_scaling ? aws_launch_template.web_server[0].id : null
}

# VERSION DU LAUNCH TEMPLATE
# Numéro de version du Launch Template (incrémenté à chaque modification)
# UTILISATION : Pour vérifier quelle version est actuellement utilisée
output "launch_template_version" {
  description = "Version actuelle du Launch Template - incrémenté à chaque modification (null si mode standalone)"
  value       = var.enable_auto_scaling ? aws_launch_template.web_server[0].latest_version : null
}

# ID DE L'AUTO SCALING GROUP
# Identifiant unique de l'ASG
# UTILISATION : Pour les commandes AWS CLI de gestion de l'ASG
output "autoscaling_group_id" {
  description = "ID de l'Auto Scaling Group - identifiant unique pour les commandes AWS CLI (null si mode standalone)"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.web_server[0].id : null
}

# ARN DE L'AUTO SCALING GROUP
# Amazon Resource Name (identifiant global unique dans AWS)
# UTILISATION : Pour les permissions IAM et l'intégration avec d'autres services AWS
output "autoscaling_group_arn" {
  description = "ARN de l'Auto Scaling Group - identifiant global AWS pour permissions et intégrations (null si mode standalone)"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.web_server[0].arn : null
}

# NOM DE L'AUTO SCALING GROUP
# Nom lisible de l'ASG (utilisé dans la console AWS)
# UTILISATION : Pour identifier facilement l'ASG dans la console AWS
output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group - nom affiché dans la console AWS (null si mode standalone)"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.web_server[0].name : null
}

# ========================================================================================================
# SECTION 4 : OUTPUTS INFORMATIONNELS ET DE DÉBOGAGE
# ========================================================================================================

# TYPE DE DÉPLOIEMENT ACTUEL
# Indique quel mode de déploiement a été utilisé
# UTILISATION : Pour vérifier rapidement le mode de déploiement actuel
output "deployment_type" {
  description = "Type de déploiement utilisé - 'instance' pour standalone ou 'autoscaling' pour ASG"
  value       = var.enable_auto_scaling ? "autoscaling" : "instance"
}