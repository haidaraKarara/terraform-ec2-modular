# ================================================================
# OUTPUTS DU BOOTSTRAP - ENVIRONNEMENT PRODUCTION
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre les outputs Terraform en PRODUCTION
# 
# QU'EST-CE QUE LES OUTPUTS EN PRODUCTION ?
# =========================================
# 
# Les outputs en production permettent de :
# 1. EXPOSER DES VALEURS CRITIQUES : Informations sur les ressources de production créées
# 2. INTÉGRATION AVEC D'AUTRES SYSTÈMES : APIs, monitoring, automation, CI/CD
# 3. AUDIT ET CONFORMITÉ : Documentation des ressources critiques
# 4. DEBUGGING DE PRODUCTION : Informations essentielles pour le support
# 5. ORCHESTRATION : Coordination entre différentes stacks Terraform
# 
# POURQUOI CES OUTPUTS SPÉCIFIQUES EN PRODUCTION ?
# ===============================================
# 
# Ces outputs exposent les informations CRITIQUES pour :
# - Configurer le backend distant dans environments/prod/
# - Permettre l'intégration avec des outils de monitoring
# - Faciliter l'audit et la conformité
# - Supporter les opérations de production (backup, monitoring, etc.)
# 
# UTILISATION EN PRODUCTION :
# ===========================
# 
# Après avoir exécuté ce bootstrap de production, vous pouvez :
# 1. Voir ces valeurs avec : terraform output
# 2. Les utiliser pour configurer backend.tf dans environments/prod/
# 3. Les intégrer dans vos pipelines CI/CD
# 4. Les monitorer avec des outils d'observabilité
# 5. Les documenter pour les audits de conformité

# ================================================================
# INFORMATIONS SUR LE BUCKET S3 D'ÉTAT - PRODUCTION
# ================================================================

output "tfstate_bucket_name" {
  # VALEUR : ID du bucket S3 de PRODUCTION (équivalent au nom du bucket)
  # Cette valeur sera utilisée dans la configuration backend "s3" de production
  # CRITIQUE : Cette information est sensible et doit être protégée
  value = aws_s3_bucket.tfstate_prod.id
  
  # DESCRIPTION : Explication claire pour l'équipe de production
  # Inclut le contexte de sécurité et d'utilisation critique
  description = "Nom du bucket S3 pour stocker l'état Terraform de l'environnement PRODUCTION - Information sensible"
}

output "tfstate_bucket_arn" {
  # VALEUR : ARN (Amazon Resource Name) du bucket de PRODUCTION
  # Format : arn:aws:s3:::nom-du-bucket-prod
  # UTILISATION CRITIQUE en production pour :
  # - Politiques IAM strictes et granulaires
  # - Intégration avec CloudTrail pour l'audit
  # - Alertes de sécurité sur les accès non autorisés
  # - Backup et réplication cross-region
  value = aws_s3_bucket.tfstate_prod.arn
  
  # UTILISATION DE L'ARN EN PRODUCTION :
  # ==================================
  # 
  # SÉCURITÉ :
  # - Création de politiques IAM ultra-restrictives
  # - Audit des accès avec CloudTrail
  # - Alertes sur les modifications non autorisées
  # 
  # MONITORING :
  # - Surveillance des métriques S3 spécifiques
  # - Alertes sur les tailles de fichiers anormales
  # - Monitoring des coûts par bucket
  # 
  # COMPLIANCE :
  # - Traçabilité pour les audits de sécurité
  # - Documentation pour la conformité réglementaire
  # - Références dans les politiques de gouvernance
  description = "ARN complet du bucket S3 de PRODUCTION - Utilisé pour politiques IAM, audit, et monitoring de sécurité"
}

# ================================================================
# INFORMATIONS SUR LA TABLE DYNAMODB DE VERROUILLAGE - PRODUCTION
# ================================================================

output "lock_table_name" {
  # VALEUR : Nom de la table DynamoDB pour le state locking de PRODUCTION
  # Cette valeur sera utilisée dans la configuration backend "s3" de production
  # avec le paramètre "dynamodb_table"
  # 
  # IMPORTANCE CRITIQUE EN PRODUCTION :
  # ==================================
  # 
  # Sans cette table, les risques en production sont MAJEURS :
  # - Corruption d'état lors de déploiements simultanés
  # - Perte de données d'infrastructure critique
  # - Outages causés par des conflits de modifications
  # - Impossibilité de rollback en cas d'incident
  value = aws_dynamodb_table.tfstate_lock_prod.name
  
  # IMPORTANCE VITALE DU VERROUILLAGE EN PRODUCTION :
  # ================================================
  # 
  # PROTECTION CONTRE :
  # - Déploiements concurrents par plusieurs équipes
  # - Conflits entre pipelines CI/CD automatisés
  # - Interventions manuelles pendant les incidents
  # - Corruption d'état lors des opérations critiques
  # 
  # GARANTIES FOURNIES :
  # - Atomicité des opérations Terraform
  # - Consistance de l'état d'infrastructure
  # - Isolation des modifications
  # - Traçabilité des verrous pour l'audit
  description = "Nom de la table DynamoDB pour le verrouillage d'état PRODUCTION - Protection critique contre les modifications concurrentes"
}

output "lock_table_arn" {
  # VALEUR : ARN de la table DynamoDB de PRODUCTION
  # Format : arn:aws:dynamodb:region:account:table/nom-table-prod
  # UTILISATION CRITIQUE pour la sécurité et le monitoring de production
  value = aws_dynamodb_table.tfstate_lock_prod.arn
  
  # UTILISATION DE L'ARN EN PRODUCTION :
  # ==================================
  # 
  # SÉCURITÉ ET CONTRÔLE D'ACCÈS :
  # - Politiques IAM ultra-granulaires pour les équipes
  # - Contrôle strict des permissions de verrouillage
  # - Audit des opérations de lock/unlock
  # - Prévention des accès non autorisés
  # 
  # MONITORING ET OBSERVABILITÉ :
  # - Surveillance des métriques DynamoDB critiques
  # - Alertes sur les verrous bloqués trop longtemps
  # - Monitoring des performances de verrouillage
  # - Détection des anomalies d'utilisation
  # 
  # OPERATIONS ET MAINTENANCE :
  # - Backup automatique des métadonnées de verrouillage
  # - Réplication pour la haute disponibilité
  # - Intégration avec les outils de monitoring
  # - Support pour la résolution d'incidents
  # 
  # CONFORMITÉ ET AUDIT :
  # - Traçabilité complète des opérations de verrouillage
  # - Documentation pour les audits de sécurité
  # - Preuve de contrôles de changement appropriés
  # - Historique des accès pour la conformité
  description = "ARN complet de la table DynamoDB PRODUCTION - Utilisé pour sécurité, monitoring, et audit des opérations de verrouillage"
}

# ================================================================
# EXEMPLE D'UTILISATION DES OUTPUTS EN PRODUCTION
# ================================================================
# 
# APRÈS LE BOOTSTRAP DE PRODUCTION, visualisez les valeurs critiques :
# 
# $ terraform output
# tfstate_bucket_name = "terraform-modular-tfstate-prod"
# tfstate_bucket_arn = "arn:aws:s3:::terraform-modular-tfstate-prod"
# lock_table_name = "terraform-modular-lock-prod"
# lock_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-modular-lock-prod"
# 
# CONFIGURATION DU BACKEND DE PRODUCTION :
# ========================================
# 
# Utilisez ces valeurs dans environments/prod/backend.tf :
# 
# terraform {
#   backend "s3" {
#     bucket         = "terraform-modular-tfstate-prod"          # ← tfstate_bucket_name
#     key            = "environments/prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-modular-lock-prod"             # ← lock_table_name
#     encrypt        = true
#   }
# }
# 
# INTÉGRATION AVEC LES OUTILS DE PRODUCTION :
# ===========================================
# 
# 1. POLITIQUES IAM STRICTES :
#    {
#      "Version": "2012-10-17",
#      "Statement": [
#        {
#          "Effect": "Allow",
#          "Action": ["s3:GetObject", "s3:PutObject"],
#          "Resource": "arn:aws:s3:::terraform-modular-tfstate-prod/*"   # ← tfstate_bucket_arn
#        },
#        {
#          "Effect": "Allow",
#          "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
#          "Resource": "arn:aws:dynamodb:us-east-1:*:table/terraform-modular-lock-prod"  # ← lock_table_arn
#        }
#      ]
#    }
# 
# 2. MONITORING CLOUDWATCH :
#    - Alertes sur les accès au bucket S3 de production
#    - Surveillance des métriques DynamoDB de verrouillage
#    - Notifications sur les operations échouées
# 
# 3. BACKUP ET DISASTER RECOVERY :
#    - Réplication cross-region du bucket S3
#    - Backup automatique de la table DynamoDB
#    - Procedures de restauration documentées
# 
# ================================================================
# BONNES PRATIQUES POUR LES OUTPUTS EN PRODUCTION
# ================================================================
# 
# 1. SÉCURITÉ DES OUTPUTS :
#    ======================
#    - Utilisez "sensitive = true" pour les données ultra-sensibles
#    - Ne jamais exposer de mots de passe ou clés d'API dans les outputs
#    - Limitez l'accès aux outputs via des politiques IAM strictes
#    - Auditez régulièrement l'utilisation des outputs sensibles
# 
# 2. DOCUMENTATION EXHAUSTIVE :
#    ===========================
#    - Documentez TOUS les outputs avec des descriptions détaillées
#    - Incluez des exemples d'utilisation pour chaque output
#    - Maintenez la documentation à jour avec les changements
#    - Documentez les implications de sécurité de chaque output
# 
# 3. NOMMAGE ET ORGANISATION :
#    =========================
#    - Utilisez des noms explicites et cohérents
#    - Groupez les outputs par fonctionnalité ou service
#    - Suivez une convention de nommage stricte
#    - Évitez les abréviations cryptiques
# 
# 4. MONITORING ET ALERTES :
#    =======================
#    - Surveillez l'utilisation des outputs critiques
#    - Configurez des alertes sur les accès anormaux
#    - Intégrez avec vos outils de monitoring existants
#    - Maintenez des métriques sur l'utilisation des outputs
# 
# 5. CONFORMITÉ ET AUDIT :
#    ======================
#    - Documentez l'utilisation des outputs pour les audits
#    - Maintenez un registre des accès aux outputs sensibles
#    - Incluez les outputs dans vos processus de revue de sécurité
#    - Préparez la documentation pour les audits de conformité
# 
# COMMANDES UTILES POUR LA PRODUCTION :
# =====================================
# 
# terraform output                     # Affiche tous les outputs
# terraform output tfstate_bucket_name # Affiche un output spécifique
# terraform output -json               # Format JSON pour l'automation
# terraform output -raw bucket_name    # Valeur brute sans quotes pour scripts
# 
# EXEMPLES D'AUTOMATION AVEC LES OUTPUTS :
# ========================================
# 
# # Script Bash pour backup automatique
# BUCKET_NAME=$(terraform output -raw tfstate_bucket_name)
# aws s3 sync s3://$BUCKET_NAME s3://backup-$BUCKET_NAME
# 
# # Pipeline CI/CD utilisant les outputs
# export TF_STATE_BUCKET=$(terraform output -raw tfstate_bucket_name)
# export TF_LOCK_TABLE=$(terraform output -raw lock_table_name)
# ================================================================