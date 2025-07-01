# ================================================================
# CONFIGURATION DES VERSIONS - BOOTSTRAP PRODUCTION
# ================================================================
# 
# OBJECTIF PÉDAGOGIQUE : Comprendre la gestion des versions pour la PRODUCTION
# 
# POURQUOI LES VERSIONS SONT CRITIQUES EN PRODUCTION ?
# ====================================================
# 
# En production, la gestion des versions est VITALE pour :
# 
# 1. STABILITÉ MAXIMALE :
#    - Éviter les breaking changes inattendus qui peuvent causer des outages
#    - Garantir la reproductibilité des déploiements critiques
#    - Maintenir la cohérence entre tous les environnements de production
# 
# 2. SÉCURITÉ RENFORCÉE :
#    - Éviter l'adoption de versions avec des vulnérabilités connues
#    - Contrôler rigoureusement quand adopter les patches de sécurité
#    - Maintenir une baseline de sécurité approuvée et auditée
# 
# 3. CONFORMITÉ ET AUDIT :
#    - Prouver la conformité avec des versions spécifiques certifiées
#    - Faciliter les audits de sécurité et de conformité
#    - Documenter l'historique des versions pour la traçabilité
# 
# 4. PRÉVISIBILITÉ ET PLANIFICATION :
#    - Planifier les mises à jour avec des tests approfondis
#    - Éviter les surprises lors des déploiements critiques
#    - Permettre les rollbacks rapides en cas de problème
# 
# 5. SUPPORT ET MAINTENANCE :
#    - Faciliter le support avec des versions stables et documentées
#    - Accélérer la résolution d'incidents avec des versions connues
#    - Maintenir la compatibilité avec les outils de monitoring

terraform {
  # ================================================================
  # VERSION MINIMUM DE TERRAFORM POUR LA PRODUCTION
  # ================================================================
  # 
  # EXPLICATION DU CONSTRAINT ">= 1.0" EN PRODUCTION :
  # ==================================================
  # 
  # ">= 1.0" signifie : "Version 1.0 ou supérieure"
  # 
  # POURQUOI 1.0+ EST REQUIS EN PRODUCTION ?
  # =======================================
  # 
  # STABILITÉ GARANTIE :
  # - Terraform 1.0+ offre une garantie de compatibilité backward
  # - API stable sans breaking changes inattendus
  # - Fonctionnalités de base matures et testées en production
  # 
  # FONCTIONNALITÉS CRITIQUES DISPONIBLES :
  # - State locking fiable avec DynamoDB
  # - Backend S3 avec chiffrement et versioning
  # - Gestion avancée des dépendances
  # - Plan et apply atomiques
  # - Import et move d'états sécurisés
  # 
  # SUPPORT ET MAINTENANCE :
  # - Versions activement maintenues par HashiCorp
  # - Documentation complète et communauté active
  # - Patches de sécurité réguliers
  # 
  # RECOMMANDATIONS POUR LA PRODUCTION :
  # ===================================
  # 
  # POUR PLUS DE CONTRÔLE, CONSIDÉREZ :
  # - "~> 1.5.0" : Autorise uniquement les patches 1.5.x (plus restrictif)
  # - "= 1.5.7" : Version exacte (maximum de contrôle)
  # - ">= 1.0, < 2.0" : Évite les versions 2.x qui pourraient avoir des breaking changes
  required_version = ">= 1.0"
  
  # ================================================================
  # FOURNISSEURS REQUIS POUR LA PRODUCTION
  # ================================================================
  # 
  # IMPORTANCE DES PROVIDERS EN PRODUCTION :
  # =======================================
  # 
  # Les providers sont les plugins qui permettent à Terraform d'interagir avec :
  # - Infrastructure cloud (AWS, Azure, GCP)
  # - Services de monitoring (DataDog, New Relic)
  # - Outils de sécurité (Vault, Auth0)
  # - Services de DNS (CloudFlare, Route53)
  # 
  # CHAQUE PROVIDER DOIT ÊTRE :
  # - Officiellement supporté et maintenu
  # - Testé en production avec des charges réelles
  # - Compatible avec les versions Terraform utilisées
  # - Documenté avec des exemples de production
  required_providers {
    aws = {
      # ================================================================
      # SOURCE DU PROVIDER AWS OFFICIEL
      # ================================================================
      # 
      # "hashicorp/aws" : Provider OFFICIEL AWS maintenu par HashiCorp
      # 
      # POURQUOI UTILISER LE PROVIDER OFFICIEL ?
      # ========================================
      # 
      # FIABILITÉ :
      # - Développé en partenariat avec AWS
      # - Testé contre l'infrastructure AWS réelle
      # - Support officiel de HashiCorp et AWS
      # 
      # SÉCURITÉ :
      # - Patches de sécurité rapides et fiables
      # - Audit de sécurité régulier
      # - Signature cryptographique des releases
      # 
      # FONCTIONNALITÉS :
      # - Support complet des services AWS
      # - Nouvelles fonctionnalités AWS disponibles rapidement
      # - Optimisations de performance continues
      # 
      # ALTERNATIVES NON RECOMMANDÉES :
      # - Providers tiers non maintenus
      # - Forks communautaires sans support
      # - Versions obsolètes ou deprecated
      source = "hashicorp/aws"
      
      # ================================================================
      # VERSION DU PROVIDER AWS POUR LA PRODUCTION
      # ================================================================
      # 
      # CONSTRAINT "~> 5.0" EXPLIQUÉ EN DÉTAIL :
      # ========================================
      # 
      # "~> 5.0" est le "pessimistic constraint operator"
      # Équivalent précis à : ">= 5.0.0, < 6.0.0"
      # 
      # QUE SIGNIFIE CETTE CONTRAINTE ?
      # ===============================
      # 
      # VERSIONS ACCEPTÉES (✅) :
      # - 5.0.0, 5.0.1, 5.0.2 (patches de sécurité)
      # - 5.1.0, 5.2.0, 5.15.0 (nouvelles fonctionnalités mineures)
      # - 5.99.99 (toutes les versions 5.x.x)
      # 
      # VERSIONS REFUSÉES (❌) :
      # - 4.67.0 (versions antérieures)
      # - 6.0.0 (breaking changes potentiels)
      # - 7.1.0 (versions majeures futures)
      # 
      # AVANTAGES DE CE CHOIX EN PRODUCTION :
      # ====================================
      # 
      # STABILITÉ :
      # - Les versions mineures (5.1, 5.2) ajoutent des fonctionnalités compatibles
      # - Pas de breaking changes au sein de la version majeure 5.x
      # - Mises à jour de sécurité automatiques (5.0.1, 5.0.2, etc.)
      # 
      # SÉCURITÉ :
      # - Patches de sécurité appliqués automatiquement
      # - Pas de risque d'utiliser des versions vulnérables
      # - Contrôle sur l'adoption des versions majeures
      # 
      # FONCTIONNALITÉS :
      # - Accès aux nouvelles ressources AWS dans les versions 5.x
      # - Améliorations de performance et de fiabilité
      # - Bug fixes automatiques
      # 
      # CONTRÔLE :
      # - Évite les breaking changes des versions 6.x
      # - Permet de planifier les migrations vers des versions majeures
      # - Équilibre entre stabilité et innovation
      version = "~> 5.0"
    }
  }
}

# ================================================================
# BONNES PRATIQUES POUR LA GESTION DES VERSIONS EN PRODUCTION
# ================================================================
# 
# 1. COHÉRENCE ABSOLUE ENTRE ENVIRONNEMENTS :
#    ==========================================
#    - MÊME constraints dans dev, staging, et prod
#    - Testez TOUJOURS les nouvelles versions en dev d'abord
#    - Pipeline de promotion : dev → staging → prod
#    - Validation complète à chaque étape
# 
# 2. STRATÉGIE DE MISE À JOUR PLANIFIÉE :
#    ====================================
#    - Planifiez des fenêtres de maintenance dédiées
#    - Lisez TOUS les changelogs et breaking changes
#    - Testez en environnement de développement pendant plusieurs jours
#    - Préparez un plan de rollback avant toute mise à jour prod
# 
# 3. LOCK FILE (.terraform.lock.hcl) CRITIQUE :
#    ===========================================
#    - Terraform génère ce fichier automatiquement
#    - Il "verrouille" les versions EXACTES utilisées en production
#    - TOUJOURS committer ce fichier dans votre VCS (git)
#    - Garantit que TOUS les développeurs/pipelines utilisent les mêmes versions
#    - Évite les "ça marche sur ma machine" en production
# 
# 4. SURVEILLANCE DES VULNÉRABILITÉS EN PRODUCTION :
#    ===============================================
#    - Surveillez activement les security advisories de HashiCorp
#    - Abonnez-vous aux notifications de sécurité AWS
#    - Utilisez des outils comme Dependabot pour la surveillance automatique
#    - Maintenez un registre des versions approuvées pour la production
#    - Testez les patches de sécurité en urgence mais avec précaution
# 
# 5. DOCUMENTATION ET TRAÇABILITÉ :
#    ===============================
#    - Documentez TOUS les changements de version en production
#    - Maintenez un changelog interne des mises à jour
#    - Associez les versions aux déploiements dans vos outils de monitoring
#    - Gardez un historique des versions pour la conformité et les audits
# 
# COMMANDES UTILES POUR LA PRODUCTION :
# =====================================
# 
# terraform version                    # Vérifiez les versions actuelles
# terraform providers                  # Listez tous les providers installés
# terraform providers lock             # Régénérez le lock file après changement
# terraform init -upgrade              # Mettez à jour vers les dernières versions compatibles
# terraform init -upgrade=false        # Utilisez exactement les versions du lock file
# 
# EXEMPLE DE WORKFLOW DE MISE À JOUR EN PRODUCTION :
# ==================================================
# 
# 1. Développement :
#    - Testez la nouvelle version en dev pendant 1-2 semaines
#    - Validez que toutes les fonctionnalités existantes marchent
#    - Testez les nouvelles fonctionnalités si utilisées
# 
# 2. Staging :
#    - Déployez en staging avec les données de production (anonymisées)
#    - Exécutez une suite complète de tests
#    - Validez les performances sous charge réaliste
# 
# 3. Production :
#    - Planifiez une fenêtre de maintenance
#    - Préparez le plan de rollback (versions précédentes + backup d'état)
#    - Déployez pendant les heures creuses
#    - Surveillez activement les métriques post-déploiement
# ================================================================