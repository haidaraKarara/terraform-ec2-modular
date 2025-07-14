# ========================================================================================================
# OUTPUTS DU MODULE COST MONITORING - INFORMATIONS DE SURVEILLANCE DES COÛTS
# ========================================================================================================

# ========================================================================================================
# SECTION 1: INFORMATIONS DES BUDGETS
# ========================================================================================================

output "main_budget_id" {
  description = "ID du budget principal"
  value       = aws_budgets_budget.main_budget.id
}

output "main_budget_arn" {
  description = "ARN du budget principal"
  value       = aws_budgets_budget.main_budget.arn
}

output "ec2_budget_id" {
  description = "ID du budget EC2"
  value       = aws_budgets_budget.ec2_budget.id
}

output "ec2_budget_arn" {
  description = "ARN du budget EC2"
  value       = aws_budgets_budget.ec2_budget.arn
}

# ========================================================================================================
# SECTION 2: INFORMATIONS DES ALERTES
# ========================================================================================================

output "cost_alarm_name" {
  description = "Nom de l'alarme de coûts CloudWatch"
  value       = aws_cloudwatch_metric_alarm.high_cost_alarm.alarm_name
}

output "cost_alarm_arn" {
  description = "ARN de l'alarme de coûts CloudWatch"
  value       = aws_cloudwatch_metric_alarm.high_cost_alarm.arn
}

output "sns_topic_arn" {
  description = "ARN du topic SNS pour les alertes de coûts"
  value       = aws_sns_topic.cost_alerts.arn
}

output "sns_topic_name" {
  description = "Nom du topic SNS pour les alertes de coûts"
  value       = aws_sns_topic.cost_alerts.name
}

# ========================================================================================================
# SECTION 3: INFORMATIONS DES RAPPORTS
# ========================================================================================================

output "cost_reports_bucket_name" {
  description = "Nom du bucket S3 pour les rapports de coûts"
  value       = aws_s3_bucket.cost_reports.bucket
}

output "cost_reports_bucket_arn" {
  description = "ARN du bucket S3 pour les rapports de coûts"
  value       = aws_s3_bucket.cost_reports.arn
}

output "cost_reports_bucket_domain_name" {
  description = "Nom de domaine du bucket S3 pour les rapports de coûts"
  value       = aws_s3_bucket.cost_reports.bucket_domain_name
}

output "cost_usage_report_name" {
  description = "Nom du rapport de coûts et d'utilisation (si activé)"
  value       = var.enable_detailed_billing ? aws_cur_report_definition.cost_usage_report[0].report_name : null
}

# ========================================================================================================
# SECTION 4: INFORMATIONS DU DASHBOARD
# ========================================================================================================

output "dashboard_name" {
  description = "Nom du dashboard CloudWatch de surveillance des coûts"
  value       = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
}

output "dashboard_url" {
  description = "URL du dashboard CloudWatch de surveillance des coûts"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
}

# ========================================================================================================
# SECTION 5: INFORMATIONS DE CONFIGURATION
# ========================================================================================================

output "budget_limits" {
  description = "Limites des budgets configurés"
  value = {
    main_budget = var.budget_limit
    ec2_budget  = var.ec2_budget_limit
  }
}

output "alert_configuration" {
  description = "Configuration des alertes"
  value = {
    email_count       = length(var.alert_emails)
    cost_threshold    = var.cost_alert_threshold
    emails_configured = length(var.alert_emails) > 0
  }
  sensitive = false
}

output "monitoring_summary" {
  description = "Résumé de la configuration de surveillance des coûts"
  value = {
    project_name            = var.project_name
    environment            = var.environment
    main_budget_limit      = var.budget_limit
    ec2_budget_limit       = var.ec2_budget_limit
    cost_alert_threshold   = var.cost_alert_threshold
    detailed_billing_enabled = var.enable_detailed_billing
    dashboard_name         = aws_cloudwatch_dashboard.cost_monitoring.dashboard_name
  }
}