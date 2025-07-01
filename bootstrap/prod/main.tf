# ================================================================
# TERRAFORM BOOTSTRAP - ENVIRONNEMENT DE PRODUCTION (PROD)
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre le processus de bootstrap pour la PRODUCTION
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
# DIFFÉRENCES CRITIQUES AVEC L'ENVIRONNEMENT DE DÉVELOPPEMENT :
# =============================================================
# 
# PRODUCTION vs DÉVELOPPEMENT :
# 
# 1. ISOLATION TOTALE :
#    - Bucket S3 séparé (terraform-modular-tfstate-PROD)
#    - Table DynamoDB séparée (terraform-modular-lock-PROD)
#    - Aucun partage de ressources avec dev
# 
# 2. SÉCURITÉ RENFORCÉE :
#    - Même niveau de chiffrement mais accès plus restreint
#    - Politiques IAM plus strictes en production
#    - Audit et monitoring plus poussés
# 
# 3. STABILITÉ MAXIMALE :
#    - Déploiements plus prudents et planifiés
#    - Tests approfondis avant tout changement
#    - Processus de rollback bien définis
# 
# SOLUTION : PROCESSUS EN DEUX ÉTAPES (IDENTIQUE À DEV)
# =====================================================
# 
# ÉTAPE 1 (ICI) : Bootstrap avec backend LOCAL
# - Créer le bucket S3 pour stocker les états futurs de PRODUCTION
# - Créer la table DynamoDB pour le verrouillage des états de PRODUCTION
# - L'état de ces ressources reste LOCAL (fichier terraform.tfstate)
# 
# ÉTAPE 2 (Dans environments/prod/) : Utiliser le backend DISTANT
# - Configurer Terraform pour utiliser le bucket S3 de PRODUCTION créé à l'étape 1
# - Tous les nouveaux états de PRODUCTION seront stockés dans S3 de manière sécurisée
# 
# ATTENTION : Ce fichier utilise le backend LOCAL par défaut !
# ============================================================

# ================================================================
# CONFIGURATION DU FOURNISSEUR AWS POUR LA PRODUCTION
# ================================================================
# 
# Définit la région AWS où seront créées les ressources de bootstrap PRODUCTION
# us-east-1 est souvent utilisée car :
# - C'est la région "par défaut" d'AWS
# - Certains services AWS ne sont disponibles que dans cette région
# - Les buckets S3 avec des noms globaux sont souvent créés ici
# - Latence optimale pour beaucoup d'applications US/EU
provider "aws" {
  region = "us-east-1"  # Région AWS pour les ressources de bootstrap PRODUCTION
}

# ================================================================
# BUCKET S3 POUR LE STOCKAGE DE L'ÉTAT TERRAFORM - PRODUCTION
# ================================================================
# 
# POURQUOI UN BUCKET S3 SÉPARÉ POUR LA PRODUCTION ?
# ==================================================
# 
# ISOLATION CRITIQUE :
# - SÉCURITÉ : Empêche tout accès accidentel depuis dev
# - COMPLIANCE : Respecte les exigences de séparation des environnements
# - AUDIT : Facilite le tracking des changements en production
# - PERFORMANCE : Évite les conflits de ressources
# 
# AVANTAGES DE S3 POUR LA PRODUCTION :
# ====================================
# 
# - DURABILITÉ : 99.999999999% (11 nines) - Critique pour la production
# - DISPONIBILITÉ : 99.99% de SLA - Essentiel pour les opérations continues
# - VERSIONING : Récupération rapide en cas d'incident production
# - CHIFFREMENT : Protection des configurations sensibles de production
# - CONTRÔLE D'ACCÈS : Sécurité granulaire avec IAM pour les équipes
# - RÉPLICATION : Possibilité de cross-region replication pour DR
resource "aws_s3_bucket" "tfstate_prod" {
  # Nom unique du bucket PRODUCTION (doit être globalement unique dans tout AWS)
  # Convention : terraform-[projet]-tfstate-[environnement]
  bucket = "terraform-modular-tfstate-prod"
  
  # force_destroy = false : PROTECTION MAXIMALE pour la production
  # Terraform refusera catégoriquement de détruire ce bucket s'il contient des objets
  # C'est une sécurité CRITIQUE pour les données d'état de production
  # JAMAIS mettre à true en production !
  force_destroy = false

  # Tags pour l'organisation, la facturation et la conformité
  tags = {
    Name        = "Terraform State Bucket - Prod"  # Nom descriptif
    Environment = "prod"                           # Identification PRODUCTION
    Project     = "terraform-modular"              # Identification du projet
    # Tags additionnels recommandés pour la production :
    # CostCenter = "infrastructure"
    # Owner = "platform-team"
    # Criticality = "high"
  }
}

# ================================================================
# VERSIONING DU BUCKET S3 - PRODUCTION
# ================================================================
# 
# POURQUOI LE VERSIONING EST ABSOLUMENT CRITIQUE EN PRODUCTION ?
# ==============================================================
# 
# Le versioning S3 est VITAL en production pour :
# 
# RÉCUPÉRATION D'URGENCE :
# - Rollback immédiat après un déploiement échoué
# - Restauration après une corruption d'état
# - Retour à un état stable connu en cas de crise
# 
# CONFORMITÉ ET AUDIT :
# - Historique complet des changements d'infrastructure
# - Traçabilité pour les audits de sécurité
# - Preuve de conformité réglementaire
# 
# COLLABORATION SÉCURISÉE :
# - Récupération après des modifications conflictuelles
# - Protection contre les erreurs humaines
# - Sauvegarde automatique avant chaque changement
# 
# EXEMPLES CRITIQUES EN PRODUCTION :
# - Déploiement échoué → rollback immédiat à la version stable
# - Incident de sécurité → analyse forensique des changements
# - Audit réglementaire → preuve de tous les changements historiques
resource "aws_s3_bucket_versioning" "versioning_prod" {
  # Référence au bucket de production créé ci-dessus
  bucket = aws_s3_bucket.tfstate_prod.id

  versioning_configuration {
    # "Enabled" : OBLIGATOIRE en production
    # Conserve automatiquement toutes les versions de l'état
    status = "Enabled"
  }
}

# ================================================================
# CHIFFREMENT DU BUCKET S3 - PRODUCTION
# ================================================================
# 
# POURQUOI LE CHIFFREMENT EST ABSOLUMENT OBLIGATOIRE EN PRODUCTION ?
# ===================================================================
# 
# L'état Terraform de PRODUCTION contient des informations ULTRA-SENSIBLES :
# - Mots de passe et clés d'accès de production
# - Configurations réseau critiques
# - Identifiants de bases de données de production
# - Secrets de chiffrement et certificats
# - Topologie complète de l'infrastructure
# 
# CONFORMITÉ RÉGLEMENTAIRE :
# =========================
# 
# Le chiffrement est souvent REQUIS par :
# - RGPD (Europe) : Protection des données personnelles
# - SOX (Finance) : Protection des données financières
# - HIPAA (Santé) : Protection des données médicales
# - PCI DSS (Paiements) : Protection des données de cartes
# 
# TYPES DE CHIFFREMENT EN PRODUCTION :
# ===================================
# 
# AES256 (utilisé ici) - MINIMUM acceptable :
# - Chiffrement côté serveur géré par S3
# - Clés gérées automatiquement par AWS
# - Transparent pour l'utilisateur
# - Conforme à la plupart des standards
# 
# Alternatives pour sécurité renforcée :
# - KMS : Clés gérées par AWS Key Management Service (recommandé en prod)
# - SSE-C : Clés fournies par le client (contrôle total)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_prod" {
  # Application du chiffrement au bucket d'état de PRODUCTION
  bucket = aws_s3_bucket.tfstate_prod.id

  rule {
    apply_server_side_encryption_by_default {
      # AES256 : Standard de chiffrement symétrique robuste
      # Pour la production, considérez KMS pour un contrôle accru
      sse_algorithm = "AES256"
    }
  }
}

# ================================================================
# BLOCAGE DE L'ACCÈS PUBLIC AU BUCKET - PRODUCTION
# ================================================================
# 
# SÉCURITÉ CRITIQUE : PROTECTION MAXIMALE EN PRODUCTION
# =====================================================
# 
# L'état Terraform de PRODUCTION ne doit JAMAIS être accessible publiquement car :
# - Contient l'architecture complète de production
# - Pourrait révéler des vulnérabilités exploitables
# - Peut contenir des identifiants de production actifs
# - Violation critique de sécurité et conformité
# - Impact business majeur en cas de fuite
# 
# LES 4 NIVEAUX DE PROTECTION APPLIQUÉS :
# =======================================
# 
# Cette configuration crée une "forteresse" autour du bucket :
# 
# 1. block_public_acls : Mur contre les ACL publiques futures
# 2. block_public_policy : Mur contre les politiques publiques futures
# 3. ignore_public_acls : Ignore même les ACL publiques existantes
# 4. restrict_public_buckets : Force la restriction absolue
# 
# RÉSULTAT : Accès UNIQUEMENT via IAM avec authentification forte
# 
# MONITORING RECOMMANDÉ EN PRODUCTION :
# ====================================
# 
# - Alertes CloudTrail sur les accès au bucket
# - Notifications sur les tentatives de modification des politiques
# - Audit régulier des permissions IAM
# - Surveillance des téléchargements d'état
resource "aws_s3_bucket_public_access_block" "block_prod" {
  # Application des restrictions maximales au bucket d'état de PRODUCTION
  bucket = aws_s3_bucket.tfstate_prod.id

  # Protection totale contre l'exposition publique
  block_public_acls       = true  # Bloque toutes les nouvelles ACL publiques
  block_public_policy     = true  # Bloque toutes les nouvelles politiques publiques
  ignore_public_acls      = true  # Ignore même les ACL publiques existantes
  restrict_public_buckets = true  # Force la restriction même avec politiques publiques
}

# ================================================================
# TABLE DYNAMODB POUR LE VERROUILLAGE D'ÉTAT - PRODUCTION
# ================================================================
# 
# PROBLÈME CRITIQUE RÉSOLU EN PRODUCTION : LA CONCURRENCE
# =======================================================
# 
# En production, les risques de concurrence sont AMPLIFIÉS :
# - Équipes multiples peuvent déployer simultanément
# - Pipelines CI/CD automatisés peuvent créer des conflits
# - Incidents de production nécessitent des interventions urgentes
# - La corruption d'état peut causer des outages critiques
# 
# SOLUTION : VERROUILLAGE DISTRIBUÉ ULTRA-FIABLE AVEC DYNAMODB
# ===========================================================
# 
# DynamoDB fournit un mécanisme de verrouillage atomique PRODUCTION-READY :
# 
# FONCTIONNEMENT EN PRODUCTION :
# 1. Terraform demande un verrou avant TOUTE opération
# 2. DynamoDB accorde le verrou au premier demandeur UNIQUEMENT
# 3. Toutes les autres opérations attendent (ou échouent selon configuration)
# 4. Le verrou est libéré automatiquement à la fin de l'opération
# 5. Timeout automatique pour éviter les verrous bloqués
# 
# AVANTAGES CRITIQUES DE DYNAMODB EN PRODUCTION :
# ===============================================
# 
# - ATOMICITÉ : Opérations garanties atomiques (ACID compliance)
# - PERFORMANCE : Latence ultra-faible (< 10ms) même sous charge
# - FIABILITÉ : 99.99% de SLA, service entièrement géré par AWS
# - SCALABILITÉ : Supporte des milliers d'opérations concurrentes
# - MONITORING : Métriques détaillées pour l'observabilité
# - RESILIENCE : Multi-AZ par défaut, backup automatique
resource "aws_dynamodb_table" "tfstate_lock_prod" {
  # Nom de la table de PRODUCTION (doit être unique dans la région)
  # Convention : terraform-[projet]-lock-[environnement]
  name = "terraform-modular-lock-prod"
  
  # Mode de facturation : PAY_PER_REQUEST pour la production
  # Avantages en production :
  # - Pas de gestion de capacité à prévoir
  # - Scaling automatique lors des pics de déploiement
  # - Coût optimisé pour usage intermittent mais critique
  # Alternative : PROVISIONED pour usage très régulier et prévisible
  billing_mode = "PAY_PER_REQUEST"
  
  # Clé primaire REQUISE par Terraform pour le verrouillage
  # "LockID" est le nom standard et OBLIGATOIRE utilisé par Terraform
  # JAMAIS changer ce nom sous peine de casser le verrouillage !
  hash_key = "LockID"

  # Définition de l'attribut clé primaire (STANDARD Terraform)
  attribute {
    name = "LockID"      # Nom de l'attribut (doit correspondre exactement à hash_key)
    type = "S"           # Type String OBLIGATOIRE (autres types : N=Number, B=Binary)
  }

  # Tags pour l'organisation, la facturation et la conformité PRODUCTION
  tags = {
    Name        = "Terraform Lock Table - Prod"  # Nom descriptif
    Environment = "prod"                         # Identification PRODUCTION
    Project     = "terraform-modular"            # Identification du projet
    # Tags additionnels recommandés pour la production :
    # Criticality = "critical"
    # Backup = "required"
    # Monitoring = "enhanced"
  }
}

# ================================================================
# PROCHAINES ÉTAPES APRÈS LE BOOTSTRAP DE PRODUCTION
# ================================================================
# 
# APRÈS AVOIR EXÉCUTÉ CE BOOTSTRAP DE PRODUCTION :
# 
# 1. VÉRIFICATION CRITIQUE :
#    - Le bucket S3 "terraform-modular-tfstate-prod" existe et est sécurisé
#    - La table DynamoDB "terraform-modular-lock-prod" existe et fonctionne
#    - Le fichier terraform.tfstate local contient ces ressources critiques
#    - Vérifier les permissions IAM et l'accès
# 
# 2. CONFIGURATION DU BACKEND DISTANT DE PRODUCTION :
#    Dans environments/prod/backend.tf, vous pourrez maintenant utiliser :
#    
#    terraform {
#      backend "s3" {
#        bucket         = "terraform-modular-tfstate-prod"
#        key            = "environments/prod/terraform.tfstate"
#        region         = "us-east-1"
#        dynamodb_table = "terraform-modular-lock-prod"
#        encrypt        = true
#      }
#    }
# 
# 3. MIGRATION DE L'ÉTAT EN PRODUCTION :
#    - `terraform init` configurera le backend distant de production
#    - L'état sera migré de local vers S3 de production
#    - Les futures opérations utiliseront S3 + DynamoDB de production
# 
# 4. SÉCURISATION SUPPLÉMENTAIRE RECOMMANDÉE :
#    - Configurer MFA pour l'accès aux ressources de production
#    - Mettre en place des politiques IAM restrictives
#    - Activer CloudTrail pour l'audit des accès
#    - Configurer des alertes sur les modifications
# 
# CRITIQUE : Gardez ce fichier bootstrap.tfstate de PRODUCTION en SÉCURITÉ !
# Il contient l'état des ressources qui permettent le stockage distant de production.
# Sauvegardez-le dans un endroit sécurisé et chiffré !
# ================================================================