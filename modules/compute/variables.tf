# ========================================================================================================
# VARIABLES D'ENTRÉE DU MODULE COMPUTE - CONFIGURATION ÉDUCATIVE DÉTAILLÉE
# ========================================================================================================
#
# Ce fichier définit toutes les variables que les utilisateurs peuvent passer à ce module.
# Les variables permettent de rendre le module réutilisable et configurable.
#
# STRUCTURE D'UNE VARIABLE TERRAFORM :
# - description : Explication de ce que fait la variable
# - type : Type de données (string, number, bool, list, map, etc.)
# - default : Valeur par défaut (optionnel)
# - validation : Règles de validation (optionnel)
# ========================================================================================================

# ========================================================================================================
# SECTION 1 : VARIABLES DE BASE - OBLIGATOIRES
# ========================================================================================================

# NOM DU PROJET
# Cette variable est utilisée dans tous les noms de ressources pour l'organisation
# BONNE PRATIQUE : Utiliser des noms courts et sans espaces (ex: "webapp", "api", "blog")
variable "project_name" {
  description = "Nom du projet - utilisé comme préfixe pour toutes les ressources créées"
  type        = string
  # Pas de valeur par défaut = variable obligatoire
}

# ENVIRONNEMENT DE DÉPLOIEMENT
# Permet de différencier les déploiements (dev, staging, prod)
# POURQUOI IMPORTANT ? Pour éviter les conflits de noms et organiser les ressources
variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod) - utilisé pour nommer et taguer les ressources"
  type        = string
  # Pas de valeur par défaut = variable obligatoire
}

# ========================================================================================================
# SECTION 2 : CONFIGURATION DE L'INSTANCE EC2
# ========================================================================================================

# TYPE D'INSTANCE EC2
# Détermine les performances et le coût de l'instance
# EXEMPLES COURANTS :
# - t2.micro : 1 vCPU, 1 GB RAM (gratuit tier)
# - t3.small : 2 vCPU, 2 GB RAM
# - t3.medium : 2 vCPU, 4 GB RAM
variable "instance_type" {
  description = "Type d'instance EC2 - détermine CPU, RAM et performances réseau (ex: t2.micro, t3.small, t3.medium)"
  type        = string
  default     = "t2.micro"  # Valeur par défaut = économique et éligible au niveau gratuit
}

# ========================================================================================================
# SECTION 3 : CONFIGURATION RÉSEAU - VARIABLES OBLIGATOIRES
# ========================================================================================================

# ID DU GROUPE DE SÉCURITÉ
# Un Security Group agit comme un firewall virtuel pour contrôler le trafic
# FOURNI PAR : Le module networking qui crée les groupes de sécurité
variable "security_group_id" {
  description = "ID du Security Group à attacher aux instances - contrôle les règles de firewall (fourni par le module networking)"
  type        = string
  # Pas de valeur par défaut = doit être fourni par le module appelant
}

# ID DU SOUS-RÉSEAU (MODE STANDALONE)
# Détermine dans quel sous-réseau déployer l'instance standalone
# FOURNI PAR : Le module networking qui crée les sous-réseaux
variable "subnet_id" {
  description = "ID du sous-réseau pour l'instance standalone - détermine la zone de disponibilité et la connectivité (fourni par le module networking)"
  type        = string
  # Pas de valeur par défaut = doit être fourni par le module appelant
}

# ========================================================================================================
# SECTION 4 : CONFIGURATION RÉSEAU AVANCÉE
# ========================================================================================================

# CRÉATION D'UNE ELASTIC IP
# Une Elastic IP est une adresse IP publique fixe
# ATTENTION : Coûte de l'argent si non attachée à une instance en cours d'exécution
variable "create_eip" {
  description = "Créer une Elastic IP pour l'instance standalone - IP publique fixe qui ne change pas (coût supplémentaire, non compatible avec Auto Scaling)"
  type        = bool
  default     = false  # Par défaut false pour éviter les coûts inattendus
}

# ========================================================================================================
# SECTION 5 : CONFIGURATION DU STOCKAGE EBS
# ========================================================================================================

# TYPE DE VOLUME EBS
# Différents types offrent différentes performances et coûts :
# - gp2 : General Purpose SSD (ancienne génération)
# - gp3 : General Purpose SSD (nouvelle génération, plus économique)
# - io1/io2 : Provisioned IOPS SSD (haute performance)
variable "root_volume_type" {
  description = "Type de volume EBS pour le disque racine - gp3 recommandé (plus récent et économique que gp2)"
  type        = string
  default     = "gp3"  # gp3 est plus récent et plus économique que gp2
}

# TAILLE DU VOLUME EBS
# Taille en gigaoctets du disque racine
# MINIMUM : 8 GB pour Amazon Linux 2
# CONSIDÉRATION : Plus grand = plus cher
variable "root_volume_size" {
  description = "Taille du volume EBS racine en gigaoctets - minimum 8 GB pour Amazon Linux 2"
  type        = number
  default     = 8  # Minimum requis pour Amazon Linux 2
}

# CHIFFREMENT DU VOLUME
# Chiffre les données au repos pour la sécurité
# RECOMMANDATION : Toujours activer en production
variable "encrypt_volume" {
  description = "Activer le chiffrement du volume EBS - fortement recommandé pour la sécurité des données"
  type        = bool
  default     = true  # Activé par défaut pour la sécurité
}

# ========================================================================================================
# SECTION 6 : GESTION DES TAGS
# ========================================================================================================

# TAGS COMMUNS
# Les tags permettent d'organiser et de facturer les ressources AWS
# EXEMPLES DE TAGS UTILES : Owner, CostCenter, Project, Environment
variable "common_tags" {
  description = "Tags communs appliqués à toutes les ressources - utile pour l'organisation et la facturation (ex: Owner, CostCenter)"
  type        = map(string)
  default     = {}  # Map vide par défaut, peut être surchargé par l'utilisateur
}

# ========================================================================================================
# SECTION 7 : VARIABLES AUTO SCALING GROUP - MODE HAUTE DISPONIBILITÉ
# ========================================================================================================

# ACTIVATION DU MODE AUTO SCALING
# Cette variable détermine le mode de déploiement du module
# false = Mode standalone (1 instance EC2 classique)
# true = Mode Auto Scaling Group (instances gérées automatiquement)
variable "enable_auto_scaling" {
  description = "Activer le mode Auto Scaling Group - false=instance standalone, true=ASG avec haute disponibilité"
  type        = bool
  default     = false  # Par défaut standalone pour simplicité
}

# SOUS-RÉSEAUX POUR AUTO SCALING GROUP
# Liste des sous-réseaux où l'ASG peut déployer des instances
# BONNE PRATIQUE : Utiliser des sous-réseaux dans différentes zones de disponibilité
# POURQUOI ? Pour la haute disponibilité en cas de panne d'une zone
variable "subnet_ids" {
  description = "Liste des IDs de sous-réseaux pour l'Auto Scaling Group - recommandé: sous-réseaux dans différentes zones pour haute disponibilité"
  type        = list(string)
  default     = []  # Liste vide par défaut, doit être fournie si enable_auto_scaling = true
}

# TARGET GROUPS POUR LOAD BALANCER
# ARNs des Target Groups du Load Balancer où enregistrer les instances ASG
# UTILISATION : Pour intégrer l'ASG avec un Application Load Balancer
# OPTIONNEL : Peut être vide si pas de Load Balancer
variable "target_group_arns" {
  description = "ARNs des Target Groups du Load Balancer - optionnel, pour intégrer l'ASG avec un ALB/NLB"
  type        = list(string)
  default     = []  # Liste vide par défaut = pas de Load Balancer
}

# ========================================================================================================
# SECTION 8 : CONFIGURATION DE LA TAILLE DE L'AUTO SCALING GROUP
# ========================================================================================================

# NOMBRE MINIMUM D'INSTANCES
# L'ASG maintiendra toujours au moins ce nombre d'instances
# CONSIDÉRATION : Plus élevé = plus de disponibilité mais plus de coût
variable "asg_min_size" {
  description = "Nombre minimum d'instances dans l'ASG - maintenu en permanence même en cas de faible charge"
  type        = number
  default     = 1  # Au moins 1 instance pour éviter les interruptions
}

# NOMBRE MAXIMUM D'INSTANCES
# L'ASG ne créera jamais plus que ce nombre d'instances
# CONSIDÉRATION : Limite les coûts en cas de pic de charge
variable "asg_max_size" {
  description = "Nombre maximum d'instances dans l'ASG - limite les coûts lors des pics de charge"
  type        = number
  default     = 2  # Maximum 2 instances par défaut pour contrôler les coûts
}

# NOMBRE DÉSIRÉ D'INSTANCES
# Nombre d'instances que l'ASG essaie de maintenir en temps normal
# RÈGLE : min_size ≤ desired_capacity ≤ max_size
variable "asg_desired_capacity" {
  description = "Nombre désiré d'instances dans l'ASG - cible normale, doit être entre min_size et max_size"
  type        = number
  default     = 1  # 1 instance par défaut, peut être augmenté selon les besoins
}