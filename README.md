# Terraform EC2 Modular Project

Infrastructure modulaire pour déployer des instances EC2 sur AWS avec une séparation complète des environnements.

## Démarrage rapide

**Pour les impatients qui veulent déployer rapidement :**

```bash
# 1. Bootstrap (créer les backends S3/DynamoDB)
cd bootstrap/dev
terraform init && terraform apply

# 2. Déployer l'environnement dev
cd ../../environments/dev
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars si nécessaire
terraform init && terraform apply

# 3. Accéder à votre application
terraform output alb_url
# Ouvrir l'URL dans votre navigateur !
```

**Résultat :** Une application web complète avec Load Balancer, Auto Scaling et accès sécurisé !

> 📝 **Note :** L'application déployée est un serveur web Apache avec une page d'accueil personnalisée qui affiche les informations de l'instance (ID, AZ, IP, etc.). Parfait pour tester le Load Balancer et l'Auto Scaling !

---

## 📋 Table des matières

1. [Démarrage rapide](#-démarrage-rapide)
2. [Architecture du projet](#-architecture-du-projet)
3. [Prérequis](#-prérequis)
4. [Configuration initiale](#-configuration-initiale)
5. [Déploiement](#-déploiement)
6. [Architecture et Fonctionnalités](#-architecture-et-fonctionnalités)
7. [Gestion des environnements](#-gestion-des-environnements)
8. [Sécurité](#-sécurité)
9. [Maintenance](#-maintenance)

## Architecture du projet

```
terraform-ec2-modular/
├── bootstrap/                  # Configuration des backends S3/DynamoDB
│   ├── dev/                   # Bootstrap environnement dev
│   │   ├── main.tf           # Ressources backend dev
│   │   ├── versions.tf       # Versions pour dev
│   │   └── outputs.tf        # Outputs dev
│   └── prod/                  # Bootstrap environnement prod
│       ├── main.tf           # Ressources backend prod
│       ├── versions.tf       # Versions pour prod
│       └── outputs.tf        # Outputs prod
├── environments/
│   ├── dev/                   # Configuration environnement développement
│   │   ├── main.tf           # Appel des modules
│   │   ├── variables.tf      # Variables spécifiques dev
│   │   ├── backend.tf        # Backend S3 dev
│   │   ├── versions.tf       # Versions pour dev
│   │   ├── outputs.tf        # Outputs dev
│   │   └── terraform.tfvars.example
│   └── prod/                  # Configuration environnement production
│       ├── main.tf           # Appel des modules
│       ├── variables.tf      # Variables spécifiques prod
│       ├── backend.tf        # Backend S3 prod
│       ├── versions.tf       # Versions pour prod
│       ├── outputs.tf        # Outputs prod
│       └── terraform.tfvars.example
└── modules/
    ├── compute/               # Module instances EC2 et Auto Scaling
    ├── load-balancer/         # Module Application Load Balancer
    └── networking/            # Module réseau et sécurité
```

## 📋 Prérequis

- [Terraform](https://terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configuré
- Accès AWS avec permissions appropriées
- AWS Systems Manager Session Manager plugin installé

## ⚙️ Configuration initiale

### 1. Initialisation des backends

**⚠️ ÉTAPE OBLIGATOIRE - À faire en premier**

Cette étape crée les buckets S3 et tables DynamoDB nécessaires pour stocker les états Terraform.

**Option 1: Bootstrap dev uniquement**
```bash
# Créer seulement les ressources dev
cd bootstrap/dev
terraform init
terraform apply
```

**Option 2: Bootstrap prod uniquement**
```bash
# Créer seulement les ressources prod  
cd bootstrap/prod
terraform init
terraform apply
```

**Option 3: Bootstrap les deux environnements**
```bash
# Créer dev
cd bootstrap/dev
terraform init && terraform apply

# Créer prod
cd ../prod  
terraform init && terraform apply
```

**Ressources créées :**
- **Dev** : `terraform-modular-tfstate-dev` (S3) + `terraform-modular-lock-dev` (DynamoDB)
- **Prod** : `terraform-modular-tfstate-prod` (S3) + `terraform-modular-lock-prod` (DynamoDB)

### 2. Installation Session Manager Plugin

**macOS (Apple Silicon) :**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

**macOS (Intel) :**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

**Linux :**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo rpm -i session-manager-plugin.rpm
```

**Vérification :**
```bash
session-manager-plugin
```

## Déploiement

### Environnement de développement

```bash
# 1. Aller dans le dossier dev
cd environments/dev

# 2. Copier et configurer les variables
cp terraform.tfvars.example terraform.tfvars

# 3. Éditer le fichier terraform.tfvars
nano terraform.tfvars  # ou votre éditeur préféré
```

**Variables à configurer dans `terraform.tfvars` :**
```hcl
# Votre région AWS
aws_region = "us-east-1"

# IPs autorisées pour l'accès HTTP au load balancer
allowed_http_cidrs = ["0.0.0.0/0"]

# Configuration du load balancer
enable_https = false
health_check_path = "/"

# Configuration Auto Scaling (Haute Disponibilité)
enable_auto_scaling = true
asg_min_size = 2                  # Minimum 2 instances pour HA
asg_max_size = 3                  # Maximum 3 instances
asg_desired_capacity = 2          # 2 instances actives (multi-AZ)

# Tags personnalisés
common_tags = {
  Terraform   = "true"
  Project     = "terraform-modular"
  Environment = "dev"
  Owner       = "VOTRE_NOM"
}
```

```bash
# 4. Initialiser Terraform (connexion au backend S3)
terraform init

# 5. Vérifier le plan de déploiement
terraform plan

# 6. Déployer l'infrastructure
terraform apply
```

### Environnement de production

```bash
# 1. Aller dans le dossier prod
cd environments/prod

# 2. Copier et configurer les variables
cp terraform.tfvars.example terraform.tfvars

# 3. Éditer le fichier terraform.tfvars
nano terraform.tfvars
```

**Variables à configurer dans `terraform.tfvars` :**
```hcl
# Configuration production
aws_region = "us-east-1"
instance_type = "t2.micro"  # Même type qu'en dev

# Configuration du load balancer
allowed_http_cidrs = ["0.0.0.0/0"]
enable_https = true
health_check_path = "/"  # Même path qu'en dev

# Configuration Auto Scaling pour la prod
enable_auto_scaling = true
asg_min_size = 2
asg_max_size = 4
asg_desired_capacity = 2

# IP élastique uniquement pour les instances standalone
create_eip = false  # Pas d'EIP en mode Auto Scaling

# Tags production
common_tags = {
  Terraform   = "true"
  Project     = "terraform-modular"
  Environment = "prod"
  Owner       = "VOTRE_NOM"
  CostCenter  = "VOTRE_CENTRE_DE_COUT"
}
```

```bash
# 4. Initialiser et déployer
terraform init
terraform plan
terraform apply
```

## Architecture et Fonctionnalités

### Architecture 3-tiers moderne

**1. Couche Réseau (Module Networking) :**
- **VPC isolé** : Réseau privé virtuel sécurisé
- **Multi-AZ** : Sous-réseaux dans 2 zones de disponibilité
- **Security Groups** : Firewall avec règles strictes
- **Accès Internet** : Via Internet Gateway contrôlé

**2. Couche Load Balancer (Module Load Balancer) :**
- **Point d'entrée unique** : Application Load Balancer public
- **Health Checks** : Vérification automatique de la santé des instances
- **SSL/TLS** : Support HTTPS avec certificats (optionnel)
- **Haute disponibilité** : Distribution multi-AZ automatique

**3. Couche Compute (Module Compute) :**
- **Auto Scaling Group** : Gestion automatique des instances
- **Launch Templates** : Configuration standardisée des instances
- **Rolling Updates** : Mise à jour sans interruption de service
- **Session Manager** : Accès sécurisé sans SSH

### 🎯 Architecture unifiée Dev/Prod

**Similitudes (même architecture) :**
- Load Balancer + Auto Scaling Group
- Session Manager pour l'accès sécurisé
- Multi-AZ pour la résilience
- Health checks et monitoring

**Différences (paramètres uniquement) :**
- **Instances** : 2-3 en dev, 2-4 en prod
- **HTTPS** : désactivé en dev, activé en prod  
- **Tags** : Environment = "dev" vs "prod"

**Avantages :**
- Tests représentatifs en dev
- Déploiements prévisibles en prod
- Architecture éprouvée et cohérente

## 🔄 Gestion des environnements

### Isolation complète

- **États séparés** : Chaque environnement a son propre backend S3
- **Ressources distinctes** : Aucun partage entre dev et prod
- **Architecture identique** : Dev et prod utilisent la même structure Load Balancer + Auto Scaling
- **Évolutions** : Possibilité de tester en dev avant prod avec la même architecture

### Commandes utiles

```bash
# Voir l'état des ressources
terraform show

# Lister les ressources
terraform state list

# Voir les outputs
terraform output

# 🌐 ACCÉDER À L'APPLICATION
terraform output alb_url

# 📋 Obtenir les IDs des instances actuelles (Auto Scaling)
terraform output get_instance_ids_command

# 🔗 Commande de connexion aux instances
terraform output ssm_session_command

# Détruire l'environnement (ATTENTION !)
terraform destroy
```

### Mise à jour des environnements

```bash
# 1. Toujours tester en dev d'abord
cd environments/dev
terraform plan
terraform apply

# 2. Puis appliquer en prod
cd ../prod  
terraform plan
terraform apply
```

## 🔒 Sécurité

### Bonnes pratiques mises en place

- ✅ **Accès SSM uniquement** : Pas de clés SSH, accès via AWS Systems Manager
- ✅ **États chiffrés** : Backends S3 avec chiffrement AES256
- ✅ **Verrouillage** : Tables DynamoDB pour éviter les conflits
- ✅ **Variables sensibles** : Fichiers `.tfvars` exclus du git
- ✅ **Load Balancer sécurisé** : Point d'entrée unique avec health checks
- ✅ **Auto Scaling** : Haute disponibilité et résilience automatique
- ✅ **Environnements isolés** : Backends séparés par environnement
- ✅ **Architecture identique** : Dev et prod utilisent la même structure

### Configuration des accès SSM (Systems Manager)

Ce projet utilise **AWS Systems Manager Session Manager** pour un accès sécurisé sans SSH.

#### Installation du plugin Session Manager

```bash
# Télécharger et installer le plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin

# Vérifier l'installation
session-manager-plugin
```

#### Utilisation

**Connexion aux instances (Auto Scaling Group) :**

```bash
# 1. Obtenir les IDs des instances actuelles
terraform output get_instance_ids_command
# Copier et exécuter la commande affichée

# 2. Se connecter à une instance spécifique
aws ssm start-session --target <INSTANCE_ID> --region us-east-1

# 3. Ou utiliser la commande générée par Terraform
terraform output ssm_session_command
```

#### Utilisation avancée (commandes à distance)

```bash
# Exécuter des commandes sans session interactive
aws ssm send-command --instance-ids <INSTANCE_ID> --document-name "AWS-RunShellScript" --parameters 'commands=["echo Hello","whoami"]' --region us-east-1

# Copier des fichiers (via S3)
aws ssm send-command --instance-ids <INSTANCE_ID> --document-name "AWS-RunShellScript" --parameters 'commands=["aws s3 cp s3://mon-bucket/fichier.txt /tmp/"]'
```

**Avantages de SSM :**
- ✅ **Aucune clé SSH à gérer** - Utilise vos identifiants AWS
- ✅ **Aucune restriction d'IP** - Fonctionne depuis n'importe où
- ✅ **Sécurité renforcée** - Pas de port 22 ouvert
- ✅ **Journalisation complète** - Tous les accès sont tracés
- ✅ **Terminal interactif** - Comme SSH mais plus sécurisé

### Gestion des permissions AWS

Assurez-vous que votre utilisateur AWS dispose des permissions suivantes :
- **EC2** : instances, security groups, launch templates, auto scaling groups
- **VPC** : subnets, internet gateways, route tables
- **ELB** : load balancers, target groups, listeners
- **S3** : création et gestion des buckets (pour backend Terraform)
- **DynamoDB** : création et gestion des tables (pour state locking)
- **IAM** : rôles et policies pour Session Manager

## 🔧 Maintenance

### Sauvegarde des états

Les états Terraform sont automatiquement sauvegardés dans S3 avec versioning activé.

### Surveillance des coûts

Utilisez les tags appliqués automatiquement pour suivre les coûts par :
- Projet (`Project = terraform-modular`)
- Environnement (`Environment = dev/prod`)
- Propriétaire (`Owner = VOTRE_NOM`)

### Mise à jour des modules

```bash
# Mettre à jour les providers
terraform init -upgrade

# Vérifier les changements
terraform plan

# Appliquer les mises à jour
terraform apply
```

### Nettoyage

```bash
# Supprimer un environnement
cd environments/dev  # ou prod
terraform destroy

# Supprimer les backends (DERNIÈRE ÉTAPE)
cd ../../bootstrap/dev
terraform destroy

# Ou pour prod
cd ../prod
terraform destroy
```

---

## 📞 Support

Pour toute question ou problème :
1. Vérifiez les logs Terraform
2. Consultez la documentation AWS
3. Vérifiez vos permissions AWS
4. Assurez-vous que les backends sont créés (étape bootstrap)