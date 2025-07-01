# modules/networking/main.tf
# Module pour la gestion du réseau et sécurité
# Ce module crée l'infrastructure réseau complète pour notre application

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
  # Crée 2 sous-réseaux (count = 2)
  count = 2

  # Associe chaque sous-réseau à notre VPC
  vpc_id = aws_vpc.main.id
  
  # Calcule automatiquement le CIDR de chaque sous-réseau
  # Subnet 1: 10.0.1.0/24 (256 IPs), Subnet 2: 10.0.2.0/24 (256 IPs)
  cidr_block = "10.0.${count.index + 1}.0/24"
  
  # Place chaque sous-réseau dans une zone de disponibilité différente
  # Améliore la résilience en cas de panne d'une zone
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  # NE PAS attribuer d'IP publique automatiquement aux instances
  # Sécurité renforcée : les instances n'auront pas d'accès direct à Internet
  map_public_ip_on_launch = false

  # Tags pour identifier chaque sous-réseau
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"  # Nom unique
    Type = "PublicSubnet"  # Type de sous-réseau
    AZ   = data.aws_availability_zones.available.names[count.index]  # Zone de disponibilité
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
  # Crée une association pour chaque sous-réseau (2 associations)
  count = 2

  # ID du sous-réseau à associer (utilise l'index pour parcourir les 2 sous-réseaux)
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
