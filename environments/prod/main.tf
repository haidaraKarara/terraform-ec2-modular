# environments/prod/main.tf
# Configuration de l'environnement de production
# Ce fichier orchestre le déploiement de tous les modules pour créer une infrastructure complète
# ATTENTION: Environnement de production - modifications avec précaution!

# ========================================
# CONFIGURATION DU PROVIDER AWS
# ========================================

# Le provider AWS définit comment Terraform communique avec les services AWS
# C'est le point d'entrée pour toutes les opérations AWS dans cet environnement
provider "aws" {
  # Région AWS où déployer toute l'infrastructure de production
  # Choisir une région proche des utilisateurs finaux
  region = var.aws_region

  # ========================================
  # TAGS PAR DÉFAUT POUR TOUTES LES RESSOURCES
  # ========================================
  
  # Ces tags sont automatiquement appliqués à TOUTES les ressources créées
  # CRITIQUE en production pour: facturation, conformité, audit, gouvernance
  default_tags {
    tags = var.common_tags  # Tags définis dans variables.tf
  }
}

# ========================================
# MODULE RÉSEAU ET SÉCURITÉ (NETWORKING)
# ========================================

# Le module networking crée l'infrastructure réseau de production :
# - VPC (réseau privé virtuel) isolé et sécurisé
# - Sous-réseaux publics dans plusieurs zones de disponibilité (haute disponibilité)
# - Internet Gateway pour l'accès Internet
# - Tables de routage optimisées
# - Security Groups (firewall) avec règles strictes
module "networking" {
  # Chemin vers le code du module networking
  source = "../../modules/networking"

  # Variables passées au module networking
  project_name       = var.project_name        # Nom du projet pour le naming
  environment        = var.environment         # Environnement (prod)
  vpc_cidr           = var.vpc_cidr            # Plage d'IPs du VPC production
  allowed_http_cidrs = var.allowed_http_cidrs  # IPs autorisées (restreintes en prod)
  enable_https       = var.enable_https       # HTTPS activé (obligatoire en prod)
  common_tags        = var.common_tags         # Tags de production
}

# ========================================
# MODULE LOAD BALANCER (RÉPARTITION DE CHARGE PRODUCTION)
# ========================================

# Le module load_balancer crée un Application Load Balancer haute performance qui :
# - Reçoit le trafic depuis Internet avec gestion SSL/TLS
# - Distribue les requêtes sur plusieurs instances EC2 (haute disponibilité)
# - Vérifie la santé des instances avec health checks agressifs
# - Assure la disponibilité 24/7 de l'application
module "load_balancer" {
  # Chemin vers le code du module load-balancer
  source = "../../modules/load-balancer"
  
  # Variables de configuration de base
  project_name = var.project_name  # Nom du projet
  environment  = var.environment   # Environnement (prod)
  
  # Variables réseau (récupérées depuis le module networking)
  vpc_id            = module.networking.vpc_id      # ID du VPC production
  vpc_cidr          = var.vpc_cidr                  # CIDR du VPC
  public_subnet_ids = module.networking.subnet_ids  # IDs des sous-réseaux
  
  # Configuration du load balancer pour la production
  health_check_path = var.health_check_path  # Chemin de vérification de santé
  enable_https      = var.enable_https      # HTTPS OBLIGATOIRE en prod
  common_tags       = var.common_tags       # Tags de production
  
  # ========================================
  # DÉPENDANCES EXPLICITES
  # ========================================
  
  # Assure que le module networking est créé AVANT le load balancer
  # Critique en production pour éviter les erreurs de déploiement
  depends_on = [module.networking]
}

# ========================================
# MODULE COMPUTE (INSTANCES EC2 + AUTO SCALING PRODUCTION)
# ========================================

# Le module compute gère les instances EC2 de production qui hébergent l'application :
# - Auto Scaling Group pour la haute disponibilité et l'élasticité
# - Instances distribuées sur plusieurs zones de disponibilité
# - Configuration des rôles IAM pour Session Manager (sécurité renforcée)
# - Installation automatique et monitoring de l'application
# - Enregistrement automatique dans le Target Group du Load Balancer
module "compute" {
  # Chemin vers le code du module compute
  source = "../../modules/compute"

  # ========================================
  # CONFIGURATION DE BASE DES INSTANCES PRODUCTION
  # ========================================
  
  project_name = var.project_name  # Nom du projet
  environment  = var.environment   # Environnement (prod)
  instance_type = var.instance_type # Type d'instance (optimisé pour prod)
  
  # ========================================
  # CONFIGURATION RÉSEAU ET SÉCURITÉ
  # ========================================
  
  # Security Group créé par le module networking
  security_group_id = module.networking.security_group_id
  
  # Premier sous-réseau pour les instances standalone (si utilisées)
  subnet_id = module.networking.subnet_ids[0]
  
  # ========================================
  # CONFIGURATION PRODUCTION
  # ========================================
  
  create_eip  = var.create_eip   # Pas d'EIP en mode ASG
  common_tags = var.common_tags  # Tags de production
  
  # ========================================
  # CONFIGURATION AUTO SCALING GROUP PRODUCTION
  # ========================================
  
  # Auto Scaling Group OBLIGATOIRE en production
  enable_auto_scaling = var.enable_auto_scaling
  
  # TOUS les sous-réseaux pour distribution géographique
  subnet_ids = module.networking.subnet_ids
  
  # Target Group du Load Balancer pour enregistrement automatique
  target_group_arns = var.enable_auto_scaling ? [module.load_balancer.target_group_arn] : []
  
  # Paramètres de dimensionnement pour la production
  # Plus d'instances qu'en dev pour gérer la charge
  asg_min_size         = var.asg_min_size         # Minimum pour la résilience
  asg_max_size         = var.asg_max_size         # Maximum pour contrôler les coûts
  asg_desired_capacity = var.asg_desired_capacity # Capacité nominale

  # ========================================
  # DÉPENDANCES EXPLICITES CRITIQUES
  # ========================================
  
  # Assure que networking ET load_balancer sont prêts avant compute
  # ESSENTIEL en production pour éviter les échecs de déploiement
  depends_on = [module.networking, module.load_balancer]
}