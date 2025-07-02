# environments/prod/variables.tf
# Variables de configuration pour l'environnement de PRODUCTION
# Ces variables définissent la configuration sécurisée et optimisée pour la production
# ATTENTION: Modifications à faire avec précaution - impact sur les utilisateurs!

# ========================================
# VARIABLES DE CONFIGURATION AWS PRODUCTION
# ========================================

# Région AWS pour l'infrastructure de production
# Choisir une région proche des utilisateurs finaux pour minimiser la latence
# Considérer: conformité RGPD, résilience, coûts
variable "aws_region" {
  description = "Région AWS pour le déploiement de production (proche des utilisateurs)"
  type        = string
  default     = "us-east-1"  # Région principale (peut être changée selon les besoins)
  
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
# VARIABLES D'IDENTIFICATION DU PROJET PRODUCTION
# ========================================

# Nom du projet - utilisé pour créer des noms de ressources uniques en production
# IMPORTANT: Changements impactés sur tous les noms de ressources
variable "project_name" {
  description = "Nom du projet utilisé pour le naming des ressources de production"
  type        = string
  default     = "terraform-modular"  # Nom du projet
  
  validation {
    condition = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Le nom du projet doit contenir entre 3 et 30 caractères."
  }
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Le nom du projet ne peut contenir que des lettres minuscules, chiffres et tirets (ex: mon-projet, webapp-2024)."
  }
}

# Environnement de production - critique pour la séparation des ressources
# Utilisé dans les noms de ressources et les tags pour isoler la production
variable "environment" {
  description = "Nom de l'environnement (PRODUCTION)"
  type        = string
  default     = "prod"  # Environnement de production
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod'."
  }
}

# ========================================
# CONFIGURATION RÉSEAU PRODUCTION
# ========================================

# Plage d'adresses IP privées pour le VPC de production
# /16 = 65,536 adresses - suffisant pour une grande infrastructure
# Séparé du dev pour éviter les conflits d'adressage
variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC de production (isolé du dev)"
  type        = string
  default     = "10.0.0.0/16"  # Plage standard pour la production
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Le vpc_cidr doit être un bloc CIDR valide (ex: 10.0.0.0/16, 172.16.0.0/12, 192.168.0.0/16)."
  }
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0)) && can(tonumber(split("/", var.vpc_cidr)[1])) && tonumber(split("/", var.vpc_cidr)[1]) <= 28 && tonumber(split("/", var.vpc_cidr)[1]) >= 16
    error_message = "Le masque de sous-réseau doit être entre /16 et /28 pour avoir assez d'adresses IP (recommandé: /16 à /24)."
  }
}

# ========================================
# CONFIGURATION DES INSTANCES EC2 PRODUCTION
# ========================================

# Type d'instance EC2 pour la production
# t2.micro = identique au dev pour cette démo (en réalité, souvent plus puissant)
# Exemples production réels: t3.small, t3.medium, c5.large selon les besoins
variable "instance_type" {
  description = "Type d'instance EC2 pour la production (CPU, RAM, performances)"
  type        = string
  default     = "t2.micro"  # Identique au dev pour cette démo
  
  validation {
    condition = can(regex("^[tm][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Le type d'instance doit être un type EC2 valide (ex: t2.micro, t3.small, m5.large, c5.xlarge)."
  }
}

# ========================================
# CONFIGURATION DE SÉCURITÉ RÉSEAU PRODUCTION
# ========================================

# Liste des adresses IP autorisées à accéder au Load Balancer
# PRODUCTION: Considérer restreindre à des IPs spécifiques si possible
# Exemple restreint: ["203.0.113.0/24", "198.51.100.0/24"]
variable "allowed_http_cidrs" {
  description = "Liste des blocs CIDR autorisés (PRODUCTION - considérer restreindre)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Tout Internet - adapter selon les besoins de sécurité
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_http_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Tous les éléments de allowed_http_cidrs doivent être des blocs CIDR valides (ex: '192.168.1.0/24', '10.0.0.1/32')."
  }
  
  validation {
    condition = length(var.allowed_http_cidrs) > 0
    error_message = "La liste allowed_http_cidrs ne peut pas être vide. Utilisez ['0.0.0.0/0'] pour autoriser tout Internet."
  }
}

# HTTPS OBLIGATOIRE en production pour la sécurité des données
# Chiffrement des communications utilisateur <-> Load Balancer
variable "enable_https" {
  description = "Activer HTTPS (OBLIGATOIRE en production pour la sécurité)"
  type        = bool
  default     = true  # TOUJOURS activé en production
}

# ========================================
# CONFIGURATION DU LOAD BALANCER PRODUCTION
# ========================================

# Chemin URL pour les vérifications de santé en production
# Peut être un endpoint dédié qui vérifie la base de données, services, etc.
variable "health_check_path" {
  description = "Chemin URL pour health checks production (peut être un endpoint dédié)"
  type        = string
  default     = "/"  # Page d'accueil - adapter selon l'application
  
  validation {
    condition = can(regex("^/.*", var.health_check_path))
    error_message = "Le chemin de health check doit commencer par '/' (ex: '/', '/health', '/api/status')."
  }
  
  validation {
    condition = length(var.health_check_path) <= 100
    error_message = "Le chemin de health check ne peut pas dépasser 100 caractères."
  }
}

# ========================================
# CONFIGURATION IP ÉLASTIQUE PRODUCTION
# ========================================

# Elastic IP NON utilisée en production avec Auto Scaling Group
# Les utilisateurs accèdent via l'URL du Load Balancer, pas directement aux instances
variable "create_eip" {
  description = "Créer une IP élastique (NON recommandé avec Auto Scaling)"
  type        = bool
  default     = false  # Toujours false avec ASG
}

# ========================================
# CONFIGURATION AUTO SCALING GROUP PRODUCTION
# ========================================

# Auto Scaling Group OBLIGATOIRE en production
# Assure haute disponibilité, résilience et gestion automatique des pannes
variable "enable_auto_scaling" {
  description = "Activer Auto Scaling Group (OBLIGATOIRE en production)"
  type        = bool
  default     = true  # TOUJOURS activé en production
}

# Nombre minimum d'instances - assure la continuité de service
# PRODUCTION: Au moins 2 pour éviter un point de défaillance unique
variable "asg_min_size" {
  description = "Nombre MINIMUM d'instances (résilience - au moins 2 en prod)"
  type        = number
  default     = 2  # Minimum pour haute disponibilité
  
  validation {
    condition = var.asg_min_size >= 1 && var.asg_min_size <= 6
    error_message = "asg_min_size doit être entre 1 et 6 instances (recommandé: minimum 2 pour la haute disponibilité en production)."
  }
}

# Nombre maximum d'instances - limite les coûts et contrôle l'échelle
# PRODUCTION: Définir selon la charge maximale attendue
variable "asg_max_size" {
  description = "Nombre MAXIMUM d'instances (contrôle des coûts)"
  type        = number
  default     = 4  # Limite raisonnable pour cette démo
  
  validation {
    condition = var.asg_max_size >= 1 && var.asg_max_size <= 6
    error_message = "asg_max_size doit être entre 1 et 6 instances."
  }
}

# Nombre d'instances cible en fonctionnement normal
# PRODUCTION: Calculer selon la charge habituelle + marge de sécurité
variable "asg_desired_capacity" {
  description = "Nombre DÉSIRÉ d'instances en fonctionnement normal"
  type        = number
  default     = 2  # 2 instances pour redondance
  
  validation {
    condition = var.asg_desired_capacity >= 1 && var.asg_desired_capacity <= 6
    error_message = "asg_desired_capacity doit être entre 1 et 6 instances."
  }
}

# ========================================
# TAGS ET MÉTADONNÉES PRODUCTION
# ========================================

# Tags CRITIQUES en production pour: facturation, conformité, audit, gouvernance
# Ces tags sont appliqués à TOUTES les ressources automatiquement
variable "common_tags" {
  description = "Tags communs OBLIGATOIRES pour toutes les ressources de production"
  type        = map(string)  # Dictionnaire clé-valeur
  default = {
    # Indique que cette ressource est gérée par Terraform
    Terraform   = "true"
    
    # Nom du projet pour regroupement et facturation
    Project     = "terraform-modular"
    
    # Environnement PRODUCTION - critique pour la séparation
    Environment = "prod"
    
    # Tags additionnels recommandés en production (décommenter si nécessaire) :
    # Owner       = "equipe-prod"          # Responsable de la ressource
    # CostCenter  = "IT-Production"        # Centre de coût pour facturation
    # Backup      = "daily"                # Politique de sauvegarde
    # Monitoring  = "critical"             # Niveau de surveillance
    # Compliance  = "SOC2"                 # Exigences de conformité
  }
}