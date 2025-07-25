# modules/load-balancer/variables.tf
# Définition des variables d'entrée pour le module load-balancer
# Ces variables permettent de personnaliser le comportement de l'ALB

# ========================================
# VARIABLES OBLIGATOIRES (FOURNIES PAR L'ENVIRONNEMENT)
# ========================================

# Nom du projet - utilisé pour nommer les ressources de manière unique
# Ex: "mon-app" -> "mon-app-dev-alb", "mon-app-prod-alb"
variable "project_name" {
  description = "Nom du projet utilisé pour le naming des ressources ALB"
  type        = string
  # OBLIGATOIRE: doit être fourni par l'environnement appelant
  
  validation {
    condition = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Le nom du projet doit contenir entre 3 et 30 caractères."
  }
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Le nom du projet ne peut contenir que des lettres minuscules, chiffres et tirets (ex: mon-projet, webapp-2024)."
  }
}

# Environnement de déploiement - permet la séparation des ressources
# Valeurs typiques: "dev", "staging", "prod"
variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  # OBLIGATOIRE: doit être fourni par l'environnement appelant
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod'."
  }
}

# ID du VPC où déployer l'ALB - fourni par le module networking
# L'ALB doit être dans le même VPC que les instances EC2
variable "vpc_id" {
  description = "Identifiant du VPC où déployer l'Application Load Balancer"
  type        = string
  # OBLIGATOIRE: fourni par module.networking.vpc_id
}

# Bloc CIDR du VPC - nécessaire pour les règles de security group
# Permet de limiter le trafic de l'ALB vers les instances du VPC uniquement
variable "vpc_cidr" {
  description = "Bloc CIDR du VPC pour les règles de sécurité"
  type        = string
  # OBLIGATOIRE: fourni par la configuration de l'environnement
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Le vpc_cidr doit être un bloc CIDR valide (ex: 10.0.0.0/16, 172.16.0.0/12, 192.168.0.0/16)."
  }
}

# IDs des sous-réseaux publics - fournis par le module networking
# L'ALB a besoin d'au moins 2 sous-réseaux dans des AZ différentes
variable "public_subnet_ids" {
  description = "Liste des IDs des sous-réseaux publics pour déployer l'ALB"
  type        = list(string)
  # OBLIGATOIRE: fourni par module.networking.subnet_ids
}

# ========================================
# VARIABLES OPTIONNELLES AVEC VALEURS PAR DÉFAUT
# ========================================

# Chemin URL pour les vérifications de santé des instances
# L'ALB vérifie ce chemin pour déterminer si une instance est saine
variable "health_check_path" {
  description = "Chemin URL pour les health checks (ex: '/', '/health', '/status')"
  type        = string
  default     = "/"  # Par défaut: page d'accueil
  
  validation {
    condition = can(regex("^/.*", var.health_check_path))
    error_message = "Le chemin de health check doit commencer par '/' (ex: '/', '/health', '/api/status')."
  }
  
  validation {
    condition = length(var.health_check_path) <= 100
    error_message = "Le chemin de health check ne peut pas dépasser 100 caractères."
  }
}

# Activer ou désactiver le support HTTPS (port 443)
# En dev: souvent désactivé, en prod: recommandé
variable "enable_https" {
  description = "Activer le listener HTTPS (port 443) sur l'ALB"
  type        = bool
  default     = false  # Par défaut: HTTPS désactivé
}

# ARN du certificat SSL pour HTTPS - nécessaire si enable_https = true
# Doit être créé dans AWS Certificate Manager (ACM)
variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL (AWS Certificate Manager) pour HTTPS"
  type        = string
  default     = ""  # Vide par défaut (requis seulement si HTTPS activé)
}

# Protection contre la suppression accidentelle de l'ALB
# Recommandé en production pour éviter les suppressions catastrophiques
variable "enable_deletion_protection" {
  description = "Activer la protection contre la suppression accidentelle de l'ALB"
  type        = bool
  default     = false  # Désactivé par défaut (plus pratique pour dev/test)
}

# Tags communs à appliquer à toutes les ressources ALB
# Hérités de l'environnement pour une gestion centralisée
variable "common_tags" {
  description = "Tags communs à appliquer à toutes les ressources du load balancer"
  type        = map(string)
  default     = {}  # Map vide par défaut
}