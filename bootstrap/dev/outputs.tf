# ================================================================
# OUTPUTS DU BOOTSTRAP - ENVIRONNEMENT DEV
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre les outputs Terraform
# 
# QU'EST-CE QUE LES OUTPUTS ?
# ===========================
# 
# Les outputs permettent de :
# 1. EXPOSER DES VALEURS : Rendre disponibles des informations sur les ressources créées
# 2. PARTAGER ENTRE MODULES : Permettre à d'autres configurations d'utiliser ces valeurs
# 3. DEBUGGING : Afficher des informations importantes après un apply
# 4. DOCUMENTATION : Documenter les éléments critiques de l'infrastructure
# 
# POURQUOI CES OUTPUTS SPÉCIFIQUES ?
# ==================================
# 
# Ces outputs exposent les informations nécessaires pour configurer
# le backend distant dans les environnements (environments/dev/, etc.)
# 
# UTILISATION PRATIQUE :
# ======================
# 
# Après avoir exécuté ce bootstrap, vous pouvez :
# 1. Voir ces valeurs avec : terraform output
# 2. Les utiliser pour configurer backend.tf dans environments/dev/
# 3. Les référencer dans d'autres modules ou configurations

# ================================================================
# INFORMATIONS SUR LE BUCKET S3 D'ÉTAT
# ================================================================

output "tfstate_bucket_name" {
  # VALEUR : ID du bucket S3 (équivalent au nom du bucket)
  # Cette valeur sera utilisée dans la configuration backend "s3"
  value = aws_s3_bucket.tfstate_dev.id
  
  # DESCRIPTION : Explication claire de l'output en français
  # Aide les utilisateurs à comprendre l'utilité de cette valeur
  description = "Nom du bucket S3 pour stocker l'état Terraform de l'environnement dev"
}

output "tfstate_bucket_arn" {
  # VALEUR : ARN (Amazon Resource Name) du bucket
  # Format : arn:aws:s3:::nom-du-bucket
  # Utile pour les politiques IAM et les références cross-account
  value = aws_s3_bucket.tfstate_dev.arn
  
  # UTILISATION DE L'ARN :
  # - Création de politiques IAM spécifiques
  # - Références dans d'autres stacks CloudFormation
  # - Monitoring et logging centralisé
  description = "ARN complet du bucket S3 - Utilisé pour les politiques IAM et références cross-service"
}

# ================================================================
# INFORMATIONS SUR LA TABLE DYNAMODB DE VERROUILLAGE
# ================================================================

output "lock_table_name" {
  # VALEUR : Nom de la table DynamoDB pour le state locking
  # Cette valeur sera utilisée dans la configuration backend "s3"
  # avec le paramètre "dynamodb_table"
  value = aws_dynamodb_table.tfstate_lock_dev.name
  
  # IMPORTANCE CRITIQUE :
  # Sans cette table, plusieurs utilisateurs pourraient modifier
  # l'état simultanément et corrompre l'infrastructure
  description = "Nom de la table DynamoDB pour le verrouillage d'état - Empêche les modifications concurrentes"
}

output "lock_table_arn" {
  # VALEUR : ARN de la table DynamoDB
  # Format : arn:aws:dynamodb:region:account:table/nom-table
  # Utile pour les politiques IAM et le monitoring
  value = aws_dynamodb_table.tfstate_lock_dev.arn
  
  # UTILISATION DE L'ARN :
  # - Politiques IAM pour contrôler l'accès au verrouillage
  # - Monitoring des opérations de verrouillage
  # - Alertes sur les verrous bloqués trop longtemps
  description = "ARN complet de la table DynamoDB - Utilisé pour les politiques IAM et le monitoring"
}

# ================================================================
# EXEMPLE D'UTILISATION DES OUTPUTS
# ================================================================
# 
# Après avoir exécuté ce bootstrap, vous pouvez voir ces valeurs :
# 
# $ terraform output
# tfstate_bucket_name = "terraform-modular-tfstate-dev"
# tfstate_bucket_arn = "arn:aws:s3:::terraform-modular-tfstate-dev"
# lock_table_name = "terraform-modular-lock-dev"
# lock_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-modular-lock-dev"
# 
# Ensuite, utilisez ces valeurs dans environments/dev/backend.tf :
# 
# terraform {
#   backend "s3" {
#     bucket         = "terraform-modular-tfstate-dev"        # ← tfstate_bucket_name
#     key            = "environments/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-modular-lock-dev"           # ← lock_table_name
#     encrypt        = true
#   }
# }
# 
# ================================================================
# BONNES PRATIQUES POUR LES OUTPUTS
# ================================================================
# 
# 1. DESCRIPTIONS CLAIRES :
#    - Expliquez toujours l'utilité de chaque output
#    - Incluez des exemples d'utilisation si pertinent
#    - Documentez les contraintes ou limitations
# 
# 2. NOMS DESCRIPTIFS :
#    - Utilisez des noms qui expliquent clairement le contenu
#    - Évitez les abréviations cryptiques
#    - Suivez une convention de nommage cohérente
# 
# 3. SENSIBILITÉ DES DONNÉES :
#    - Utilisez "sensitive = true" pour les données sensibles
#    - Ne jamais exposer de mots de passe ou clés d'API
#    - Considérez la sécurité même dans les outputs
# 
# 4. MAINTENANCE :
#    - Supprimez les outputs obsolètes
#    - Mettez à jour les descriptions quand l'usage change
#    - Versionnez les changements d'outputs importants
# ================================================================