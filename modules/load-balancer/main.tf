# modules/load-balancer/main.tf
# Module pour la gestion du Load Balancer et haute disponibilité
# Ce module crée un Application Load Balancer (ALB) qui distribue le trafic
# sur plusieurs instances pour améliorer les performances et la disponibilité

# ========================================
# SECURITY GROUP POUR L'APPLICATION LOAD BALANCER
# ========================================

# Security Group spécifique pour l'ALB - séparé de celui des instances EC2
# Cela permet un contrôle granulaire des flux réseau entre Internet, ALB et instances
resource "aws_security_group" "alb_sg" {
  # Préfixe pour le nom (AWS ajoute un suffixe unique)
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  
  # Description pour identifier facilement ce security group
  description = "Security group for Application Load Balancer"
  
  # VPC où déployer ce security group
  vpc_id = var.vpc_id

  # ========================================
  # RÈGLES D'ENTRÉE (TRAFIC DEPUIS INTERNET)
  # ========================================
  
  # Règle 1: Accès HTTP depuis Internet (port 80)
  # TOUJOURS activée - permet aux utilisateurs d'accéder à l'application
  ingress {
    from_port   = 80                # Port HTTP standard
    to_port     = 80
    protocol    = "tcp"             # Protocole TCP
    cidr_blocks = ["0.0.0.0/0"]    # Tout Internet peut accéder
    description = "HTTP access from internet"
  }

  # Règle 2: Accès HTTPS depuis Internet (port 443) - CONDITIONNEL
  # Créée seulement si enable_https est activé
  dynamic "ingress" {
    # Si enable_https=true, crée 1 règle [1], sinon 0 règle []
    for_each = var.enable_https ? [1] : []
    
    content {
      from_port   = 443             # Port HTTPS standard
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Tout Internet peut accéder
      description = "HTTPS access from internet"
    }
  }

  # ========================================
  # RÈGLES DE SORTIE (TRAFIC VERS LES INSTANCES)
  # ========================================
  
  # L'ALB doit pouvoir communiquer avec les instances backend sur le port 80
  # IMPORTANT: Trafic limité au VPC seulement (sécurité)
  egress {
    from_port   = 80              # Port où les instances écoutent
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # Seulement vers notre VPC (pas Internet)
    description = "HTTP traffic to instances"
  }

  # Tags pour identifier et organiser cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Type = "SecurityGroup"
  })

  # Crée le nouveau avant de supprimer l'ancien (zéro downtime)
  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# TARGET GROUP POUR LES INSTANCES WEB
# ========================================

# Un Target Group définit un groupe d'instances qui reçoivent le trafic de l'ALB
# Il gère l'enregistrement/désenregistrement automatique des instances
resource "aws_lb_target_group" "web" {
  # Préfixe pour le nom (AWS ajoute un suffixe unique)
  name_prefix = "web-"
  
  # Port sur lequel les instances écoutent (ici port 80 = HTTP)
  port = 80
  
  # Protocole utilisé pour communiquer avec les instances
  protocol = "HTTP"
  
  # VPC où se trouvent les instances cibles
  vpc_id = var.vpc_id

  # ========================================
  # CONFIGURATION DES HEALTH CHECKS
  # ========================================
  
  # Les health checks vérifient si les instances sont en bonne santé
  # Les instances malades sont automatiquement retirées du trafic
  health_check {
    enabled = true  # Active les vérifications de santé
    
    # Nombre de checks réussis pour considérer une instance saine
    healthy_threshold = 2
    
    # Nombre de checks échoués pour considérer une instance malade
    unhealthy_threshold = 3
    
    # Temps d'attente maximal pour chaque check (en secondes)
    timeout = 5
    
    # Intervalle entre chaque check (en secondes)
    interval = 30
    
    # Chemin URL à vérifier (ex: "/health", "/" pour la page d'accueil)
    path = var.health_check_path
    
    # Code de réponse HTTP attendu pour considérer l'instance saine
    matcher = "200"  # 200 = OK
    
    # Port à utiliser pour les checks ("traffic-port" = même port que le trafic)
    port = "traffic-port"
    
    # Protocole pour les health checks
    protocol = "HTTP"
  }

  # ========================================
  # CONFIGURATION DE DÉSENREGISTREMENT
  # ========================================
  
  # Délai d'attente avant de supprimer complètement une instance du target group
  # Permet aux connexions existantes de se terminer proprement
  deregistration_delay = 300  # 5 minutes

  # Tags pour identifier cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-tg"
    Type = "TargetGroup"
  })

  # Crée le nouveau avant de supprimer l'ancien
  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# APPLICATION LOAD BALANCER (ALB)
# ========================================

# L'ALB est le point d'entrée principal pour tout le trafic web
# Il distribue intelligemment les requêtes sur plusieurs instances
resource "aws_lb" "main" {
  # Nom unique de l'ALB
  name = "${var.project_name}-${var.environment}-alb"
  
  # false = Internet-facing (accessible depuis Internet)
  # true = Internal (accessible seulement depuis le VPC)
  internal = false
  
  # Type de load balancer:
  # - "application" = Layer 7 (HTTP/HTTPS) - le plus utilisé
  # - "network" = Layer 4 (TCP/UDP) - plus performant mais moins de fonctionnalités
  load_balancer_type = "application"
  
  # Security groups à attacher à l'ALB (contrôle le trafic entrant/sortant)
  security_groups = [aws_security_group.alb_sg.id]
  
  # Sous-réseaux où déployer l'ALB (MINIMUM 2 dans des AZ différentes)
  # Utilise nos sous-réseaux publics pour être accessible depuis Internet
  subnets = var.public_subnet_ids

  # ========================================
  # PROTECTION CONTRE LA SUPPRESSION ACCIDENTELLE
  # ========================================
  
  # Si activé, empêche la suppression accidentelle de l'ALB
  # Utile en production pour éviter les catastrophes
  enable_deletion_protection = var.enable_deletion_protection

  # Tags pour identifier et organiser cette ressource
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
    Type = "ApplicationLoadBalancer"
  })
}

# ========================================
# LISTENER HTTP (PORT 80)
# ========================================

# Un Listener définit comment l'ALB traite les requêtes sur un port spécifique
# Ce listener gère tout le trafic HTTP (port 80)
resource "aws_lb_listener" "web" {
  # ALB auquel attacher ce listener
  load_balancer_arn = aws_lb.main.arn
  
  # Port d'écoute (80 = HTTP standard)
  port = "80"
  
  # Protocole (HTTP pour ce listener)
  protocol = "HTTP"

  # ========================================
  # ACTION PAR DÉFAUT
  # ========================================
  
  # Définit que faire avec les requêtes reçues sur ce port
  default_action {
    # "forward" = transmettre les requêtes vers un target group
    # Autres options: "redirect", "fixed-response", etc.
    type = "forward"
    
    # Target group vers lequel transmettre les requêtes
    target_group_arn = aws_lb_target_group.web.arn
  }

  # Tags pour identifier ce listener
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-listener"
    Type = "Listener"
  })
}

# ========================================
# LISTENER HTTPS (PORT 443) - CONDITIONNEL
# ========================================

# Ce listener est créé seulement si HTTPS est activé (variable enable_https)
# Gère le trafic sécurisé avec chiffrement SSL/TLS
resource "aws_lb_listener" "web_https" {
  # Crée ce listener seulement si enable_https = true
  count = var.enable_https ? 1 : 0
  
  # ALB auquel attacher ce listener
  load_balancer_arn = aws_lb.main.arn
  
  # Port d'écoute (443 = HTTPS standard)
  port = "443"
  
  # Protocole HTTPS (chiffré)
  protocol = "HTTPS"
  
  # ========================================
  # CONFIGURATION SSL/TLS
  # ========================================
  
  # Politique de sécurité SSL (définit les versions TLS autorisées)
  # Cette politique supporte TLS 1.2+ (moderne et sécurisé)
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  
  # ARN du certificat SSL (doit être créé dans AWS Certificate Manager)
  # Nécessaire pour le chiffrement HTTPS
  certificate_arn = var.ssl_certificate_arn

  # ========================================
  # ACTION PAR DÉFAUT
  # ========================================
  
  # Même action que HTTP: transmettre vers le target group
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  # Tags pour identifier ce listener HTTPS
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-https-listener"
    Type = "Listener"
  })
}