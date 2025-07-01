# ========================================================================================================
# MODULE COMPUTE TERRAFORM - GESTION DES INSTANCES EC2 AVEC DEUX MODES DE DÉPLOIEMENT
# ========================================================================================================
# 
# Ce module Terraform permet de déployer des instances EC2 sur AWS avec deux modes de déploiement :
# 1. MODE STANDALONE : Une seule instance EC2 classique (enable_auto_scaling = false)
# 2. MODE AUTO SCALING : Utilise un Auto Scaling Group avec Launch Template (enable_auto_scaling = true)
#
# POURQUOI DEUX MODES ?
# - Mode standalone : Idéal pour les environnements de développement, tests, ou applications simples
# - Mode Auto Scaling : Idéal pour la production avec haute disponibilité et mise à l'échelle automatique
#
# SÉCURITÉ : Toutes les instances utilisent AWS Systems Manager Session Manager pour l'accès
# (pas de clés SSH nécessaires, pas de ports SSH ouverts)
# ========================================================================================================

# ========================================================================================================
# SECTION 1 : GESTION DES RÔLES IAM POUR AWS SYSTEMS MANAGER
# ========================================================================================================

# CRÉATION DU RÔLE IAM POUR SESSION MANAGER
# Un rôle IAM est nécessaire pour permettre aux instances EC2 d'utiliser AWS Systems Manager
# Ce rôle définit QUI peut assumer ce rôle (ici, le service EC2)
resource "aws_iam_role" "ssm_role" {
  # Préfixe du nom du rôle - AWS ajoutera un suffixe aléatoire pour éviter les conflits
  name_prefix = "${var.project_name}-${var.environment}-ssm-"
  
  # POLITIQUE D'ASSOMPTION DE RÔLE (Trust Policy)
  # Cette politique définit QUELS services AWS peuvent "assumer" (utiliser) ce rôle
  # Ici, nous autorisons le service EC2 à utiliser ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"  # Version de la politique IAM (obligatoire)
    Statement = [
      {
        Action = "sts:AssumeRole"      # Action d'assomption de rôle
        Effect = "Allow"               # Autoriser cette action
        Principal = {
          Service = "ec2.amazonaws.com" # Le service EC2 peut assumer ce rôle
        }
      }
    ]
  })

  # TAGS : Étiquetage des ressources pour l'organisation et la facturation
  # merge() combine les tags communs avec des tags spécifiques à cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-role"
    Type = "IAMRole"  # Tag personnalisé pour identifier le type de ressource
  })
}

# ATTACHEMENT DE LA POLITIQUE AWS MANAGÉE POUR SESSION MANAGER
# Une fois le rôle créé, nous devons lui attacher des permissions spécifiques
# AWS fournit des politiques pré-construites (AWS Managed Policies) pour éviter d'écrire des politiques complexes
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name  # Référence au rôle créé ci-dessus
  
  # ARN de la politique AWS managée pour Session Manager
  # Cette politique contient toutes les permissions nécessaires pour :
  # - Permettre à l'agent SSM de s'enregistrer
  # - Autoriser les connexions Session Manager
  # - Permettre l'exécution de commandes à distance
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CRÉATION DU PROFIL D'INSTANCE EC2
# Un Instance Profile est un "conteneur" qui permet d'attacher un rôle IAM à une instance EC2
# POURQUOI NÉCESSAIRE ? Les instances EC2 ne peuvent pas utiliser directement un rôle IAM,
# elles ont besoin d'un Instance Profile qui fait le lien
resource "aws_iam_instance_profile" "ssm_profile" {
  name_prefix = "${var.project_name}-${var.environment}-ssm-"
  role        = aws_iam_role.ssm_role.name  # Associe le rôle au profil

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-profile"
    Type = "InstanceProfile"
  })
}

# ========================================================================================================
# SECTION 2 : SOURCES DE DONNÉES ET CONFIGURATION LOCALE
# ========================================================================================================

# RÉCUPÉRATION DE LA RÉGION AWS ACTUELLE
# Cette data source nous permet de connaître dynamiquement la région où nous déployons
# Utile pour construire des ARNs ou des commandes qui nécessitent la région
data "aws_region" "current" {}

# RÉCUPÉRATION DE L'AMI AMAZON LINUX LA PLUS RÉCENTE
# Une AMI (Amazon Machine Image) est un modèle qui contient le système d'exploitation
# et les logiciels nécessaires pour lancer une instance
# POURQUOI RÉCUPÉRER DYNAMIQUEMENT ? Pour toujours utiliser la version la plus récente et sécurisée
data "aws_ami" "amazon_linux" {
  most_recent = true    # Prendre la plus récente
  owners      = ["amazon"]  # Seulement les AMI officielles d'Amazon

  # FILTRE 1 : Pattern du nom de l'AMI
  # "amzn2-ami-hvm-*-x86_64-gp2" correspond à Amazon Linux 2 avec :
  # - hvm : Type de virtualisation (Hardware Virtual Machine)
  # - x86_64 : Architecture 64 bits
  # - gp2 : Type de stockage EBS General Purpose SSD
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  # FILTRE 2 : Type de virtualisation
  # HVM est plus performant que PV (paravirtual) et supporté par tous les types d'instances modernes
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CONFIGURATION LOCALE : PRÉPARATION DU SCRIPT USER DATA
# templatefile() permet d'injecter des variables dans un fichier template
# Le script user-data.sh sera exécuté au démarrage de chaque instance
locals {
  user_data = templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name  # Variable injectée dans le script
    environment  = var.environment   # Variable injectée dans le script
  })
}

# ========================================================================================================
# SECTION 3 : MODE STANDALONE - INSTANCE EC2 UNIQUE
# ========================================================================================================

# CRÉATION D'UNE INSTANCE EC2 STANDALONE
# Cette ressource n'est créée QUE si var.enable_auto_scaling = false
# AVANTAGES du mode standalone : Simplicité, coût réduit, idéal pour dev/test
# INCONVÉNIENTS : Pas de haute disponibilité, pas de mise à l'échelle automatique
resource "aws_instance" "web_server" {
  # LOGIQUE CONDITIONNELLE : count = 0 signifie "ne pas créer cette ressource"
  # Si enable_auto_scaling = true, alors count = 0 (pas d'instance standalone)
  # Si enable_auto_scaling = false, alors count = 1 (créer 1 instance standalone)
  count = var.enable_auto_scaling ? 0 : 1
  
  # CONFIGURATION DE BASE DE L'INSTANCE
  ami                    = data.aws_ami.amazon_linux.id  # AMI récupérée dynamiquement
  instance_type          = var.instance_type             # Type d'instance (t2.micro, t3.small, etc.)
  vpc_security_group_ids = [var.security_group_id]       # Groupes de sécurité (firewall)
  subnet_id              = var.subnet_id                 # Sous-réseau où déployer l'instance
  
  # PROFIL IAM POUR SESSION MANAGER
  # Attache le profil d'instance qui contient le rôle IAM pour SSM
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  
  # SCRIPT DE DÉMARRAGE (USER DATA)
  # base64encode() encode le script en base64 (format requis par AWS)
  # Ce script s'exécute une seule fois au premier démarrage de l'instance
  user_data                   = base64encode(local.user_data)
  # Si le user_data change, remplacer l'instance (pour appliquer les changements)
  user_data_replace_on_change = true

  # CONFIGURATION DU DISQUE RACINE
  # Chaque instance EC2 a un volume EBS racine qui contient le système d'exploitation
  root_block_device {
    volume_type           = var.root_volume_type    # Type de volume EBS (gp2, gp3, io1, etc.)
    volume_size           = var.root_volume_size    # Taille en GB
    delete_on_termination = true                    # Supprimer le volume quand l'instance est terminée
    encrypted             = var.encrypt_volume      # Chiffrement du volume (recommandé)

    # Tags spécifiques au volume EBS
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-root-volume"
    })
  }

  # TAGS DE L'INSTANCE EC2
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-instance"
    Type = "WebServer"  # Tag métier pour identifier le rôle de l'instance
  })

  # RÈGLES DE CYCLE DE VIE
  # ignore_changes = [ami] : Ne pas recréer l'instance si l'AMI change
  # POURQUOI ? Car les AMI changent fréquemment et on ne veut pas détruire l'instance
  # pour chaque nouvelle version d'AMI
  lifecycle {
    ignore_changes = [ami]
  }
}

# ========================================================================================================
# SECTION 4 : MODE AUTO SCALING - LAUNCH TEMPLATE
# ========================================================================================================

# CRÉATION DU LAUNCH TEMPLATE POUR AUTO SCALING GROUP
# Un Launch Template définit la "recette" pour créer des instances dans un Auto Scaling Group
# DIFFÉRENCE avec instance standalone : Le Launch Template ne crée pas d'instance directement,
# il définit juste la configuration que l'ASG utilisera pour créer des instances
# Cette ressource n'est créée QUE si var.enable_auto_scaling = true
resource "aws_launch_template" "web_server" {
  # LOGIQUE CONDITIONNELLE : inverse de l'instance standalone
  # Si enable_auto_scaling = true, alors count = 1 (créer le launch template)
  # Si enable_auto_scaling = false, alors count = 0 (pas de launch template)
  count = var.enable_auto_scaling ? 1 : 0
  
  # CONFIGURATION DE BASE DU TEMPLATE
  name_prefix   = "${var.project_name}-${var.environment}-"    # Préfixe pour le nom
  image_id      = data.aws_ami.amazon_linux.id                # Même AMI que le mode standalone
  instance_type = var.instance_type                           # Type d'instance
  
  # CONFIGURATION RÉSEAU SPÉCIFIQUE POUR ASG
  # DIFFÉRENCE IMPORTANTE : Les instances ASG n'ont généralement pas d'IP publique
  # car elles sont souvent derrière un Load Balancer
  network_interfaces {
    associate_public_ip_address = false                       # Pas d'IP publique pour ASG
    security_groups             = [var.security_group_id]     # Groupes de sécurité
    delete_on_termination       = true                        # Supprimer l'interface réseau avec l'instance
  }
  
  # PROFIL IAM POUR SESSION MANAGER
  # Même configuration que l'instance standalone
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }
  
  # SCRIPT DE DÉMARRAGE
  # Même script user_data que l'instance standalone
  user_data = base64encode(local.user_data)
  
  # CONFIGURATION DU STOCKAGE EBS
  # Dans un Launch Template, on utilise block_device_mappings au lieu de root_block_device
  block_device_mappings {
    device_name = "/dev/xvda"    # Nom du device pour Amazon Linux (point de montage racine)
    ebs {
      volume_type           = var.root_volume_type    # Type de volume EBS
      volume_size           = var.root_volume_size    # Taille en GB
      delete_on_termination = true                    # Supprimer avec l'instance
      encrypted             = var.encrypt_volume      # Chiffrement
    }
  }
  
  # SPÉCIFICATION DES TAGS POUR LES INSTANCES CRÉÉES PAR CE TEMPLATE
  # resource_type = "instance" : Tags appliqués aux instances EC2 créées
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-asg-instance"
      Type = "WebServer"
    })
  }
  
  # SPÉCIFICATION DES TAGS POUR LES VOLUMES EBS CRÉÉS PAR CE TEMPLATE
  # resource_type = "volume" : Tags appliqués aux volumes EBS créés
  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-asg-volume"
    })
  }
  
  # TAGS DU LAUNCH TEMPLATE LUI-MÊME
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-launch-template"
    Type = "LaunchTemplate"
  })
  
  # RÈGLE DE CYCLE DE VIE POUR LES MISES À JOUR
  # create_before_destroy = true : Créer la nouvelle version avant de détruire l'ancienne
  # POURQUOI ? Pour éviter les interruptions de service lors des mises à jour
  lifecycle {
    create_before_destroy = true
  }
}

# ========================================================================================================
# SECTION 5 : AUTO SCALING GROUP - GESTION AUTOMATIQUE DES INSTANCES
# ========================================================================================================

# CRÉATION DE L'AUTO SCALING GROUP
# Un ASG gère automatiquement un groupe d'instances EC2 :
# - Maintient le nombre désiré d'instances en fonctionnement
# - Remplace automatiquement les instances défaillantes
# - Peut augmenter/diminuer le nombre d'instances selon la charge (scaling)
# - Distribue les instances dans plusieurs zones de disponibilité pour la haute disponibilité
resource "aws_autoscaling_group" "web_server" {
  # LOGIQUE CONDITIONNELLE : Même que le Launch Template
  count = var.enable_auto_scaling ? 1 : 0
  
  # CONFIGURATION DE BASE DE L'ASG
  name                = "${var.project_name}-${var.environment}-asg"
  
  # DISTRIBUTION GÉOGRAPHIQUE ET RÉSEAU
  # vpc_zone_identifier : Liste des sous-réseaux où déployer les instances
  # L'ASG distribuera automatiquement les instances dans ces sous-réseaux
  # AVANTAGE : Haute disponibilité en cas de panne d'une zone de disponibilité
  vpc_zone_identifier = var.subnet_ids
  
  # INTÉGRATION AVEC LOAD BALANCER (OPTIONNEL)
  # target_group_arns : ARNs des Target Groups du Load Balancer
  # Si fourni, l'ASG enregistrera automatiquement les instances dans ces Target Groups
  target_group_arns   = var.target_group_arns
  
  # CONFIGURATION DES VÉRIFICATIONS DE SANTÉ
  # health_check_type = "ELB" : Utilise les health checks du Load Balancer
  # Alternative : "EC2" (vérifie seulement si l'instance EC2 répond)
  # POURQUOI ELB ? Plus précis car vérifie si l'application répond correctement
  health_check_type   = "ELB"
  # Délai d'attente avant de commencer les health checks (temps pour que l'instance démarre)
  health_check_grace_period = 300  # 5 minutes
  
  # CONFIGURATION DE LA TAILLE DE L'ASG
  # Ces valeurs définissent combien d'instances l'ASG va maintenir
  min_size         = var.asg_min_size           # Minimum d'instances (jamais moins)
  max_size         = var.asg_max_size           # Maximum d'instances (jamais plus)
  desired_capacity = var.asg_desired_capacity   # Nombre désiré d'instances (cible)
  
  # RÉFÉRENCE AU LAUNCH TEMPLATE
  # L'ASG utilise ce template pour créer de nouvelles instances
  launch_template {
    id      = aws_launch_template.web_server[0].id  # ID du Launch Template créé ci-dessus
    version = "$Latest"  # Utilise toujours la dernière version du template
    # Alternative : version spécifique comme "1", "2", etc.
  }
  
  # STRATÉGIE DE RAFRAÎCHISSEMENT DES INSTANCES
  # Instance refresh permet de mettre à jour les instances existantes
  # quand le Launch Template change (nouvelle AMI, nouveau user_data, etc.)
  instance_refresh {
    strategy = "Rolling"  # Remplace les instances une par une (pas toutes en même temps)
    preferences {
      # Pourcentage minimum d'instances qui doivent rester "saines" pendant le refresh
      # 50% signifie qu'au moins la moitié des instances reste disponible pendant la mise à jour
      min_healthy_percentage = 50
    }
  }
  
  # GESTION DES TAGS - VERSION SPÉCIALE POUR ASG
  # Les ASG ont une syntaxe spéciale pour les tags car ils peuvent être propagés aux instances
  
  # TAG SPÉCIFIQUE À L'ASG (pas propagé aux instances)
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false  # Ce tag reste sur l'ASG seulement
  }
  
  # TAGS DYNAMIQUES PROPAGÉS AUX INSTANCES
  # dynamic "tag" permet de créer un bloc tag pour chaque élément de var.common_tags
  # C'est équivalent à écrire un bloc tag {...} pour chaque tag dans common_tags
  dynamic "tag" {
    for_each = var.common_tags  # Pour chaque tag dans common_tags
    content {
      key                 = tag.key    # Clé du tag actuel
      value               = tag.value  # Valeur du tag actuel
      propagate_at_launch = true       # Propager ce tag aux instances créées
    }
  }
  
  # RÈGLE DE CYCLE DE VIE
  # Même règle que le Launch Template pour éviter les interruptions
  lifecycle {
    create_before_destroy = true
  }
}

# ========================================================================================================
# SECTION 6 : ELASTIC IP (OPTIONNEL) - SEULEMENT POUR MODE STANDALONE
# ========================================================================================================

# CRÉATION D'UNE ELASTIC IP (ADRESSE IP PUBLIQUE FIXE)
# Une Elastic IP est une adresse IP publique statique que vous pouvez attacher à une instance
# AVANTAGES : L'IP ne change pas si l'instance redémarre ou est remplacée
# INCONVÉNIENTS : Coût supplémentaire si non utilisée, non compatible avec Auto Scaling Group
resource "aws_eip" "web_server" {
  # LOGIQUE CONDITIONNELLE COMPLEXE : Créer seulement si :
  # 1. var.create_eip = true (l'utilisateur veut une EIP)
  # 2. ET var.enable_auto_scaling = false (mode standalone seulement)
  # POURQUOI ? Les Auto Scaling Groups ne peuvent pas utiliser d'Elastic IP
  # car les instances peuvent être créées/détruites dynamiquement
  count    = var.create_eip && !var.enable_auto_scaling ? 1 : 0
  
  # ATTACHEMENT À L'INSTANCE STANDALONE
  instance = aws_instance.web_server[0].id  # Référence à l'instance créée
  
  # DOMAINE VPC : Indique que l'EIP est pour une instance dans un VPC
  # (par opposition au réseau classique EC2, qui est déprécié)
  domain   = "vpc"

  # TAGS DE L'ELASTIC IP
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eip"
  })

  # DÉPENDANCE EXPLICITE
  # depends_on assure que l'instance est créée avant l'EIP
  # Normalement Terraform gère les dépendances automatiquement via les références,
  # mais c'est une sécurité supplémentaire pour éviter les erreurs de timing
  depends_on = [aws_instance.web_server]
}
