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
  default     = "us-east-1" # Région par défaut (Virginie du Nord)

  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "ap-southeast-1", "ap-northeast-1", "ca-central-1"
    ], var.aws_region)
    error_message = "La région AWS doit être une région valide et supportée. Régions disponibles: us-east-1, us-east-2, us-west-1, us-west-2, eu-west-1, eu-west-2, eu-west-3, eu-central-1, ap-southeast-1, ap-northeast-1, ca-central-1."
  }
}

# ========================================
# VARIABLES D'IDENTIFICATION DU PROJET
# ========================================

# Nom du projet - utilisé pour créer des noms de ressources uniques
# Exemple: "mon-app" -> "mon-app-dev-vpc", "mon-app-dev-alb"
variable "project_name" {
  description = "Nom du projet utilisé pour le naming des ressources"
  type        = string
  default     = "terraform-modular" # Nom par défaut du projet

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Le nom du projet doit contenir entre 3 et 30 caractères."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Le nom du projet ne peut contenir que des lettres minuscules, chiffres et tirets (ex: mon-projet, webapp-2024)."
  }
}

# Environnement de déploiement - permet de séparer dev/staging/prod
# Utilisé dans les noms de ressources et les tags
variable "environment" {
  description = "Nom de l'environnement (dev, staging, prod)"
  type        = string
  default     = "dev" # Environnement de développement

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod'."
  }
}

# ========================================
# CONFIGURATION RÉSEAU
# ========================================

# Plage d'adresses IP privées pour le VPC
# /16 = 65,536 adresses (10.0.0.0 à 10.0.255.255)
variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC (plage d'adresses IP privées)"
  type        = string
  default     = "10.0.0.0/16" # Standard pour un environnement de dev

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Le vpc_cidr doit être un bloc CIDR valide (ex: 10.0.0.0/16, 172.16.0.0/12, 192.168.0.0/16)."
  }

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && can(tonumber(split("/", var.vpc_cidr)[1])) && tonumber(split("/", var.vpc_cidr)[1]) <= 28 && tonumber(split("/", var.vpc_cidr)[1]) >= 16
    error_message = "Le masque de sous-réseau doit être entre /16 et /28 pour avoir assez d'adresses IP (recommandé: /16 à /24)."
  }
}

# ========================================
# CONFIGURATION DES INSTANCES EC2
# ========================================

# Type d'instance EC2 déterminant les ressources (CPU, RAM, réseau)
# t2.micro = 1 vCPU, 1 GB RAM - idéal pour le développement
variable "instance_type" {
  description = "Type d'instance EC2 (détermine CPU, RAM, performances réseau)"
  type        = string
  default     = "t2.micro" # Niveau gratuit AWS (Free Tier)

  validation {
    condition     = can(regex("^[tm][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Le type d'instance doit être un type EC2 valide (ex: t2.micro, t3.small, m5.large, c5.xlarge)."
  }
}

# ========================================
# CONFIGURATION DE SÉCURITÉ RÉSEAU
# ========================================

# Liste des adresses IP autorisées à accéder au Load Balancer
# Format CIDR: "192.168.1.0/24" (réseau) ou "203.0.113.1/32" (IP unique)
variable "allowed_http_cidrs" {
  description = "Liste des blocs CIDR autorisés pour l'accès HTTP/HTTPS au Load Balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Par défaut: tout Internet (attention en prod!)

  validation {
    condition = alltrue([
      for cidr in var.allowed_http_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Tous les éléments de allowed_http_cidrs doivent être des blocs CIDR valides (ex: '192.168.1.0/24', '10.0.0.1/32')."
  }

  validation {
    condition     = length(var.allowed_http_cidrs) > 0
    error_message = "La liste allowed_http_cidrs ne peut pas être vide. Utilisez ['0.0.0.0/0'] pour autoriser tout Internet."
  }
}

# Activer ou désactiver le support HTTPS (port 443)
# En développement, souvent désactivé pour simplifier
variable "enable_https" {
  description = "Activer l'accès HTTPS (port 443) sur le Load Balancer"
  type        = bool
  default     = false # Désactivé en dev (pas de certificat SSL requis)
}

# ========================================
# CONFIGURATION DU LOAD BALANCER
# ========================================

# Chemin URL utilisé par le Load Balancer pour vérifier la santé des instances
# Exemples: "/" (page d'accueil), "/health" (endpoint dédié), "/status"
variable "health_check_path" {
  description = "Chemin URL pour les vérifications de santé du Load Balancer"
  type        = string
  default     = "/" # Page d'accueil par défaut

  validation {
    condition     = can(regex("^/.*", var.health_check_path))
    error_message = "Le chemin de health check doit commencer par '/' (ex: '/', '/health', '/api/status')."
  }

  validation {
    condition     = length(var.health_check_path) <= 100
    error_message = "Le chemin de health check ne peut pas dépasser 100 caractères."
  }
}

# ========================================
# CONFIGURATION IP ÉLASTIQUE
# ========================================

# Créer une Elastic IP (IP publique fixe) pour les instances standalone
# ATTENTION: Pas utilisée avec Auto Scaling Group (instances multiples)
variable "create_eip" {
  description = "Créer une IP élastique pour l'instance standalone"
  type        = bool
  default     = false # Désactivé car on utilise l'Auto Scaling Group
}

# ========================================
# CONFIGURATION AUTO SCALING GROUP
# ========================================

# Activer l'Auto Scaling Group au lieu d'une instance EC2 unique
# ASG = Gestion automatique des instances (création, suppression, santé)
variable "enable_auto_scaling" {
  description = "Activer l'Auto Scaling Group pour la haute disponibilité"
  type        = bool
  default     = true # Activé par défaut (architecture recommandée)
}

# Nombre minimum d'instances que l'ASG doit maintenir
# HAUTE DISPONIBILITÉ : Au moins 2 instances pour éviter le SPOF (Single Point of Failure)
variable "asg_min_size" {
  description = "Nombre minimum d'instances dans l'Auto Scaling Group (HA requis: min 2)"
  type        = number
  default     = 2 # MINIMUM 2 pour la haute disponibilité

  validation {
    condition     = var.asg_min_size >= 0 && var.asg_min_size <= 6
    error_message = "asg_min_size doit être entre 0 et 6 instances."
  }
}

# Nombre maximum d'instances que l'ASG peut créer
# Permet l'auto-scaling en cas de charge tout en limitant les coûts
variable "asg_max_size" {
  description = "Nombre maximum d'instances dans l'Auto Scaling Group"
  type        = number
  default     = 3 # Permet scaling jusqu'à 3 instances

  validation {
    condition     = var.asg_max_size >= 1 && var.asg_max_size <= 6
    error_message = "asg_max_size doit être entre 1 et 6 instances."
  }
}

# Nombre d'instances que l'ASG essaie de maintenir en permanence
# HAUTE DISPONIBILITÉ : 2 instances dans 2 AZ différentes
variable "asg_desired_capacity" {
  description = "Nombre désiré d'instances dans l'Auto Scaling Group (HA: 2 instances)"
  type        = number
  default     = 2 # 2 instances pour redondance multi-AZ

  validation {
    condition     = var.asg_desired_capacity >= 1 && var.asg_desired_capacity <= 6
    error_message = "asg_desired_capacity doit être entre 1 et 6 instances."
  }
}

# ========================================
# TAGS ET MÉTADONNÉES
# ========================================

# Tags appliqués automatiquement à TOUTES les ressources créées
# Utiles pour: facturation, organisation, automation, conformité
variable "common_tags" {
  description = "Tags communs appliqués à toutes les ressources AWS"
  type        = map(string) # Dictionnaire clé-valeur
  default = {
    # Indique que cette ressource est gérée par Terraform
    Terraform = "true"

    # Nom du projet pour regrouper les ressources
    Project = "terraform-modular"

    # Environnement pour séparer dev/staging/prod
    Environment = "dev"

    # Autres tags utiles (décommentés si nécessaire) :
    # Owner       = "equipe-dev"
    # CostCenter  = "IT-Development"
    # Backup      = "daily"
  }
}