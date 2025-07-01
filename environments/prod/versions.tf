# environments/prod/versions.tf
# Configuration centralisée des providers et contraintes de versions PRODUCTION
# Ce fichier assure la stabilité et la reproductibilité des déploiements de production
# CRITIQUE: Versions verrouillées pour éviter les régressions en production

# ========================================
# CONTRAINTES DE VERSIONS TERRAFORM ET PROVIDERS PRODUCTION
# ========================================

# Définit les versions Terraform et AWS compatibles pour la production
# Plus strict qu'en dev pour assurer la stabilité et éviter les surprises
terraform {
  # Version minimale de Terraform requise pour la production
  # ">= 1.0" = version 1.0 ou supérieure
  # Terraform 1.0+ garantit la stabilité de l'API et la rétrocompatibilité
  required_version = ">= 1.0"

  # ========================================
  # CONFIGURATION DU PROVIDER AWS PRODUCTION
  # ========================================
  
  # Liste des providers requis avec contraintes strictes
  required_providers {
    # Provider AWS officiel de HashiCorp
    aws = {
      # Source officielle du provider
      source = "hashicorp/aws"
      
      # Contrainte de version stricte pour la production
      # "~> 5.0" = version 5.x (5.0, 5.1, 5.2, etc.) mais PAS 6.0
      # Plus précis qu'en dev pour éviter les changements inattendus
      version = "~> 5.0"
    }
  }
}