# environments/prod/backend.tf
# Configuration du backend distant pour l'état Terraform de PRODUCTION
# L'état contient des informations CRITIQUES sur l'infrastructure de production
# ATTENTION: Sécurité maximale requise - accès restreint aux administrateurs

# ========================================
# CONFIGURATION DU BACKEND S3 PRODUCTION
# ========================================

# Backend S3 pour l'état de production - isolé de l'environnement de dev
# Avantages critiques: sauvegarde, chiffrement, contrôle d'accès, audit
terraform {
  backend "s3" {
    # Bucket S3 dédié à la production - SÉPARÉ du dev
    # Ce bucket doit être créé par le script bootstrap/prod AVANT utilisation
    bucket = "terraform-modular-tfstate-prod"
    
    # Nom du fichier d'état dans le bucket
    # Permet plusieurs états dans le même bucket avec différentes clés
    key = "terraform.tfstate"
    
    # Région AWS du bucket S3 de production
    # Doit correspondre à la région de l'infrastructure
    region = "us-east-1"
    
    # Chiffrement OBLIGATOIRE en production
    # Protège les données sensibles (mots de passe, clés, configurations)
    encrypt = true
    
    # Table DynamoDB pour verrouillage concurrent en production
    # CRITIQUE: Empêche les modifications simultanées qui pourraient corrompre l'état
    # Cette table doit être créée par bootstrap/prod
    dynamodb_table = "terraform-modular-lock-prod"
  }
}