# modules/networking/variables.tf
# Définition des variables d'entrée pour le module networking
# Ces variables permettent de personnaliser le comportement du module

# ========================================
# VARIABLES OBLIGATOIRES
# ========================================

# Nom du projet - utilisé pour créer des noms de ressources uniques
# Exemple: "mon-app" donnera "mon-app-dev-vpc", "mon-app-dev-sg", etc.
variable "project_name" {
  description = "Nom du projet utilisé pour le naming des ressources"
  type        = string
  # OBLIGATOIRE: aucune valeur par défaut
  
  validation {
    condition = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Le nom du projet doit contenir entre 3 et 30 caractères."
  }
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Le nom du projet ne peut contenir que des lettres minuscules, chiffres et tirets (ex: mon-projet, webapp-2024)."
  }
}

# Environnement (dev, staging, prod) - utilisé pour séparer les environnements
# Permet d'avoir des ressources distinctes pour chaque environnement
variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  # OBLIGATOIRE: aucune valeur par défaut
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod'."
  }
}

# ========================================
# VARIABLES OPTIONNELLES AVEC VALEURS PAR DÉFAUT
# ========================================

# Plage d'adresses IP pour le VPC (notation CIDR)
# 10.0.0.0/16 fournit 65,536 adresses IP (10.0.0.0 à 10.0.255.255)
variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC (ex: 10.0.0.0/16 pour 65k IPs)"
  type        = string
  default     = "10.0.0.0/16"  # Valeur par défaut si non spécifiée
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Le vpc_cidr doit être un bloc CIDR valide (ex: 10.0.0.0/16, 172.16.0.0/12, 192.168.0.0/16)."
  }
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0)) && can(tonumber(split("/", var.vpc_cidr)[1])) && tonumber(split("/", var.vpc_cidr)[1]) <= 28 && tonumber(split("/", var.vpc_cidr)[1]) >= 16
    error_message = "Le masque de sous-réseau doit être entre /16 et /28 pour avoir assez d'adresses IP (recommandé: /16 à /24)."
  }
}

# Liste des adresses IP autorisées à accéder aux services web (HTTP/HTTPS)
# Format CIDR: "1.2.3.4/32" (une IP) ou "1.2.3.0/24" (256 IPs)
variable "allowed_http_cidrs" {
  description = "Liste des blocs CIDR autorisés pour l'accès HTTP/HTTPS"
  type        = list(string)  # Liste de chaînes de caractères
  default     = ["0.0.0.0/0"]  # Par défaut: autoriser tout Internet (attention en prod!)
  
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

# Activer ou désactiver l'accès HTTPS (port 443)
# true = ouvre le port 443, false = seul HTTP (port 80) est ouvert
variable "enable_https" {
  description = "Activer l'accès HTTPS (port 443) dans le security group"
  type        = bool   # Valeur booléenne: true ou false
  default     = false  # Par défaut: HTTPS désactivé (plus sûr pour le dev)
}

# Tags communs à appliquer à toutes les ressources
# Les tags aident à organiser et suivre les coûts des ressources AWS
variable "common_tags" {
  description = "Tags communs à appliquer à toutes les ressources créées"
  type        = map(string)  # Dictionnaire clé-valeur
  default     = {}           # Par défaut: aucun tag (map vide)
}
