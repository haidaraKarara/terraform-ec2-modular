# 💰 Guide de Test de Coûts Terraform

Ce guide explique comment utiliser les outils de test de coûts intégrés dans ce projet Terraform.

## 🎯 Objectifs du Test de Coûts

- **Estimation préventive** : Connaître les coûts avant déploiement
- **Surveillance continue** : Alertes sur les dépassements de budget
- **Optimisation** : Identification des ressources coûteuses
- **Gouvernance** : Contrôle des dépenses par environnement

## 🛠️ Outils Intégrés

### 1. Infracost - Estimation des Coûts

**Installation d'Infracost :**
```bash
# macOS
brew install infracost

# Linux
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Windows
choco install infracost
```

**Configuration initiale :**
```bash
# Créer un compte gratuit et obtenir une clé API
infracost auth login

# Ou définir la clé API manuellement
export INFRACOST_API_KEY=your_api_key_here
```

### 2. Script de Test de Coûts

**Utilisation du script :**
```bash
# Estimer les coûts dev
./scripts/cost-estimation.sh dev

# Estimer les coûts prod
./scripts/cost-estimation.sh prod

# Estimer tous les environnements
./scripts/cost-estimation.sh all
```

**Exemple de sortie :**
```
[INFO] Estimation des coûts pour l'environnement: dev
[INFO] Résumé des coûts pour dev:

Project: terraform-ec2-modular-dev

 Name                                    Monthly Qty  Unit         Monthly Cost

 module.compute.aws_instance.main[0]                                     $8.76
 ├─ Instance usage (Linux/UNIX, on-demand, t2.micro)    730  hours            $8.76
 └─ root_block_device
    └─ General Purpose SSD (gp3)                          8  GB               $0.77

 module.load_balancer.aws_lb.main                                       $18.40
 ├─ Application load balancer                             1  months          $18.40
 └─ Load balancer capacity units                          1  LCU-hours        $0.00

 OVERALL TOTAL                                                          $27.93
```

### 3. Intégration CI/CD

Le workflow GitHub Actions `.github/workflows/cost-estimation.yml` :
- Se déclenche sur les PR vers `main`
- Estime les coûts pour dev et prod
- Commente les PR avec les estimations
- Vérifie les seuils de coûts

**Variables d'environnement requises :**
```yaml
# Dans GitHub Secrets
INFRACOST_API_KEY: your_infracost_api_key
AWS_ACCESS_KEY_ID: your_aws_access_key
AWS_SECRET_ACCESS_KEY: your_aws_secret_key
```

## 📊 Module de Surveillance des Coûts

### Configuration du Module

Ajoutez le module dans vos environnements :

```hcl
module "cost_monitoring" {
  source = "../../modules/cost-monitoring"
  
  project_name     = var.project_name
  environment      = var.environment
  budget_limit     = 100  # Budget mensuel en USD
  ec2_budget_limit = 50   # Budget EC2 en USD
  alert_emails     = ["admin@company.com"]
  
  # Seuils d'alerte
  cost_alert_threshold = 80
  
  # Rapports détaillés (optionnel)
  enable_detailed_billing = true
  
  common_tags = var.common_tags
}
```

### Fonctionnalités du Module

**Budgets AWS :**
- Budget principal par environnement
- Budget spécifique pour EC2
- Alertes à 60% et 80% du budget

**Alertes CloudWatch :**
- Surveillance des coûts estimés
- Notifications SNS par email
- Métriques personnalisées

**Rapports de Coûts :**
- Bucket S3 pour stockage des rapports
- Cost and Usage Reports (optionnel)
- Rétention automatique des données

**Dashboard CloudWatch :**
- Visualisation des coûts en temps réel
- Métriques EC2 et facturation
- Graphiques personnalisables

## 🔧 Configuration des Seuils

### Seuils par Environnement

```bash
# Environnement dev
DEV_BUDGET_LIMIT=50        # Budget mensuel dev
DEV_ALERT_THRESHOLD=40     # Alerte à 40 USD

# Environnement prod
PROD_BUDGET_LIMIT=500      # Budget mensuel prod
PROD_ALERT_THRESHOLD=400   # Alerte à 400 USD
```

### Personnalisation des Alertes

**Modifier les seuils dans le script :**
```bash
# Dans scripts/cost-estimation.sh
if [[ "${env}" == "prod" ]]; then
    threshold=500 # Seuil prod
else
    threshold=100 # Seuil dev
fi
```

**Ajouter des destinataires d'alertes :**
```hcl
alert_emails = [
  "team-lead@company.com",
  "finance@company.com",
  "devops@company.com"
]
```

## 📈 Interprétation des Résultats

### Métriques Importantes

**Coût Total Mensuel :**
- Estimation basée sur 730 heures/mois
- Inclut tous les services AWS utilisés
- Affiché en USD

**Coût par Ressource :**
- Instances EC2 : Type, taille, région
- Load Balancers : Nombre de LCU
- Stockage EBS : Type et taille
- Bande passante : Transfert de données

### Optimisations Recommandées

**Instances EC2 :**
- Utiliser `t3.micro` au lieu de `t2.micro` (plus récent)
- Configurer Auto Scaling pour ajuster la capacité
- Utiliser des instances Spot pour dev/test

**Stockage :**
- Préférer `gp3` à `gp2` (plus économique)
- Dimensionner correctement les volumes
- Supprimer les snapshots inutiles

**Load Balancers :**
- Utiliser Application Load Balancer (ALB) 
- Configurer la terminaison SSL au load balancer
- Optimiser les health checks

## 🚨 Gestion des Alertes

### Types d'Alertes

**Alertes de Budget :**
- 60% du budget : Alerte préventive
- 80% du budget : Alerte critique
- 100% du budget : Alerte dépassement

**Alertes CloudWatch :**
- Coûts estimés dépassant le seuil
- Utilisation anormale des ressources
- Pics de trafic réseau

### Actions Recommandées

**En cas d'alerte :**
1. Vérifier les métriques dans CloudWatch
2. Identifier les ressources coûteuses
3. Analyser les patterns d'utilisation
4. Ajuster la configuration si nécessaire

**Escalade :**
- Alerte dev : Équipe technique
- Alerte prod : Équipe + Management
- Dépassement critique : Finance + Direction

## 📋 Checklist de Déploiement

**Avant le déploiement :**
- [ ] Installer Infracost
- [ ] Configurer la clé API
- [ ] Exécuter l'estimation des coûts
- [ ] Vérifier les seuils de budget
- [ ] Configurer les alertes email

**Après le déploiement :**
- [ ] Vérifier les budgets AWS
- [ ] Tester les alertes SNS
- [ ] Consulter le dashboard CloudWatch
- [ ] Valider les rapports de coûts
- [ ] Documenter les coûts de référence

## 🔍 Dépannage

### Problèmes Courants

**Infracost ne fonctionne pas :**
```bash
# Vérifier l'installation
infracost --version

# Vérifier la clé API
infracost configure get api_key

# Réinitialiser la configuration
infracost configure set api_key YOUR_API_KEY
```

**Terraform non initialisé :**
```bash
cd environments/dev
terraform init
```

**Alertes email non reçues :**
- Vérifier les souscriptions SNS
- Confirmer les adresses email
- Vérifier les spams

### Logs et Diagnostic

**Logs CloudWatch :**
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/cost/"
```

**État des budgets :**
```bash
aws budgets describe-budgets --account-id YOUR_ACCOUNT_ID
```

## 📚 Ressources Utiles

- [Documentation Infracost](https://www.infracost.io/docs/)
- [AWS Budgets Guide](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [CloudWatch Billing Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html)
- [Cost Optimization Best Practices](https://docs.aws.amazon.com/whitepapers/latest/cost-optimization-right-sizing/cost-optimization-right-sizing.html)