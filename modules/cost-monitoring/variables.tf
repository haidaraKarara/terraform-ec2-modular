# ========================================================================================================
# VARIABLES DU MODULE COST MONITORING - SURVEILLANCE DES COÛTS AWS
# ========================================================================================================

# ========================================================================================================
# SECTION 1: VARIABLES OBLIGATOIRES
# ========================================================================================================

variable "project_name" {
  description = "Nom du projet - utilisé comme préfixe pour toutes les ressources de monitoring"
  type        = string
  
  validation {
    condition = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Le nom du projet doit contenir entre 3 et 30 caractères."
  }
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être 'dev', 'staging' ou 'prod'."
  }
}

# ========================================================================================================
# SECTION 2: CONFIGURATION DES BUDGETS
# ========================================================================================================

variable "budget_limit" {
  description = "Limite du budget mensuel principal en USD"
  type        = number
  default     = 100
  
  validation {
    condition = var.budget_limit > 0 && var.budget_limit <= 10000
    error_message = "La limite du budget doit être entre 1 et 10000 USD."
  }
}

variable "ec2_budget_limit" {
  description = "Limite du budget mensuel pour les instances EC2 en USD"
  type        = number
  default     = 50
  
  validation {
    condition = var.ec2_budget_limit > 0 && var.ec2_budget_limit <= 100
    error_message = "La limite du budget EC2 doit être entre 1 et 100 USD."
  }
}

# ========================================================================================================
# SECTION 3: CONFIGURATION DES ALERTES
# ========================================================================================================

variable "alert_emails" {
  description = "Liste des adresses email pour recevoir les alertes de coûts"
  type        = list(string)
  default     = []
  
  validation {
    condition = length(var.alert_emails) <= 10
    error_message = "Maximum 10 adresses email sont autorisées."
  }
  
  validation {
    condition = alltrue([
      for email in var.alert_emails : 
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "Toutes les adresses email doivent être valides."
  }
}

variable "cost_alert_threshold" {
  description = "Seuil d'alerte pour les coûts estimés en USD"
  type        = number
  default     = 80
  
  validation {
    condition = var.cost_alert_threshold > 0 && var.cost_alert_threshold <= 1000
    error_message = "Le seuil d'alerte doit être entre 1 et 1000 USD."
  }
}

# ========================================================================================================
# SECTION 4: CONFIGURATION DES RAPPORTS
# ========================================================================================================

variable "enable_detailed_billing" {
  description = "Activer les rapports détaillés de coûts et d'utilisation (Cost and Usage Report)"
  type        = bool
  default     = false
}

variable "report_retention_days" {
  description = "Nombre de jours de rétention des rapports de coûts"
  type        = number
  default     = 90
  
  validation {
    condition = var.report_retention_days >= 30 && var.report_retention_days <= 365
    error_message = "La rétention des rapports doit être entre 30 et 365 jours."
  }
}

# ========================================================================================================
# SECTION 5: TAGS ET MÉTADONNÉES
# ========================================================================================================

variable "common_tags" {
  description = "Tags communs appliqués à toutes les ressources de monitoring"
  type        = map(string)
  default     = {}
}