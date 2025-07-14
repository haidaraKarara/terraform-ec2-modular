# ========================================================================================================
# MODULE DE SURVEILLANCE DES COÛTS AWS - CONFIGURATION COMPLÈTE
# ========================================================================================================
#
# Ce module crée des ressources AWS pour surveiller et alerter sur les coûts :
# - Budgets AWS pour contrôler les dépenses
# - Alertes CloudWatch pour les dépassements
# - Tags de facturation pour le suivi des coûts
# - Rapports de coûts et d'utilisation
#
# Utilisation:
# module "cost_monitoring" {
#   source = "./modules/cost-monitoring"
#   
#   project_name     = var.project_name
#   environment      = var.environment
#   budget_limit     = 100
#   alert_emails     = ["admin@company.com"]
#   common_tags      = var.common_tags
# }
# ========================================================================================================

# ========================================================================================================
# SECTION 1: BUDGETS AWS - CONTRÔLE DES DÉPENSES
# ========================================================================================================

# Budget principal pour l'environnement
resource "aws_budgets_budget" "main_budget" {
  name         = "${var.project_name}-${var.environment}-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  time_period_end   = "2087-06-15_00:00"
  
  # Filtrer par environnement
  cost_filter {
    name   = "TagKeyValue"
    values = ["Environment$${var.environment}"]
  }
  
  # Alertes par email
  dynamic "notification" {
    for_each = var.alert_emails
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                 = 80
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_email_addresses = [notification.value]
    }
  }
  
  # Alerte préventive à 60%
  dynamic "notification" {
    for_each = var.alert_emails
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                 = 60
      threshold_type            = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [notification.value]
    }
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-budget"
    Type = "CostMonitoring"
  })
}

# Budget pour les instances EC2 spécifiquement
resource "aws_budgets_budget" "ec2_budget" {
  name         = "${var.project_name}-${var.environment}-ec2-budget"
  budget_type  = "COST"
  limit_amount = var.ec2_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  time_period_end   = "2087-06-15_00:00"
  
  # Filtrer par service EC2 et environnement
  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }
  
  cost_filter {
    name   = "TagKeyValue"
    values = ["Environment$${var.environment}"]
  }
  
  # Alertes EC2
  dynamic "notification" {
    for_each = var.alert_emails
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                 = 90
      threshold_type            = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [notification.value]
    }
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-budget"
    Type = "CostMonitoring"
    Service = "EC2"
  })
}

# ========================================================================================================
# SECTION 2: ALERTES CLOUDWATCH - SURVEILLANCE EN TEMPS RÉEL
# ========================================================================================================

# Groupe de logs pour les alertes de coûts
resource "aws_cloudwatch_log_group" "cost_alerts" {
  name              = "/aws/cost/${var.project_name}-${var.environment}"
  retention_in_days = 30
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cost-logs"
    Type = "CostMonitoring"
  })
}

# Métrique personnalisée pour le suivi des coûts
resource "aws_cloudwatch_metric_alarm" "high_cost_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 heures
  statistic           = "Maximum"
  threshold           = var.cost_alert_threshold
  alarm_description   = "This metric monitors AWS estimated charges for ${var.environment} environment"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]
  
  dimensions = {
    Currency = "USD"
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cost-alarm"
    Type = "CostMonitoring"
  })
}

# ========================================================================================================
# SECTION 3: NOTIFICATIONS SNS - SYSTÈME D'ALERTE
# ========================================================================================================

# Topic SNS pour les alertes de coûts
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-${var.environment}-cost-alerts"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cost-alerts"
    Type = "CostMonitoring"
  })
}

# Politique SNS pour permettre les publications
resource "aws_sns_topic_policy" "cost_alerts_policy" {
  arn = aws_sns_topic.cost_alerts.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })
}

# Souscriptions email pour les alertes
resource "aws_sns_topic_subscription" "cost_email_alerts" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# ========================================================================================================
# SECTION 4: RAPPORTS DE COÛTS - ANALYSE ET SUIVI
# ========================================================================================================

# Bucket S3 pour stocker les rapports de coûts
resource "aws_s3_bucket" "cost_reports" {
  bucket = "${var.project_name}-${var.environment}-cost-reports-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cost-reports"
    Type = "CostMonitoring"
  })
}

# ID aléatoire pour le nom unique du bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Configuration du versioning
resource "aws_s3_bucket_versioning" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Chiffrement du bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquer l'accès public
resource "aws_s3_bucket_public_access_block" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Politique de cycle de vie
resource "aws_s3_bucket_lifecycle_configuration" "cost_reports" {
  bucket = aws_s3_bucket.cost_reports.id
  
  rule {
    id     = "cost_reports_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = ""
    }
    
    expiration {
      days = 365  # Supprimer après 1 an
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ========================================================================================================
# SECTION 5: CONFIGURATION COST AND USAGE REPORT
# ========================================================================================================

# Rapport de coûts et d'utilisation détaillé
resource "aws_cur_report_definition" "cost_usage_report" {
  count = var.enable_detailed_billing ? 1 : 0
  
  report_name                = "${var.project_name}-${var.environment}-cost-usage-report"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "GZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = aws_s3_bucket.cost_reports.bucket
  s3_prefix                  = "cost-usage-reports/"
  s3_region                  = data.aws_region.current.name
  
  additional_artifacts = [
    "REDSHIFT",
    "QUICKSIGHT",
    "ATHENA"
  ]
  
  refresh_closed_reports = true
  report_versioning      = "OVERWRITE_REPORT"
}

# Données de la région actuelle
data "aws_region" "current" {}

# ========================================================================================================
# SECTION 6: DASHBOARD CLOUDWATCH - VISUALISATION
# ========================================================================================================

# Dashboard CloudWatch pour la surveillance des coûts
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-cost-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Estimated AWS Charges"
          period  = 86400
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", "*"],
            ["AWS/EC2", "NetworkOut", "InstanceId", "*"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Network Usage"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
  
}