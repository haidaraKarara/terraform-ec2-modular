# modules/networking/main.tf
# Module pour la gestion du réseau et sécurité
# Ce module crée l'infrastructure réseau complète pour notre application
#
# 🎯 STRATÉGIE COUNT POUR LA HAUTE DISPONIBILITÉ
# ===============================================
# Ce module utilise la variable `count` pour créer une architecture multi-AZ :
#
# 📊 RESSOURCES CRÉÉES AVEC COUNT :
# • 2 sous-réseaux publics (aws_subnet.public)
# • 2 associations de routage (aws_route_table_association.public)
#
# 🔄 FONCTIONNEMENT DE COUNT :
# • count = 2 → Terraform crée 2 instances de la ressource
# • count.index → Variable automatique (0, 1, 2...) pour différencier chaque instance
# • aws_subnet.public[0] → Premier sous-réseau (AZ 1, CIDR 10.0.1.0/24)
# • aws_subnet.public[1] → Deuxième sous-réseau (AZ 2, CIDR 10.0.2.0/24)
#
# 🌍 AVANTAGES MULTI-AZ :
# • Haute disponibilité : Si une AZ tombe, l'autre continue
# • Distribution géographique : Résilience aux pannes datacenter
# • Load balancing : Trafic réparti sur plusieurs zones
# • Conformité : Respect des bonnes pratiques AWS

# ========================================
# DÉTECTION AUTOMATIQUE DES ZONES DE DISPONIBILITÉ
# ========================================

# Cette ressource "data" permet de récupérer automatiquement la liste
# des zones de disponibilité (AZ) disponibles dans la région AWS choisie
data "aws_availability_zones" "available" {
  state = "available"  # Filtre pour ne récupérer que les AZ actives
}

# ========================================
# CRÉATION DU VPC (VIRTUAL PRIVATE CLOUD)
# ========================================

# Le VPC est notre réseau privé virtuel dans AWS
# C'est l'équivalent d'un centre de données virtuel isolé
resource "aws_vpc" "main" {
  # Définit la plage d'adresses IP privées pour notre VPC (ex: 10.0.0.0/16)
  cidr_block = var.vpc_cidr
  
  # Active la résolution DNS des noms d'hôtes dans le VPC
  # Permet aux instances d'avoir des noms DNS plutôt que juste des IPs
  enable_dns_hostnames = true
  
  # Active le support DNS dans le VPC
  # Nécessaire pour que les instances puissent résoudre les noms de domaine
  enable_dns_support = true

  # Fusion des tags communs avec des tags spécifiques à cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"  # Nom unique du VPC
    Type = "VPC"  # Type de ressource pour faciliter la gestion
  })
}

# ========================================
# PASSERELLE INTERNET (INTERNET GATEWAY)
# ========================================

# L'Internet Gateway permet aux ressources du VPC d'accéder à Internet
# C'est le pont entre notre réseau privé et Internet
resource "aws_internet_gateway" "main" {
  # Attache cette passerelle à notre VPC
  vpc_id = aws_vpc.main.id

  # Tags pour identifier et organiser cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"  # Nom unique de la passerelle
    Type = "InternetGateway"  # Type de ressource
  })
}

# ========================================
# SOUS-RÉSEAUX PUBLICS (PUBLIC SUBNETS)
# ========================================

# Crée 2 sous-réseaux publics dans différentes zones de disponibilité
# Cela assure la haute disponibilité de notre application
resource "aws_subnet" "public" {
  
  # ========================================
  # MÉTA-ARGUMENT COUNT : CRÉATION MULTIPLE
  # ========================================
  
  # count = 2 signifie "créer 2 instances de cette ressource"
  # Terraform va exécuter ce bloc 2 fois avec count.index = 0, puis count.index = 1
  count = 2
  
  # ========================================
  # CONFIGURATION DE BASE (IDENTIQUE POUR TOUS)
  # ========================================

  # Associe chaque sous-réseau à notre VPC (même VPC pour tous)
  vpc_id = aws_vpc.main.id
  
  # ========================================
  # CONFIGURATION DYNAMIQUE (DIFFÉRENTE POUR CHAQUE)
  # ========================================
  
  # Calcule automatiquement le CIDR de chaque sous-réseau en utilisant count.index
  # count.index = 0 → "10.0.${0 + 1}.0/24" = "10.0.1.0/24" (Subnet 1)
  # count.index = 1 → "10.0.${1 + 1}.0/24" = "10.0.2.0/24" (Subnet 2)
  # Résultat : 2 sous-réseaux avec des plages IP différentes
  cidr_block = "10.0.${count.index + 1}.0/24"
  
  # Sélectionne une zone de disponibilité différente pour chaque sous-réseau
  # count.index = 0 → data.aws_availability_zones.available.names[0] (ex: us-east-1a)
  # count.index = 1 → data.aws_availability_zones.available.names[1] (ex: us-east-1b)
  # Résultat : Distribution géographique pour haute disponibilité
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # NE PAS attribuer d'IP publique automatiquement aux instances
  # Sécurité renforcée : les instances n'auront pas d'accès direct à Internet
  map_public_ip_on_launch = false

  # ========================================
  # TAGS DYNAMIQUES (UTILISATION DE COUNT.INDEX)
  # ========================================
  
  # Tags pour identifier chaque sous-réseau individuellement
  tags = merge(var.common_tags, {
    # Nom unique pour chaque sous-réseau utilisant count.index
    # count.index = 0 → "projet-dev-public-subnet-1"
    # count.index = 1 → "projet-dev-public-subnet-2"
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    
    Type = "PublicSubnet"  # Type identique pour tous
    
    # Zone de disponibilité spécifique à chaque sous-réseau
    # Utilise le même index que pour availability_zone
    AZ = data.aws_availability_zones.available.names[count.index]
  })
}

# ========================================
# TABLE DE ROUTAGE POUR LES SOUS-RÉSEAUX PUBLICS
# ========================================

# La table de routage définit comment le trafic réseau est dirigé
# Elle indique où envoyer les paquets selon leur destination
resource "aws_route_table" "public" {
  # Associe cette table de routage à notre VPC
  vpc_id = aws_vpc.main.id

  # Définit une route par défaut vers Internet
  route {
    # 0.0.0.0/0 signifie "toutes les adresses IP" (route par défaut)
    cidr_block = "0.0.0.0/0"
    
    # Dirige tout le trafic vers l'Internet Gateway
    # Cela permet aux ressources des sous-réseaux d'accéder à Internet
    gateway_id = aws_internet_gateway.main.id
  }

  # Tags pour identifier cette table de routage
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"  # Nom unique
    Type = "RouteTable"  # Type de ressource
  })
}

# ========================================
# ASSOCIATIONS TABLE DE ROUTAGE - SOUS-RÉSEAUX
# ========================================

# Associe chaque sous-réseau public à la table de routage publique
# Sans cette association, les sous-réseaux ne sauraient pas comment router le trafic
resource "aws_route_table_association" "public" {
  
  # ========================================
  # COUNT SYNCHRONISÉ AVEC LES SOUS-RÉSEAUX
  # ========================================
  
  # IMPORTANT : count = 2 doit correspondre au count des sous-réseaux
  # Crée une association pour chaque sous-réseau créé précédemment
  count = 2

  # ========================================
  # RÉFÉRENCE AUX RESSOURCES CRÉÉES PAR COUNT
  # ========================================
  
  # Référence les sous-réseaux créés précédemment avec count
  # aws_subnet.public[0] → Premier sous-réseau (count.index = 0)
  # aws_subnet.public[1] → Deuxième sous-réseau (count.index = 1)
  # La notation [count.index] permet de référencer la bonne instance
  subnet_id = aws_subnet.public[count.index].id
  
  # ID de la table de routage à associer
  route_table_id = aws_route_table.public.id
}

# ========================================
# GROUPE DE SÉCURITÉ POUR LES INSTANCES EC2
# ========================================

# Le Security Group agit comme un firewall virtuel pour contrôler le trafic
# Il définit quelles connexions sont autorisées (entrantes et sortantes)
resource "aws_security_group" "ec2_sg" {
  # Préfixe pour le nom du security group (AWS ajoutera un suffixe unique)
  name_prefix = "${var.project_name}-${var.environment}-"
  
  # Description pour documenter l'usage de ce security group
  description = "Security group for ${var.project_name} EC2 instance"
  
  # Associe ce security group à notre VPC
  vpc_id = aws_vpc.main.id

  # ========================================
  # RÈGLES D'ENTRÉE (INGRESS)
  # ========================================
  
  # IMPORTANT: Pas d'accès SSH (port 22)
  # Nous utilisons AWS Systems Manager Session Manager pour un accès sécurisé
  # Cela évite d'exposer le port SSH qui est souvent ciblé par les attaques

  # Règle 1: Accès HTTP (port 80)
  ingress {
    from_port   = 80      # Port de début (80 pour HTTP)
    to_port     = 80      # Port de fin (même port)
    protocol    = "tcp"   # Protocole TCP
    cidr_blocks = var.allowed_http_cidrs  # Adresses IP autorisées (depuis les variables)
    description = "HTTP access"  # Description de la règle
  }

  # Règle 2: Accès HTTPS (port 443) - CONDITIONNEL
  # Utilise un bloc "dynamic" pour créer cette règle seulement si HTTPS est activé
  dynamic "ingress" {
    # Si enable_https est true, crée 1 règle [1], sinon crée 0 règle []
    for_each = var.enable_https ? [1] : []
    
    content {
      from_port   = 443     # Port HTTPS
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_http_cidrs  # Mêmes IPs autorisées que HTTP
      description = "HTTPS access"
    }
  }

  # ========================================
  # RÈGLES DE SORTIE (EGRESS)
  # ========================================
  
  # Autorise TOUT le trafic sortant
  # Les instances peuvent communiquer avec n'importe quel service externe
  egress {
    from_port   = 0           # Port 0 = tous les ports
    to_port     = 0           # Port 0 = tous les ports
    protocol    = "-1"        # -1 = tous les protocoles (TCP, UDP, ICMP, etc.)
    cidr_blocks = ["0.0.0.0/0"]  # Toutes les destinations Internet
    description = "All outbound traffic"  # Description de la règle
  }

  # Tags pour identifier ce security group
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg"  # Nom unique
    Type = "SecurityGroup"  # Type de ressource
  })

  # ========================================
  # GESTION DU CYCLE DE VIE
  # ========================================
  
  # Crée le nouveau security group AVANT de supprimer l'ancien
  # Évite les interruptions de service lors des mises à jour
  lifecycle {
    create_before_destroy = true
  }
}
