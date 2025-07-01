# environments/dev/versions.tf
# Configuration centralisée des providers et contraintes de versions
# Ce fichier assure la compatibilité et la reproductibilité des déploiements

# ========================================
# CONTRAINTES DE VERSIONS TERRAFORM ET PROVIDERS
# ========================================

# Définit les versions Terraform et des providers AWS compatibles
# Permet d'éviter les problèmes de compatibilité entre différentes versions
terraform {
  # Version minimale de Terraform requise
  # ">= 1.0" = version 1.0 ou supérieure
  # Terraform 1.0+ apporte la stabilité de l'API et la rétrocompatibilité
  required_version = ">= 1.0"

  # ========================================
  # CONFIGURATION DU PROVIDER AWS
  # ========================================
  
  # Liste des providers externes requis avec leurs contraintes de version
  required_providers {
    # Provider AWS officiel de HashiCorp
    aws = {
      # Source officielle du provider (registry.terraform.io)
      source = "hashicorp/aws"
      
      # Contrainte de version du provider AWS
      # "~> 5.0" = version 5.x (5.0, 5.1, 5.2, etc.) mais pas 6.0
      # Cette notation assure la compatibilité avec les nouvelles fonctionnalités
      # tout en évitant les changements majeurs (breaking changes)
      version = "~> 5.0"
    }
  }
}