# Terraform Azure Load Balancer - Complete Guide

## 📋 Overview

This folder contains production-ready Terraform configurations for deploying Azure Load Balancers with various complexity levels.

## 🗂️ What's Inside

### Main Configurations
- **01-basic-load-balancer/** - Simple public load balancer with Windows VMs
- **02-internal-load-balancer/** - Internal load balancer for backend services
- **03-multi-tier-setup/** - Complete 3-tier application architecture
- **04-advanced-config/** - Zone-redundant setup with monitoring

### Reusable Modules
- **modules/load_balancer/** - Reusable load balancer module
- **modules/networking/** - Reusable networking module

## 🚀 Quick Start

### Prerequisites
```bash
# Install Terraform (macOS)
brew install terraform

# Install Azure CLI
brew install azure-cli

# Authenticate with Azure
az login
az account set --subscription "SUBSCRIPTION_ID"

# Verify installation
terraform version
az account show
```

### Deploy Basic Load Balancer
```bash
cd 01-basic-load-balancer

# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy
terraform apply

# View outputs
terraform output

# Destroy when done
terraform destroy
```

## 📊 Configuration Comparison

| Feature | Basic | Internal | Multi-Tier | Advanced |
|---------|-------|----------|-----------|----------|
| Public LB | ✅ | ❌ | ✅ | ✅ |
| Internal LB | ❌ | ✅ | ✅ | ❌ |
| Zone Redundancy | ❌ | ❌ | ❌ | ✅ |
| Monitoring | ❌ | ❌ | ❌ | ✅ |
| Multiple Tiers | ❌ | ❌ | ✅ | ❌ |
| Complexity | Low | Medium | High | Very High |
| Time to Deploy | 5 min | 7 min | 15 min | 20 min |

## 📖 Configuration Details

### 01-basic-load-balancer
**Ideal for:** Learning, simple web applications, POC

**What it creates:**
- Resource Group
- Virtual Network (10.0.0.0/16)
- Subnet (10.0.1.0/24)
- 3 Windows Server VMs
- Public Load Balancer
- Health Probes
- Load Balancing Rules

**Deploy:**
```bash
cd 01-basic-load-balancer
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Expected Output:**
```
load_balancer_public_ip = "X.X.X.X"
access_url = "http://X.X.X.X"
vm_private_ips = ["10.0.1.X", "10.0.1.Y", "10.0.1.Z"]
```

### 02-internal-load-balancer
**Ideal for:** Backend services, multi-tier applications

**What it creates:**
- Resource Group
- Virtual Network with 2 subnets
- 2 Linux VMs per subnet
- Internal Load Balancer
- Network Security Groups

**Deploy:**
```bash
cd 02-internal-load-balancer
terraform init
terraform plan
terraform apply
```

### 03-multi-tier-setup
**Ideal for:** Production applications, complex architectures

**What it creates:**
- 3-tier architecture (Web, API, Database)
- 3 separate subnets
- Public LB for Web tier
- Internal LBs for API and DB tiers
- Proper NSG rules per tier
- 2 VMs per tier

**Architecture:**
```
Internet
   ↓
[Public LB: port 80]
   ↓
[Web Tier VMs]
   ↓
[Internal LB: port 8080]
   ↓
[API Tier VMs]
   ↓
[Internal LB: port 3306]
   ↓
[DB Tier VMs]
```

**Deploy:**
```bash
cd 03-multi-tier-setup
terraform init
terraform plan
terraform apply

# Example output
web_lb_public_ip = "52.X.X.X"
api_lb_private_ip = "10.0.2.10"
db_lb_private_ip = "10.0.3.10"
```

### 04-advanced-config
**Ideal for:** Production with high availability requirements

**What it creates:**
- Zone-redundant load balancer
- VMs across 3 availability zones
- Diagnostics and monitoring setup
- Log Analytics workspace
- Alert rules
- Multiple outbound IPs

**Deploy:**
```bash
cd 04-advanced-config
terraform init
terraform plan
terraform apply
```

## 🔧 Common Commands

### Planning & Deployment
```bash
# Initialize working directory
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# Destroy resources
terraform destroy
```

### State Management
```bash
# Show current state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show azurerm_lb.lb

# Move resource
terraform state mv OLD_PATH NEW_PATH

# Remove resource (but keep in Azure)
terraform state rm azurerm_lb.lb
```

### Debugging
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Save plan output to file
terraform plan -json > plan.json

# Show execution plan in JSON
terraform show -json
```

## 📝 Variable Customization

### Basic Configuration
Edit `terraform.tfvars`:

```hcl
# Change location
location = "West US 2"

# Change VM count
vm_count = 5

# Change VM size
vm_size = "Standard_B4ms"

# Change environment name
environment = "staging"

# Add custom tags
tags = {
  Environment = "prod"
  Project = "myapp"
  Owner = "devops@company.com"
}
```

### Passing Variables via CLI
```bash
# Single variable
terraform plan -var="vm_count=5"

# Multiple variables
terraform plan \
  -var="location=West US 2" \
  -var="vm_count=5" \
  -var="environment=prod"

# From file
terraform plan -var-file="prod.tfvars"
```

## 🔐 Security Best Practices

### 1. Secure Credentials
```bash
# Use Azure CLI authentication (recommended)
az login

# Or use environment variables
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
```

### 2. Protect State File
```bash
# Configure remote state in Azure Storage
cat > backend.tf << 'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
EOF

# Initialize with remote backend
terraform init
```

### 3. Mark Sensitive Outputs
```hcl
output "vm_password" {
  value       = random_password.vm_password.result
  sensitive   = true
  description = "VM admin password"
}
```

### 4. Use Terraform Cloud
```bash
# Login to Terraform Cloud
terraform login

# Configure in terraform.tf
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "prod"
    }
  }
}
```

## 📊 Monitoring & Diagnostics

### View Logs
```bash
# Azure CLI
az monitor diagnostic-settings list --resource /subscriptions/...

# Query Log Analytics
az monitor log-analytics query \
  --workspace "workspace-id" \
  --analytics-query "AzureDiagnostics | where ResourceType == 'LOADBALANCERS'"
```

### KQL Queries for Monitoring
```kusto
# Unhealthy backend count
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName == "DipAvailability"
| summarize avg(Total) by bin(TimeGenerated, 5m)

# Connection count
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName == "SynCount"
| summarize sum(Total) by bin(TimeGenerated, 1m)
```

## 🐛 Troubleshooting

### Issue: Resource already exists
```bash
# Solution: Import existing resource
terraform import azurerm_lb.lb \
  "/subscriptions/SUB/resourceGroups/RG/providers/Microsoft.Network/loadBalancers/LB_NAME"
```

### Issue: Insufficient permissions
```bash
# Solution: Check RBAC
az role assignment list --assignee <principal-id>

# Grant required permissions
az role assignment create \
  --role Contributor \
  --assignee-object-id <principal-id>
```

### Issue: State mismatch
```bash
# Solution: Refresh state
terraform refresh

# Or remove and reimport
terraform state rm azurerm_lb.lb
terraform import azurerm_lb.lb <resource-id>
```

## 🏗️ Using Modules

### Load Balancer Module
```hcl
module "my_lb" {
  source = "./modules/load_balancer"

  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  environment        = "prod"

  lb_name           = "my-lb"
  lb_type           = "Public"
  backend_pool_name = "my-backend-pool"
  health_probe_name = "my-probe"
  lb_rule_name      = "my-rule"

  frontend_public_ip_id = azurerm_public_ip.lb_pip.id
  health_probe_port     = 80
  health_probe_path     = "/health"
  session_persistence   = "ClientIP"

  tags = local.common_tags
}
```

### Networking Module
```hcl
module "my_network" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location

  vnet_name = "my-vnet"
  vnet_cidr = "10.0.0.0/16"

  subnets = {
    web = { cidr = "10.0.1.0/24" }
    api = { cidr = "10.0.2.0/24" }
    db  = { cidr = "10.0.3.0/24" }
  }

  tags = local.common_tags
}
```

## 📈 Scaling Strategies

### Horizontal Scaling (Add VMs)
```bash
# Modify terraform.tfvars
vm_count = 10

# Apply
terraform apply
```

### Vertical Scaling (Change VM Size)
```bash
# Modify terraform.tfvars
vm_size = "Standard_D2s_v3"

# Apply (requires VM restart)
terraform apply
```

### Regional Scaling
```hcl
# Use workspaces for multi-region
terraform workspace new us-east
terraform workspace new us-west

# Deploy same config to different regions
terraform apply -var="location=East US"
```

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Init
        run: terraform -chdir=01-basic-load-balancer init
      
      - name: Plan
        run: terraform -chdir=01-basic-load-balancer plan
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      
      - name: Apply
        if: github.ref == 'refs/heads/main'
        run: terraform -chdir=01-basic-load-balancer apply -auto-approve
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
```

## 📚 File Structure Explained

```
terraform/
├── README.md                          ← You are here
├── 01-basic-load-balancer/
│   ├── provider.tf                    ← Azure provider config
│   ├── variables.tf                   ← Input variables
│   ├── main.tf                        ← Main resources
│   ├── outputs.tf                     ← Output values
│   └── terraform.tfvars               ← Variable values
├── 02-internal-load-balancer/
│   └── [same structure]
├── 03-multi-tier-setup/
│   └── [same structure]
├── 04-advanced-config/
│   └── [same structure]
└── modules/
    ├── load_balancer/                 ← LB module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── networking/                    ← Network module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🎯 Best Practices

### 1. Use Consistent Naming
```hcl
local {
  naming_convention = "${var.environment}-${var.project}-"
}

# Usage
resource "azurerm_lb" "lb" {
  name = "${local.naming_convention}lb"
}
```

### 2. Tag Everything
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}
```

### 3. Use Data Sources
```hcl
# Reference existing resources
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

resource "azurerm_lb" "lb" {
  resource_group_name = data.azurerm_resource_group.existing.name
}
```

### 4. Use Locals for Common Values
```hcl
locals {
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  environment         = var.environment
}
```

## 📞 Support & Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Load Balancer Docs](https://learn.microsoft.com/azure/load-balancer/)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

---

**Last Updated:** October 2025  
**Terraform Version:** 1.0+  
**Azure Provider:** 3.0+
