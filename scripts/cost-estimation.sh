#!/bin/bash

# =============================================================================
# SCRIPT DE TEST DE COÛT TERRAFORM - INFRACOST
# =============================================================================
# 
# Ce script effectue une estimation des coûts pour les environnements
# Terraform en utilisant Infracost
#
# Usage:
#   ./scripts/cost-estimation.sh [dev|prod|all]
#
# Prérequis:
#   - Infracost installé (https://www.infracost.io/docs/#quick-start)
#   - AWS CLI configuré
#   - Terraform initialisé dans les environnements
# =============================================================================

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRACOST_CONFIG="${PROJECT_ROOT}/.infracost/config.yml"
REPORTS_DIR="${PROJECT_ROOT}/cost-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleur
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si Infracost est installé
check_infracost() {
    if ! command -v infracost &> /dev/null; then
        print_error "Infracost n'est pas installé. Veuillez l'installer:"
        echo "  curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh"
        exit 1
    fi
    
    print_success "Infracost trouvé: $(infracost --version)"
}

# Créer le répertoire de rapports
create_reports_dir() {
    mkdir -p "${REPORTS_DIR}"
    print_info "Répertoire de rapports créé: ${REPORTS_DIR}"
}

# Estimer les coûts pour un environnement
estimate_environment_cost() {
    local env=$1
    local env_path="${PROJECT_ROOT}/environments/${env}"
    
    print_info "Estimation des coûts pour l'environnement: ${env}"
    
    if [[ ! -d "${env_path}" ]]; then
        print_error "Environnement ${env} introuvable: ${env_path}"
        return 1
    fi
    
    # Vérifier que terraform.tfvars existe
    if [[ ! -f "${env_path}/terraform.tfvars" ]]; then
        print_warning "Fichier terraform.tfvars manquant pour ${env}"
        print_info "Copie du fichier d'exemple..."
        cp "${env_path}/terraform.tfvars.example" "${env_path}/terraform.tfvars"
    fi
    
    # Initialiser Terraform si nécessaire
    if [[ ! -d "${env_path}/.terraform" ]]; then
        print_info "Initialisation de Terraform pour ${env}..."
        cd "${env_path}"
        terraform init
        cd "${PROJECT_ROOT}"
    fi
    
    # Générer le rapport de coûts
    local report_file="${REPORTS_DIR}/cost-estimate-${env}-${TIMESTAMP}.json"
    local html_report="${REPORTS_DIR}/cost-estimate-${env}-${TIMESTAMP}.html"
    
    print_info "Génération du rapport JSON..."
    infracost breakdown \
        --path "${env_path}" \
        --terraform-var-file "${env_path}/terraform.tfvars" \
        --format json \
        --out-file "${report_file}"
    
    print_info "Génération du rapport HTML..."
    infracost output \
        --path "${report_file}" \
        --format html \
        --out-file "${html_report}"
    
    # Afficher le résumé des coûts
    print_info "Résumé des coûts pour ${env}:"
    infracost breakdown \
        --path "${env_path}" \
        --terraform-var-file "${env_path}/terraform.tfvars" \
        --format table
    
    # Afficher un résumé détaillé des coûts
    local monthly_cost=$(jq -r '.totalMonthlyCost // "0"' "${report_file}")
    local resource_count=$(jq -r '.projects[0].breakdown.resources | length' "${report_file}")
    
    echo ""
    printf "${GREEN}💰 Coût total mensuel: \$%.2f USD${NC}\n" "${monthly_cost}"
    printf "${BLUE}📊 Nombre de ressources: %d${NC}\n" "${resource_count}"
    
    # Top 3 des ressources les plus coûteuses
    print_info "Top 3 des ressources les plus coûteuses:"
    jq -r '.projects[0].breakdown.resources | sort_by(.monthlyCost) | reverse | .[0:3] | .[] | "  • " + .name + ": $" + (.monthlyCost | tostring) + " USD/mois"' "${report_file}" 2>/dev/null || echo "  Données détaillées non disponibles"
    
    print_success "Rapports générés:"
    echo "  - JSON: ${report_file}"
    echo "  - HTML: ${html_report}"
}

# Comparer les coûts entre environnements
compare_environments() {
    local dev_report="${REPORTS_DIR}/cost-estimate-dev-${TIMESTAMP}.json"
    local prod_report="${REPORTS_DIR}/cost-estimate-prod-${TIMESTAMP}.json"
    
    if [[ -f "${dev_report}" && -f "${prod_report}" ]]; then
        print_info "Comparaison des coûts dev vs prod..."
        
        local comparison_file="${REPORTS_DIR}/cost-comparison-${TIMESTAMP}.json"
        
        infracost diff \
            --path "${dev_report}" \
            --compare-to "${prod_report}" \
            --format json \
            --out-file "${comparison_file}"
        
        # Générer le rapport HTML de comparaison
        local comparison_html="${REPORTS_DIR}/cost-comparison-${TIMESTAMP}.html"
        infracost output \
            --path "${comparison_file}" \
            --format html \
            --out-file "${comparison_html}"
        
        print_info "=== COMPARAISON DÉTAILLÉE DES COÛTS ==="
        echo ""
        
        # Extraire les coûts totaux
        local dev_total=$(jq -r '.totalMonthlyCost // "0"' "${dev_report}")
        local prod_total=$(jq -r '.totalMonthlyCost // "0"' "${prod_report}")
        
        # Calculer la différence
        local diff_amount=$(echo "scale=2; ${prod_total} - ${dev_total}" | bc -l)
        local diff_percent=$(echo "scale=2; (${diff_amount} / ${dev_total}) * 100" | bc -l)
        
        printf "${BLUE}Environnement DEV:${NC}  \$%.2f USD/mois\n" "${dev_total}"
        printf "${BLUE}Environnement PROD:${NC} \$%.2f USD/mois\n" "${prod_total}"
        printf "${BLUE}Différence:${NC}         \$%.2f USD/mois" "${diff_amount}"
        
        if (( $(echo "${diff_amount} > 0" | bc -l) )); then
            printf " ${RED}(+%.1f%%)${NC}\n" "${diff_percent}"
        else
            printf " ${GREEN}(%.1f%%)${NC}\n" "${diff_percent}"
        fi
        
        echo ""
        print_info "Détails des différences par ressource:"
        infracost diff \
            --path "${dev_report}" \
            --compare-to "${prod_report}" \
            --format diff
        
        echo ""
        print_success "Rapports de comparaison générés:"
        echo "  - JSON: ${comparison_file}"
        echo "  - HTML: ${comparison_html}"
        echo ""
        
        # Recommandations basées sur la différence
        if (( $(echo "${diff_percent} > 200" | bc -l) )); then
            print_warning "La production coûte plus de 200% de plus que le dev"
            echo "  💡 Recommandation: Vérifiez la taille des instances et l'Auto Scaling"
        elif (( $(echo "${diff_percent} > 100" | bc -l) )); then
            print_info "La production coûte plus de 100% de plus que le dev (normal)"
            echo "  💡 Recommandation: Configuration cohérente avec les bonnes pratiques"
        elif (( $(echo "${diff_percent} < 50" | bc -l) )); then
            print_warning "La production coûte moins de 50% de plus que le dev"
            echo "  💡 Recommandation: Vérifiez si la prod a suffisamment de ressources"
        fi
    fi
}

# Vérifier les seuils de coût
check_cost_thresholds() {
    local env=$1
    local report_file="${REPORTS_DIR}/cost-estimate-${env}-${TIMESTAMP}.json"
    
    if [[ -f "${report_file}" ]]; then
        local monthly_cost=$(jq -r '.totalMonthlyCost' "${report_file}")
        local threshold=100 # Seuil par défaut de 100 USD
        
        if [[ "${env}" == "prod" ]]; then
            threshold=500 # Seuil plus élevé pour prod
        fi
        
        if (( $(echo "${monthly_cost} > ${threshold}" | bc -l) )); then
            print_warning "Coût mensuel pour ${env} (${monthly_cost} USD) dépasse le seuil de ${threshold} USD"
        else
            print_success "Coût mensuel pour ${env} (${monthly_cost} USD) dans les limites"
        fi
    fi
}

# Afficher l'aide
show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  dev     Estimer les coûts pour l'environnement dev"
    echo "  prod    Estimer les coûts pour l'environnement prod"
    echo "  all     Estimer les coûts pour tous les environnements"
    echo "  help    Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 dev          # Estimer les coûts dev"
    echo "  $0 all          # Estimer tous les environnements"
    echo ""
}

# Fonction principale
main() {
    local environment=${1:-"all"}
    
    case "${environment}" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "dev")
            check_infracost
            create_reports_dir
            estimate_environment_cost "dev"
            check_cost_thresholds "dev"
            ;;
        "prod")
            check_infracost
            create_reports_dir
            estimate_environment_cost "prod"
            check_cost_thresholds "prod"
            ;;
        "all")
            check_infracost
            create_reports_dir
            estimate_environment_cost "dev"
            estimate_environment_cost "prod"
            compare_environments
            check_cost_thresholds "dev"
            check_cost_thresholds "prod"
            ;;
        *)
            print_error "Option invalide: ${environment}"
            show_help
            exit 1
            ;;
    esac
    
    print_success "Estimation des coûts terminée!"
}

# Exécuter le script
main "$@"