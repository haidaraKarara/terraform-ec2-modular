# ================================================================
# TERRAFORM BOOTSTRAP - ENVIRONNEMENT DE DÉVELOPPEMENT (DEV)
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre le processus de bootstrap de Terraform
# 
# QU'EST-CE QUE LE BOOTSTRAP ET POURQUOI EN AVONS-NOUS BESOIN ?
# ===============================================================
# 
# Le "bootstrap" est la première étape OBLIGATOIRE avant d'utiliser un backend distant.
# C'est le processus de création des ressources nécessaires pour stocker l'état de Terraform.
# 
# LE PROBLÈME "L'ŒEUF ET LA POULE" (Chicken-and-Egg Problem) :
# =============================================================
# 
# 1. Pour utiliser un backend S3, nous avons besoin d'un bucket S3 qui existe déjà
# 2. Mais pour créer ce bucket S3 avec Terraform, nous avons besoin d'un endroit pour stocker l'état
# 3. Si nous utilisons le backend local pour créer le bucket, puis configurons le backend distant,
#    nous résolvons ce problème circulaire
# 
# SOLUTION : PROCESSUS EN DEUX ÉTAPES
# ====================================
# 
# ÉTAPE 1 (ICI) : Bootstrap avec backend LOCAL
# - Créer le bucket S3 pour stocker les états futurs
# - Créer la table DynamoDB pour le verrouillage des états
# - L'état de ces ressources reste LOCAL (fichier terraform.tfstate)
# 
# ÉTAPE 2 (Dans environments/) : Utiliser le backend DISTANT
# - Configurer Terraform pour utiliser le bucket S3 créé à l'étape 1
# - Tous les nouveaux états seront stockés dans S3 de manière sécurisée
# 
# ATTENTION : Ce fichier utilise le backend LOCAL par défaut !
# ============================================================

# ================================================================
# CONFIGURATION DU FOURNISSEUR AWS
# ================================================================
# 
# Définit la région AWS où seront créées les ressources de bootstrap
# us-east-1 est souvent utilisée car :
# - C'est la région "par défaut" d'AWS
# - Certains services AWS ne sont disponibles que dans cette région
# - Les buckets S3 avec des noms globaux sont souvent créés ici
provider "aws" {
  region = "us-east-1"  # Région AWS pour les ressources de bootstrap
}

# ================================================================
# BUCKET S3 POUR LE STOCKAGE DE L'ÉTAT TERRAFORM
# ================================================================
# 
# POURQUOI UN BUCKET S3 ?
# =======================
# 
# S3 (Simple Storage Service) est idéal pour stocker l'état Terraform car :
# - DURABILITÉ : 99.999999999% (11 nines) de durabilité des données
# - DISPONIBILITÉ : Haute disponibilité avec redondance automatique
# - VERSIONING : Permet de récupérer des versions antérieures de l'état
# - CHIFFREMENT : Protection des données sensibles dans l'état
# - CONTRÔLE D'ACCÈS : Sécurité granulaire avec IAM
# 
# SÉPARATION DES ENVIRONNEMENTS :
# ===============================
# 
# Chaque environnement (dev, prod) a son propre bucket pour :
# - ISOLATION : Éviter les conflits entre environnements
# - SÉCURITÉ : Contrôler l'accès par environnement
# - ORGANISATION : Faciliter la gestion et la maintenance
resource "aws_s3_bucket" "tfstate_dev" {
  # Nom unique du bucket (doit être globalement unique dans tout AWS)
  bucket = "terraform-modular-tfstate-dev"
  
  # force_destroy = false : Protection contre la suppression accidentelle
  # Terraform refusera de détruire ce bucket s'il contient des objets
  # C'est une sécurité importante pour les données d'état critiques
  force_destroy = false

  # Tags pour l'organisation et la facturation
  tags = {
    Name        = "Terraform State Bucket - Dev"  # Nom descriptif
    Environment = "dev"                           # Identification de l'environnement
    Project     = "terraform-modular"             # Identification du projet
  }
}

# ================================================================
# VERSIONING DU BUCKET S3
# ================================================================
# 
# POURQUOI LE VERSIONING EST CRUCIAL ?
# ====================================
# 
# Le versioning S3 conserve plusieurs versions de chaque fichier d'état :
# 
# AVANTAGES :
# - RÉCUPÉRATION : Retour à une version antérieure en cas d'erreur
# - AUDIT : Historique des changements d'infrastructure
# - SÉCURITÉ : Protection contre la corruption de fichiers
# - COLLABORATION : Récupération après des modifications conflictuelles
# 
# EXEMPLES D'UTILISATION :
# - terraform apply échoue → revenir à la version précédente
# - Suppression accidentelle → restaurer depuis une version sauvegardée
# - Debugging → comparer les états à différents moments
resource "aws_s3_bucket_versioning" "versioning_dev" {
  # Référence au bucket créé ci-dessus
  bucket = aws_s3_bucket.tfstate_dev.id

  versioning_configuration {
    # "Enabled" active le versioning pour tous les objets du bucket
    status = "Enabled"
  }
}

# ================================================================
# CHIFFREMENT DU BUCKET S3
# ================================================================
# 
# POURQUOI LE CHIFFREMENT EST OBLIGATOIRE ?
# ==========================================
# 
# L'état Terraform contient des informations SENSIBLES :
# - Mots de passe et clés d'accès
# - Configurations réseau internes
# - Identifiants de ressources
# - Données de connexion aux bases de données
# 
# TYPES DE CHIFFREMENT S3 :
# =========================
# 
# AES256 (utilisé ici) :
# - Chiffrement côté serveur géré par S3
# - Clés gérées automatiquement par AWS
# - Transparent pour l'utilisateur
# - Pas de coût supplémentaire
# 
# Alternatives :
# - KMS : Clés gérées par AWS Key Management Service (plus de contrôle)
# - SSE-C : Clés fournies par le client (contrôle total)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_dev" {
  # Application du chiffrement au bucket d'état
  bucket = aws_s3_bucket.tfstate_dev.id

  rule {
    apply_server_side_encryption_by_default {
      # AES256 : Standard de chiffrement symétrique robuste
      sse_algorithm = "AES256"
    }
  }
}

# ================================================================
# BLOCAGE DE L'ACCÈS PUBLIC AU BUCKET
# ================================================================
# 
# SÉCURITÉ CRITIQUE : POURQUOI BLOQUER L'ACCÈS PUBLIC ?
# =====================================================
# 
# L'état Terraform ne doit JAMAIS être accessible publiquement car :
# - Contient des informations de configuration sensibles
# - Pourrait révéler l'architecture interne
# - Peut contenir des identifiants ou tokens
# - Violation potentielle de la sécurité et conformité
# 
# LES 4 NIVEAUX DE PROTECTION :
# =============================
# 
# 1. block_public_acls : Empêche l'ajout d'ACL publiques
# 2. block_public_policy : Empêche l'ajout de politiques publiques
# 3. ignore_public_acls : Ignore les ACL publiques existantes
# 4. restrict_public_buckets : Restreint l'accès même avec politiques publiques
# 
# RÉSULTAT : Accès UNIQUEMENT via IAM et authentification AWS
resource "aws_s3_bucket_public_access_block" "block_dev" {
  # Application des restrictions au bucket d'état
  bucket = aws_s3_bucket.tfstate_dev.id

  # Bloque toute tentative de rendre le bucket accessible publiquement
  block_public_acls       = true  # Empêche les nouvelles ACL publiques
  block_public_policy     = true  # Empêche les nouvelles politiques publiques
  ignore_public_acls      = true  # Ignore les ACL publiques existantes
  restrict_public_buckets = true  # Force la restriction même avec politiques publiques
}

# ================================================================
# TABLE DYNAMODB POUR LE VERROUILLAGE D'ÉTAT
# ================================================================
# 
# PROBLÈME RÉSOLU : LA CONCURRENCE
# =================================
# 
# Sans verrouillage, plusieurs utilisateurs peuvent :
# - Modifier l'infrastructure simultanément
# - Corrompre le fichier d'état
# - Créer des conflits irréversibles
# - Perdre des modifications
# 
# SOLUTION : VERROUILLAGE DISTRIBUÉ AVEC DYNAMODB
# ===============================================
# 
# DynamoDB fournit un mécanisme de verrouillage atomique :
# 
# FONCTIONNEMENT :
# 1. Terraform demande un verrou avant toute opération
# 2. DynamoDB accorde le verrou au premier demandeur
# 3. Les autres opérations attendent la libération du verrou
# 4. Le verrou est libéré automatiquement à la fin de l'opération
# 
# AVANTAGES DE DYNAMODB :
# - ATOMICITÉ : Opérations garanties atomiques
# - PERFORMANCE : Latence très faible (< 10ms)
# - FIABILITÉ : Service entièrement géré par AWS
# - COST-EFFECTIVE : Mode "PAY_PER_REQUEST" (paiement à l'usage)
resource "aws_dynamodb_table" "tfstate_lock_dev" {
  # Nom de la table (doit être unique dans la région)
  name = "terraform-modular-lock-dev"
  
  # Mode de facturation : PAY_PER_REQUEST
  # Plus économique pour un usage intermittent (développement)
  # Alternative : PROVISIONED (capacité fixe, plus prévisible pour la production)
  billing_mode = "PAY_PER_REQUEST"
  
  # Clé primaire requise par Terraform pour le verrouillage
  # "LockID" est le nom standard utilisé par Terraform
  hash_key = "LockID"

  # Définition de l'attribut clé primaire
  attribute {
    name = "LockID"      # Nom de l'attribut (doit correspondre à hash_key)
    type = "S"           # Type String (autres types : N=Number, B=Binary)
  }

  # Tags pour l'organisation et la facturation
  tags = {
    Name        = "Terraform Lock Table - Dev"  # Nom descriptif
    Environment = "dev"                         # Identification de l'environnement
    Project     = "terraform-modular"           # Identification du projet
  }
}

# ================================================================
# PROCHAINES ÉTAPES APRÈS LE BOOTSTRAP
# ================================================================
# 
# APRÈS AVOIR EXÉCUTÉ CE BOOTSTRAP :
# 
# 1. VÉRIFICATION :
#    - Le bucket S3 "terraform-modular-tfstate-dev" existe
#    - La table DynamoDB "terraform-modular-lock-dev" existe
#    - Le fichier terraform.tfstate local contient ces ressources
# 
# 2. CONFIGURATION DU BACKEND DISTANT :
#    Dans environments/dev/backend.tf, vous pourrez maintenant utiliser :
#    
#    terraform {
#      backend "s3" {
#        bucket         = "terraform-modular-tfstate-dev"
#        key            = "environments/dev/terraform.tfstate"
#        region         = "us-east-1"
#        dynamodb_table = "terraform-modular-lock-dev"
#        encrypt        = true
#      }
#    }
# 
# 3. MIGRATION DE L'ÉTAT :
#    - `terraform init` configurera le backend distant
#    - L'état sera migré de local vers S3
#    - Les futures opérations utiliseront S3 + DynamoDB
# 
# IMPORTANT : Gardez ce fichier bootstrap.tfstate en sécurité !
# Il contient l'état des ressources qui permettent le stockage distant.
# ================================================================