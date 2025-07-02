# environments/dev/backend.tf
# Configuration du backend distant pour stocker l'état Terraform
# L'état Terraform contient les informations sur les ressources créées

# ========================================
# CONFIGURATION DU BACKEND S3
# ========================================

# Le backend S3 stocke l'état Terraform dans un bucket S3 plutôt qu'en local
# Avantages: partage d'état, sauvegarde automatique, chiffrement, verrouillage
terraform {
  backend "s3" {
    # Nom du bucket S3 où stocker le fichier d'état
    # Ce bucket doit être créé par le script bootstrap AVANT d'utiliser ce backend
    bucket = "terraform-modular-tfstate-dev"

    # Nom du fichier d'état dans le bucket
    # Permet d'avoir plusieurs états dans le même bucket avec des clés différentes
    key = "terraform.tfstate"

    # Région AWS où se trouve le bucket S3
    # Doit correspondre à la région où le bucket a été créé
    region = "us-east-1"

    # Chiffrement du fichier d'état en transit et au repos
    # OBLIGATOIRE pour protéger les données sensibles (mots de passe, clés, etc.)
    encrypt = true

    # Table DynamoDB pour le verrouillage de l'état (state locking)
    # Empêche plusieurs utilisateurs de modifier l'état simultanément
    # Cette table doit être créée par le script bootstrap
    dynamodb_table = "terraform-modular-lock-dev"
  }
}