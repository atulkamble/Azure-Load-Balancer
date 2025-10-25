#!/bin/bash

# Azure Load Balancer - Terraform Deployment Script
# This script helps deploy Terraform configurations for Azure Load Balancer

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Install from https://www.terraform.io/downloads"
        exit 1
    fi
    print_success "Terraform installed: $(terraform version -json | jq -r '.terraform_version')"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install from https://learn.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI installed: $(az --version | head -1)"
    
    # Check Azure login
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Running 'az login'..."
        az login
    fi
    
    ACCOUNT=$(az account show --query 'name' -o tsv)
    SUBSCRIPTION=$(az account show --query 'id' -o tsv)
    print_success "Logged in to: $ACCOUNT"
    print_info "Subscription ID: $SUBSCRIPTION"
}

# List available configurations
list_configs() {
    print_header "Available Configurations"
    
    echo ""
    echo "  1) Basic Load Balancer"
    echo "     - Simple public-facing load balancer"
    echo "     - 3 Windows VMs"
    echo "     - Estimated cost: \$50-100/month"
    echo ""
    echo "  2) Internal Load Balancer"
    echo "     - Private internal load balancer"
    echo "     - 2 Linux VMs"
    echo "     - Estimated cost: \$30-50/month"
    echo ""
    echo "  3) Multi-Tier Setup"
    echo "     - 3-tier architecture (Web, API, DB)"
    echo "     - 6 VMs total (2 per tier)"
    echo "     - Estimated cost: \$200-300/month"
    echo ""
    echo "  4) Advanced Configuration"
    echo "     - Zone-redundant deployment"
    echo "     - Monitoring & diagnostics"
    echo "     - Estimated cost: \$150-250/month"
    echo ""
}

# Deploy configuration
deploy_config() {
    local config=$1
    local config_path=""
    local config_name=""
    
    case $config in
        1)
            config_path="01-basic-load-balancer"
            config_name="Basic Load Balancer"
            ;;
        2)
            config_path="02-internal-load-balancer"
            config_name="Internal Load Balancer"
            ;;
        3)
            config_path="03-multi-tier-setup"
            config_name="Multi-Tier Setup"
            ;;
        4)
            config_path="04-advanced-config"
            config_name="Advanced Configuration"
            ;;
        *)
            print_error "Invalid selection"
            return 1
            ;;
    esac
    
    print_header "Deploying: $config_name"
    
    # Change to config directory
    if [ ! -d "$config_path" ]; then
        print_error "Configuration directory not found: $config_path"
        return 1
    fi
    
    cd "$config_path"
    print_success "Changed to directory: $config_path"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
    
    # Validate configuration
    print_info "Validating configuration..."
    terraform validate
    print_success "Configuration is valid"
    
    # Format code
    print_info "Formatting code..."
    terraform fmt
    print_success "Code formatted"
    
    # Show plan
    print_info "Generating execution plan..."
    terraform plan -out=tfplan
    print_success "Plan generated: tfplan"
    
    # Confirm deployment
    echo ""
    read -p "Do you want to proceed with deployment? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Deployment cancelled"
        rm -f tfplan
        return 0
    fi
    
    # Apply configuration
    print_info "Applying configuration..."
    terraform apply tfplan
    print_success "Configuration applied successfully!"
    
    # Show outputs
    print_header "Deployment Outputs"
    terraform output
    
    # Save outputs to file
    terraform output -json > outputs.json
    print_success "Outputs saved to outputs.json"
    
    cd - > /dev/null
}

# Destroy configuration
destroy_config() {
    local config=$1
    local config_path=""
    local config_name=""
    
    case $config in
        1)
            config_path="01-basic-load-balancer"
            config_name="Basic Load Balancer"
            ;;
        2)
            config_path="02-internal-load-balancer"
            config_name="Internal Load Balancer"
            ;;
        3)
            config_path="03-multi-tier-setup"
            config_name="Multi-Tier Setup"
            ;;
        4)
            config_path="04-advanced-config"
            config_name="Advanced Configuration"
            ;;
        *)
            print_error "Invalid selection"
            return 1
            ;;
    esac
    
    print_header "Destroying: $config_name"
    
    if [ ! -d "$config_path" ]; then
        print_error "Configuration directory not found: $config_path"
        return 1
    fi
    
    cd "$config_path"
    
    # Show plan
    print_info "Generating destroy plan..."
    terraform plan -destroy -out=destroy_plan
    print_success "Destroy plan generated"
    
    # Confirm destruction
    echo ""
    print_warning "This will delete all resources!"
    read -p "Are you sure you want to destroy? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Destroy cancelled"
        rm -f destroy_plan
        cd - > /dev/null
        return 0
    fi
    
    # Destroy
    print_info "Destroying resources..."
    terraform destroy -auto-approve
    print_success "Resources destroyed"
    
    cd - > /dev/null
}

# Show status
show_status() {
    local config=$1
    local config_path=""
    
    case $config in
        1) config_path="01-basic-load-balancer" ;;
        2) config_path="02-internal-load-balancer" ;;
        3) config_path="03-multi-tier-setup" ;;
        4) config_path="04-advanced-config" ;;
        *) return 1 ;;
    esac
    
    if [ ! -d "$config_path" ]; then
        print_error "Configuration not found"
        return 1
    fi
    
    cd "$config_path"
    
    if [ ! -f "terraform.tfstate" ]; then
        print_info "No resources deployed yet"
        cd - > /dev/null
        return 0
    fi
    
    print_header "Deployment Status"
    terraform show
    
    echo ""
    print_header "Outputs"
    terraform output
    
    cd - > /dev/null
}

# Main menu
main_menu() {
    echo ""
    print_header "Azure Load Balancer - Terraform Deployment"
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Deploy configuration"
    echo "  2) Show deployment status"
    echo "  3) Destroy resources"
    echo "  4) Check prerequisites"
    echo "  5) Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            list_configs
            read -p "Select configuration (1-4): " config
            deploy_config "$config"
            ;;
        2)
            list_configs
            read -p "Select configuration (1-4): " config
            show_status "$config"
            ;;
        3)
            list_configs
            read -p "Select configuration (1-4): " config
            destroy_config "$config"
            ;;
        4)
            check_prerequisites
            ;;
        5)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            main_menu
            ;;
    esac
    
    # Ask to continue
    echo ""
    read -p "Continue? (yes/no): " continue
    if [ "$continue" = "yes" ]; then
        main_menu
    else
        print_info "Goodbye!"
        exit 0
    fi
}

# Run main menu
check_prerequisites
main_menu
