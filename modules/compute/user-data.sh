#!/bin/bash
# ========================================================================================================
# SCRIPT USER DATA - INITIALISATION AUTOMATIQUE DES INSTANCES EC2
# ========================================================================================================
#
# CE SCRIPT S'EXÉCUTE AUTOMATIQUEMENT AU PREMIER DÉMARRAGE DE CHAQUE INSTANCE EC2
#
# QUAND EST-IL EXÉCUTÉ ?
# - Une seule fois, au tout premier démarrage de l'instance
# - Exécuté avec les privilèges root (administrateur)
# - Les logs sont disponibles dans /var/log/cloud-init-output.log
#
# OBJECTIFS DE CE SCRIPT :
# 1. Mettre à jour le système d'exploitation
# 2. Installer et configurer Apache (serveur web)
# 3. Installer des outils de développement et de monitoring
# 4. Configurer AWS Systems Manager Agent pour l'accès sécurisé
# 5. Créer une page web personnalisée avec les informations de l'instance
#
# VARIABLES TERRAFORM INJECTÉES :
# - ${project_name} : Nom du projet (ex: "webapp")
# - ${environment} : Environnement (ex: "dev", "prod")
# ========================================================================================================

# ========================================================================================================
# SECTION 1 : MISE À JOUR DU SYSTÈME D'EXPLOITATION
# ========================================================================================================

# MISE À JOUR DE TOUS LES PACKAGES INSTALLÉS
# -y : Répondre automatiquement "oui" à toutes les questions
# POURQUOI IMPORTANT ? Pour avoir les dernières corrections de sécurité
echo "$(date): Début de la mise à jour du système..." >> /var/log/user-data.log
yum update -y
echo "$(date): Mise à jour du système terminée" >> /var/log/user-data.log

# ========================================================================================================
# SECTION 2 : INSTALLATION ET CONFIGURATION DU SERVEUR WEB APACHE
# ========================================================================================================

# INSTALLATION D'APACHE HTTP SERVER
# httpd est le nom du package Apache sur Amazon Linux
echo "$(date): Installation d'Apache..." >> /var/log/user-data.log
yum install -y httpd

# DÉMARRAGE IMMÉDIAT D'APACHE
# systemctl start : Démarrer le service maintenant
echo "$(date): Démarrage d'Apache..." >> /var/log/user-data.log
systemctl start httpd

# ACTIVATION D'APACHE AU DÉMARRAGE
# systemctl enable : Démarrer automatiquement Apache à chaque redémarrage
# POURQUOI ? Pour que le service web soit toujours disponible après un redémarrage
systemctl enable httpd
echo "$(date): Apache configuré pour démarrer automatiquement" >> /var/log/user-data.log

# ========================================================================================================
# SECTION 3 : INSTALLATION D'OUTILS DE DÉVELOPPEMENT ET DE MONITORING
# ========================================================================================================

# INSTALLATION D'OUTILS UTILES POUR LE DÉVELOPPEMENT ET LA MAINTENANCE
echo "$(date): Installation des outils de développement..." >> /var/log/user-data.log
yum install -y \
    git \        # Système de contrôle de version
    htop \       # Monitoring des processus et des ressources système
    wget \       # Téléchargement de fichiers via HTTP/HTTPS
    curl \       # Client HTTP en ligne de commande
    tree \       # Affichage de l'arborescence des dossiers
    nano         # Éditeur de texte simple
echo "$(date): Outils de développement installés" >> /var/log/user-data.log

# ========================================================================================================
# SECTION 4 : CONFIGURATION D'AWS SYSTEMS MANAGER AGENT
# ========================================================================================================

# INSTALLATION D'AWS SYSTEMS MANAGER AGENT
# SSM Agent permet la connexion sécurisée sans SSH
# AVANTAGE : Pas besoin d'ouvrir le port 22 ou de gérer des clés SSH
echo "$(date): Installation et configuration de SSM Agent..." >> /var/log/user-data.log
yum install -y amazon-ssm-agent

# ACTIVATION AU DÉMARRAGE
# Pour que l'agent SSM soit toujours disponible après un redémarrage
systemctl enable amazon-ssm-agent

# DÉMARRAGE IMMÉDIAT
systemctl start amazon-ssm-agent

# VÉRIFICATION DU STATUT ET JOURNALISATION
# Enregistre le statut dans les logs pour diagnostic
echo "$(date): Vérification du statut SSM Agent..." >> /var/log/user-data.log
systemctl status amazon-ssm-agent >> /var/log/user-data.log 2>&1

# ========================================================================================================
# SECTION 5 : CRÉATION D'UNE PAGE WEB PERSONNALISÉE ET INFORMATIVE
# ========================================================================================================

# CRÉATION DU FICHIER INDEX.HTML AVEC INFORMATIONS DYNAMIQUES
# Cette page web affichera des informations utiles sur l'instance déployée
# EMPLACEMENT : /var/www/html/index.html (répertoire par défaut d'Apache)
echo "$(date): Création de la page web personnalisée..." >> /var/log/user-data.log

cat > /var/www/html/index.html << 'HTML_END'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project_name} - ${environment}</title>
    
    <!-- STYLES CSS POUR UNE PRÉSENTATION PROFESSIONNELLE -->
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 40px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            background: white; 
            padding: 40px; 
            border-radius: 15px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            max-width: 800px;
            margin: 0 auto;
        }
        h1 { 
            color: #333; 
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        .success { 
            color: #28a745; 
            font-weight: bold; 
            text-align: center;
            font-size: 1.2em;
            margin-bottom: 30px;
        }
        .info { 
            background: #f8f9fa; 
            padding: 20px; 
            border-radius: 10px; 
            margin: 20px 0;
            border-left: 5px solid #007bff;
        }
        .info h3 {
            color: #007bff;
            margin-top: 0;
        }
        .status-loading {
            color: #ffc107;
            font-style: italic;
        }
        .status-loaded {
            color: #28a745;
            font-weight: bold;
        }
        ul li {
            margin: 8px 0;
        }
        .command {
            background: #2d3748;
            color: #e2e8f0;
            padding: 10px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
            overflow-x: auto;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #6c757d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Terraform Modular Project</h1>
        <p class="success">✅ Instance EC2 déployée avec succès !</p>
        
        <!-- INFORMATIONS DYNAMIQUES DE L'INSTANCE -->
        <div class="info">
            <h3>📋 Informations de l'instance :</h3>
            <p><strong>Projet :</strong> ${project_name}</p>
            <p><strong>Environnement :</strong> ${environment}</p>
            <p><strong>Instance ID :</strong> <span id="instance-id" class="status-loading">Chargement...</span></p>
            <p><strong>Type d'instance :</strong> <span id="instance-type" class="status-loading">Chargement...</span></p>
            <p><strong>Zone de disponibilité :</strong> <span id="az" class="status-loading">Chargement...</span></p>
            <p><strong>Adresse IP privée :</strong> <span id="private-ip" class="status-loading">Chargement...</span></p>
            <p><strong>Timestamp de déploiement :</strong> $(date)</p>
        </div>

        <!-- SERVICES INSTALLÉS -->
        <div class="info">
            <h3>🛠️ Services installés et configurés :</h3>
            <ul>
                <li>✅ <strong>Apache HTTP Server</strong> - Serveur web sur port 80</li>
                <li>✅ <strong>Git</strong> - Système de contrôle de version</li>
                <li>✅ <strong>Outils de monitoring</strong> - htop, tree, nano</li>
                <li>✅ <strong>AWS Systems Manager Agent</strong> - Accès sécurisé sans SSH</li>
                <li>✅ <strong>Curl & Wget</strong> - Clients HTTP en ligne de commande</li>
            </ul>
        </div>
        
        <!-- MÉTHODES D'ACCÈS -->
        <div class="info">
            <h3>🔐 Méthodes d'accès à l'instance :</h3>
            <p><strong>AWS Session Manager (Recommandé) :</strong></p>
            <div class="command">aws ssm start-session --target &lt;instance-id&gt; --region &lt;region&gt;</div>
            
            <p><strong>SSH traditionnel (si configuré) :</strong></p>
            <div class="command">ssh -i ~/.ssh/key.pem ec2-user@&lt;adresse-ip&gt;</div>
            
            <p><em>💡 Session Manager est plus sécurisé car il ne nécessite pas d'ouvrir le port SSH (22)</em></p>
        </div>

        <!-- INFORMATIONS TECHNIQUES -->
        <div class="info">
            <h3>⚙️ Informations techniques :</h3>
            <ul>
                <li><strong>OS :</strong> Amazon Linux 2</li>
                <li><strong>Serveur web :</strong> Apache HTTP Server (httpd)</li>
                <li><strong>Accès :</strong> AWS Systems Manager Session Manager</li>
                <li><strong>Sécurité :</strong> Volume EBS chiffré</li>
                <li><strong>Logs :</strong> /var/log/user-data.log</li>
            </ul>
        </div>

        <div class="footer">
            <p>🏗️ Déployé avec Terraform | 🚀 Module Compute | ☁️ AWS EC2</p>
            <p>Instance initialisée automatiquement via User Data Script</p>
        </div>
    </div>

    <!-- JAVASCRIPT POUR RÉCUPÉRER LES MÉTADONNÉES EC2 -->
    <script>
        // FONCTION UTILITAIRE POUR METTRE À JOUR UN ÉLÉMENT
        function updateElement(elementId, value, isError = false) {
            const element = document.getElementById(elementId);
            if (element) {
                element.textContent = value;
                element.className = isError ? 'status-error' : 'status-loaded';
            }
        }

        // RÉCUPÉRATION DE L'ID DE L'INSTANCE
        // Service de métadonnées EC2 : IP spéciale 169.254.169.254
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => updateElement('instance-id', data))
            .catch(error => updateElement('instance-id', 'Erreur de récupération', true));
        
        // RÉCUPÉRATION DU TYPE D'INSTANCE
        fetch('http://169.254.169.254/latest/meta-data/instance-type')
            .then(response => response.text())
            .then(data => updateElement('instance-type', data))
            .catch(error => updateElement('instance-type', 'Erreur de récupération', true));
            
        // RÉCUPÉRATION DE LA ZONE DE DISPONIBILITÉ
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => updateElement('az', data))
            .catch(error => updateElement('az', 'Erreur de récupération', true));

        // RÉCUPÉRATION DE L'ADRESSE IP PRIVÉE
        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(response => response.text())
            .then(data => updateElement('private-ip', data))
            .catch(error => updateElement('private-ip', 'Erreur de récupération', true));
    </script>
</body>
</html>
HTML_END

# ========================================================================================================
# SECTION 6 : FINALISATION ET VÉRIFICATIONS
# ========================================================================================================

# CONFIGURATION DES PERMISSIONS DU FICHIER WEB
# S'assurer que Apache peut lire le fichier
chmod 644 /var/www/html/index.html
chown apache:apache /var/www/html/index.html
echo "$(date): Page web créée et permissions configurées" >> /var/log/user-data.log

# JOURNALISATION DE LA FIN DU SCRIPT
echo "$(date): Script User Data terminé avec succès" >> /var/log/user-data.log
echo "$(date): Services disponibles :" >> /var/log/user-data.log
echo "  - Apache HTTP Server : Port 80" >> /var/log/user-data.log
echo "  - AWS SSM Agent : Prêt pour Session Manager" >> /var/log/user-data.log

# REDÉMARRAGE FINAL D'APACHE
# Pour s'assurer que tout fonctionne correctement après toutes les modifications
echo "$(date): Redémarrage final d'Apache..." >> /var/log/user-data.log
systemctl restart httpd

# VÉRIFICATION FINALE DU STATUT D'APACHE
if systemctl is-active --quiet httpd; then
    echo "$(date): ✅ Apache fonctionne correctement - Instance prête" >> /var/log/user-data.log
else
    echo "$(date): ❌ Erreur : Apache ne fonctionne pas correctement" >> /var/log/user-data.log
fi

# MESSAGE DE FIN DANS LES LOGS
echo "$(date): ========================================" >> /var/log/user-data.log
echo "$(date): INITIALISATION TERMINÉE AVEC SUCCÈS" >> /var/log/user-data.log
echo "$(date): Instance prête pour utilisation" >> /var/log/user-data.log
echo "$(date): ========================================" >> /var/log/user-data.log
