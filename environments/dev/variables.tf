# environments/dev/variables.tf
# Variables de configuration pour l'environnement de développement
# Ces variables permettent de personnaliser le déploiement selon les besoins

# ========================================
# VARIABLES DE CONFIGURATION AWS
# ========================================

# Région AWS où déployer toute l'infrastructure
# Choisir une région proche des utilisateurs pour réduire la latence
variable "aws_region" {
  description = "Région AWS pour le déploiement (ex: us-east-1, eu-west-1)"
  type        = string
  default     = "us-east-1"  # Région par défaut (Virginie du Nord)
}

# ========================================
# VARIABLES D'IDENTIFICATION DU PROJET
# ========================================

# Nom du projet - utilisé pour créer des noms de ressources uniques
# Exemple: "mon-app" -> "mon-app-dev-vpc", "mon-app-dev-alb"
variable "project_name" {
  description = "Nom du projet utilisé pour le naming des ressources"
  type        = string
  default     = "terraform-modular"  # Nom par défaut du projet
}

# Environnement de déploiement - permet de séparer dev/staging/prod
# Utilisé dans les noms de ressources et les tags
variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod)"
  type        = string
  default     = "dev"  # Environnement de développement
}

# ========================================
# CONFIGURATION RÉSEAU
# ========================================

# Plage d'adresses IP privées pour le VPC
# /16 = 65,536 adresses (10.0.0.0 à 10.0.255.255)
variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC (plage d'adresses IP privées)"
  type        = string
  default     = "10.0.0.0/16"  # Standard pour un environnement de dev
}

# ========================================
# CONFIGURATION DES INSTANCES EC2
# ========================================

# Type d'instance EC2 déterminant les ressources (CPU, RAM, réseau)
# t2.micro = 1 vCPU, 1 GB RAM - idéal pour le développement
variable "instance_type" {
  description = "Type d'instance EC2 (détermine CPU, RAM, performances réseau)"
  type        = string
  default     = "t2.micro"  # Niveau gratuit AWS (Free Tier)
}

# ========================================
# CONFIGURATION DE SÉCURITÉ RÉSEAU
# ========================================

# Liste des adresses IP autorisées à accéder au Load Balancer
# Format CIDR: "192.168.1.0/24" (réseau) ou "203.0.113.1/32" (IP unique)
variable "allowed_http_cidrs" {
  description = "Liste des blocs CIDR autorisés pour l'accès HTTP/HTTPS au Load Balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Par défaut: tout Internet (attention en prod!)
}

# Activer ou désactiver le support HTTPS (port 443)
# En développement, souvent désactivé pour simplifier
variable "enable_https" {
  description = "Activer l'accès HTTPS (port 443) sur le Load Balancer"
  type        = bool
  default     = false  # Désactivé en dev (pas de certificat SSL requis)
}

# ========================================
# CONFIGURATION DU LOAD BALANCER
# ========================================

# Chemin URL utilisé par le Load Balancer pour vérifier la santé des instances
# Exemples: "/" (page d'accueil), "/health" (endpoint dédié), "/status"
variable "health_check_path" {
  description = "Chemin URL pour les vérifications de santé du Load Balancer"
  type        = string
  default     = "/"  # Page d'accueil par défaut
}

# ========================================
# CONFIGURATION IP ÉLASTIQUE
# ========================================

# Créer une Elastic IP (IP publique fixe) pour les instances standalone
# ATTENTION: Pas utilisée avec Auto Scaling Group (instances multiples)
variable "create_eip" {
  description = "Créer une IP élastique pour l'instance standalone"
  type        = bool
  default     = false  # Désactivé car on utilise l'Auto Scaling Group
}

# ========================================
# CONFIGURATION AUTO SCALING GROUP
# ========================================

# Activer l'Auto Scaling Group au lieu d'une instance EC2 unique
# ASG = Gestion automatique des instances (création, suppression, santé)
variable "enable_auto_scaling" {
  description = "Activer l'Auto Scaling Group pour la haute disponibilité"
  type        = bool
  default     = true  # Activé par défaut (architecture recommandée)
}

# Nombre minimum d'instances que l'ASG doit maintenir
# HAUTE DISPONIBILITÉ : Au moins 2 instances pour éviter le SPOF (Single Point of Failure)
variable "asg_min_size" {
  description = "Nombre minimum d'instances dans l'Auto Scaling Group (HA requis: min 2)"
  type        = number
  default     = 2  # MINIMUM 2 pour la haute disponibilité
}

# Nombre maximum d'instances que l'ASG peut créer
# Permet l'auto-scaling en cas de charge tout en limitant les coûts
variable "asg_max_size" {
  description = "Nombre maximum d'instances dans l'Auto Scaling Group"
  type        = number
  default     = 3  # Permet scaling jusqu'à 3 instances
}

# Nombre d'instances que l'ASG essaie de maintenir en permanence
# HAUTE DISPONIBILITÉ : 2 instances dans 2 AZ différentes
variable "asg_desired_capacity" {
  description = "Nombre désiré d'instances dans l'Auto Scaling Group (HA: 2 instances)"
  type        = number
  default     = 2  # 2 instances pour redondance multi-AZ
}

# ========================================
# TAGS ET MÉTADONNÉES
# ========================================

# Tags appliqués automatiquement à TOUTES les ressources créées
# Utiles pour: facturation, organisation, automation, conformité
variable "common_tags" {
  description = "Tags communs appliqués à toutes les ressources AWS"
  type        = map(string)  # Dictionnaire clé-valeur
  default = {
    # Indique que cette ressource est gérée par Terraform
    Terraform   = "true"
    
    # Nom du projet pour regrouper les ressources
    Project     = "terraform-modular"
    
    # Environnement pour séparer dev/staging/prod
    Environment = "dev"
    
    # Autres tags utiles (décommentés si nécessaire) :
    # Owner       = "equipe-dev"
    # CostCenter  = "IT-Development"
    # Backup      = "daily"
  }
}