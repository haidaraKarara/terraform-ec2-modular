# ================================================================
# CONFIGURATION DES VERSIONS - BOOTSTRAP DEV
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre la gestion des versions de Terraform
# 
# POURQUOI SPÉCIFIER DES VERSIONS ?
# =================================
# 
# La spécification des versions est CRITIQUE pour :
# 
# 1. REPRODUCTIBILITÉ :
#    - Garantir que tous les développeurs utilisent les mêmes versions
#    - Éviter les "ça marche sur ma machine" entre environnements
#    - Assurer la cohérence des déploiements
# 
# 2. STABILITÉ :
#    - Éviter les breaking changes inattendus
#    - Contrôler quand adopter de nouvelles fonctionnalités
#    - Prévenir les régressions en production
# 
# 3. SÉCURITÉ :
#    - Éviter l'utilisation de versions avec des vulnérabilités connues
#    - Planifier les mises à jour de sécurité
#    - Maintenir une baseline sécurisée
# 
# 4. DEBUGGING :
#    - Identifier rapidement les problèmes liés aux versions
#    - Faciliter le support et la résolution d'incidents
#    - Permettre les rollbacks rapides si nécessaire

terraform {
  # ================================================================
  # VERSION MINIMUM DE TERRAFORM
  # ================================================================
  # 
  # EXPLICATION DU CONSTRAINT ">= 1.0" :
  # ====================================
  # 
  # ">= 1.0" signifie : "Version 1.0 ou supérieure"
  # 
  # POURQUOI LA VERSION 1.0+ ?
  # - STABILITÉ : Terraform 1.0+ garantit la compatibilité backward
  # - MATURITÉ : API stable et fonctionnalités bien établies
  # - SUPPORT : Versions activement maintenues et supportées
  # - FONCTIONNALITÉS : State locking, backend S3, etc. pleinement supportés
  # 
  # ALTERNATIVES POSSIBLES :
  # - "= 1.5.7" : Version exacte (très restrictif)
  # - "~> 1.5.0" : Versions 1.5.x uniquement (plus flexible)
  # - ">= 1.0, < 2.0" : Gamme de versions (recommandé pour la production)
  required_version = ">= 1.0"
  
  # ================================================================
  # FOURNISSEURS REQUIS (PROVIDERS)
  # ================================================================
  # 
  # QU'EST-CE QU'UN PROVIDER ?
  # ===========================
  # 
  # Un provider est un plugin qui permet à Terraform d'interagir avec :
  # - Services cloud (AWS, Azure, GCP)
  # - Services SaaS (GitHub, Datadog, PagerDuty)
  # - APIs diverses (Kubernetes, Docker, DNS)
  # 
  # PROVIDER AWS EXPLIQUÉ :
  # =======================
  required_providers {
    aws = {
      # SOURCE : Adresse du provider dans le registre Terraform
      # Format : namespace/provider-type
      # hashicorp/aws = provider officiel AWS maintenu par HashiCorp
      source = "hashicorp/aws"
      
      # VERSION CONSTRAINT "~> 5.0" EXPLIQUÉ :
      # ======================================
      # 
      # "~> 5.0" est appelé "pessimistic constraint operator"
      # Équivalent à : ">= 5.0, < 6.0"
      # 
      # SIGNIFICATION :
      # - Accepte toutes les versions 5.x.x
      # - Refuse les versions 6.0.0 et supérieures
      # - Autorise les mises à jour de sécurité et bug fixes
      # - Bloque les breaking changes majeurs
      # 
      # EXEMPLES DE VERSIONS ACCEPTÉES :
      # ✅ 5.0.0, 5.1.0, 5.15.3, 5.99.99
      # ❌ 4.67.0, 6.0.0, 7.1.0
      # 
      # POURQUOI CE CHOIX EST INTELLIGENT :
      # - Les versions mineures (5.x) ajoutent des fonctionnalités compatibles
      # - Les versions majeures (6.x) peuvent introduire des breaking changes
      # - Équilibre entre stabilité et accès aux nouvelles fonctionnalités
      version = "~> 5.0"
    }
  }
}

# ================================================================
# BONNES PRATIQUES POUR LA GESTION DES VERSIONS
# ================================================================
# 
# 1. COHÉRENCE ENTRE ENVIRONNEMENTS :
#    - Utilisez les mêmes constraints dans dev, staging, et prod
#    - Testez les nouvelles versions d'abord en dev
#    - Déployez progressivement : dev → staging → prod
# 
# 2. MISE À JOUR PLANIFIÉE :
#    - Planifiez régulièrement des mises à jour des versions
#    - Lisez les changelogs avant de mettre à jour
#    - Testez en environnement de développement d'abord
# 
# 3. LOCK FILE (.terraform.lock.hcl) :
#    - Terraform génère automatiquement ce fichier
#    - Il "verrouille" les versions exactes utilisées
#    - Committez ce fichier dans votre VCS (git)
#    - Garantit que tous utilisent exactement les mêmes versions
# 
# 4. SURVEILLANCE DES VULNÉRABILITÉS :
#    - Surveillez les advisories de sécurité
#    - Mettez à jour rapidement en cas de vulnérabilité critique
#    - Utilisez des outils comme Dependabot pour la surveillance automatique
# 
# COMMANDES UTILES :
# ==================
# 
# terraform version              # Affiche les versions actuelles
# terraform providers            # Liste les providers installés
# terraform init -upgrade        # Met à jour vers les dernières versions compatibles
# ================================================================