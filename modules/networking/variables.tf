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
}

# Environnement (dev, staging, prod) - utilisé pour séparer les environnements
# Permet d'avoir des ressources distinctes pour chaque environnement
variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  # OBLIGATOIRE: aucune valeur par défaut
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
}

# Liste des adresses IP autorisées à accéder aux services web (HTTP/HTTPS)
# Format CIDR: "1.2.3.4/32" (une IP) ou "1.2.3.0/24" (256 IPs)
variable "allowed_http_cidrs" {
  description = "Liste des blocs CIDR autorisés pour l'accès HTTP/HTTPS"
  type        = list(string)  # Liste de chaînes de caractères
  default     = ["0.0.0.0/0"]  # Par défaut: autoriser tout Internet (attention en prod!)
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
