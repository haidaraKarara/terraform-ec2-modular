# environments/dev/main.tf
# Configuration de l'environnement de développement
# Ce fichier orchestre le déploiement de tous les modules pour créer une infrastructure complète

# ========================================
# CONFIGURATION DU PROVIDER AWS
# ========================================

# Le provider AWS définit comment Terraform communique avec les services AWS
# C'est le point d'entrée pour toutes les opérations AWS dans cet environnement
provider "aws" {
  # Région AWS où déployer toutes les ressources
  # Exemple: "us-east-1", "eu-west-1", "ap-southeast-1"
  region = var.aws_region

  # ========================================
  # TAGS PAR DÉFAUT POUR TOUTES LES RESSOURCES
  # ========================================

  # Ces tags sont automatiquement appliqués à TOUTES les ressources créées
  # Très utile pour: facturation, organisation, conformité, automation
  default_tags {
    tags = var.common_tags # Tags définis dans variables.tf
  }
}

# ========================================
# MODULE RÉSEAU ET SÉCURITÉ (NETWORKING)
# ========================================

# Le module networking crée l'infrastructure réseau de base :
# - VPC (réseau privé virtuel)
# - Sous-réseaux publics dans plusieurs zones de disponibilité
# - Internet Gateway pour l'accès Internet
# - Tables de routage
# - Security Groups (firewall)
module "networking" {
  # Chemin vers le code du module networking
  source = "../../modules/networking"

  # Variables passées au module networking
  project_name       = var.project_name       # Nom du projet pour le naming
  environment        = var.environment        # Environnement (dev, prod)
  vpc_cidr           = var.vpc_cidr           # Plage d'IPs du VPC
  allowed_http_cidrs = var.allowed_http_cidrs # IPs autorisées pour HTTP/HTTPS
  enable_https       = var.enable_https       # Activer le port 443
  common_tags        = var.common_tags        # Tags à appliquer
}

# ========================================
# MODULE LOAD BALANCER (RÉPARTITION DE CHARGE)
# ========================================

# Le module load_balancer crée un Application Load Balancer qui :
# - Reçoit le trafic depuis Internet
# - Distribue les requêtes sur plusieurs instances EC2
# - Vérifie la santé des instances (health checks)
# - Assure la haute disponibilité de l'application
module "load_balancer" {
  # Chemin vers le code du module load-balancer
  source = "../../modules/load-balancer"

  # Variables de configuration de base
  project_name = var.project_name # Nom du projet
  environment  = var.environment  # Environnement (dev)

  # Variables réseau (récupérées depuis le module networking)
  vpc_id            = module.networking.vpc_id     # ID du VPC créé
  vpc_cidr          = var.vpc_cidr                 # CIDR du VPC
  public_subnet_ids = module.networking.subnet_ids # IDs des sous-réseaux

  # Configuration du load balancer
  health_check_path = var.health_check_path # Chemin pour vérifier la santé
  enable_https      = var.enable_https      # Activer HTTPS
  common_tags       = var.common_tags       # Tags à appliquer

  # ========================================
  # DÉPENDANCES EXPLICITES
  # ========================================

  # Assure que le module networking est créé AVANT le load balancer
  # Nécessaire car le LB a besoin du VPC et des sous-réseaux
  depends_on = [module.networking]
}

# ========================================
# MODULE COMPUTE (INSTANCES EC2 + AUTO SCALING)
# ========================================

# Le module compute gère les instances EC2 qui hébergent l'application :
# - Création des instances EC2 avec ou sans Auto Scaling
# - Configuration des rôles IAM pour Session Manager
# - Installation automatique d'Apache et de l'application
# - Enregistrement automatique dans le Target Group du Load Balancer
module "compute" {
  # Chemin vers le code du module compute
  source = "../../modules/compute"

  # ========================================
  # CONFIGURATION DE BASE DES INSTANCES
  # ========================================

  project_name  = var.project_name  # Nom du projet
  environment   = var.environment   # Environnement (dev)
  instance_type = var.instance_type # Type d'instance (t2.micro)

  # ========================================
  # CONFIGURATION RÉSEAU ET SÉCURITÉ
  # ========================================

  # Security Group créé par le module networking
  security_group_id = module.networking.security_group_id

  # Premier sous-réseau pour les instances standalone
  # [0] = prend le premier élément de la liste des sous-réseaux
  subnet_id = module.networking.subnet_ids[0]

  # ========================================
  # CONFIGURATION OPTIONNELLE
  # ========================================

  create_eip  = var.create_eip  # Créer une IP élastique
  common_tags = var.common_tags # Tags à appliquer

  # ========================================
  # CONFIGURATION AUTO SCALING GROUP
  # ========================================

  # Activer ou désactiver l'Auto Scaling Group
  enable_auto_scaling = var.enable_auto_scaling

  # TOUS les sous-réseaux pour distribuer les instances ASG
  subnet_ids = module.networking.subnet_ids

  # Target Group du Load Balancer pour enregistrer les instances
  # Logique conditionnelle: seulement si Auto Scaling est activé
  target_group_arns = var.enable_auto_scaling ? [module.load_balancer.target_group_arn] : []

  # Paramètres de dimensionnement de l'ASG
  asg_min_size         = var.asg_min_size         # Minimum d'instances
  asg_max_size         = var.asg_max_size         # Maximum d'instances
  asg_desired_capacity = var.asg_desired_capacity # Nombre désiré

  # ========================================
  # DÉPENDANCES EXPLICITES
  # ========================================

  # Assure que networking ET load_balancer sont créés avant compute
  # Nécessaire car les instances ont besoin du réseau et du target group
  depends_on = [module.networking, module.load_balancer]
}