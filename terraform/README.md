# Terraform Configuration for Azure Load Balancer

This folder contains production-ready Terraform configurations for deploying Azure Load Balancers.

## 📁 Folder Structure

```
terraform/
├── README.md                          # This file
├── variables.tf                       # Input variables
├── main.tf                            # Main configuration
├── outputs.tf                         # Output values
├── terraform.tfvars                   # Variable values (example)
├── provider.tf                        # Azure provider configuration
├── locals.tf                          # Local values
├── 01-basic-load-balancer/           # Basic public load balancer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── 02-internal-load-balancer/        # Internal load balancer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── 03-multi-tier-setup/              # Multi-tier application
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── 04-advanced-config/               # Advanced configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── modules/                          # Reusable modules
    ├── load_balancer/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── networking/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🚀 Quick Start

### Prerequisites
```bash
# Install Terraform
brew install terraform              # macOS
# or
terraform version                   # Check existing installation

# Install Azure CLI
brew install azure-cli              # macOS

# Authenticate with Azure
az login
az account show
```

### Deploy Basic Load Balancer

```bash
# Navigate to basic example
cd terraform/01-basic-load-balancer

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan

# View outputs
terraform output
```

### Destroy Resources

```bash
# Destroy all resources
terraform destroy

# Destroy specific example
cd terraform/01-basic-load-balancer
terraform destroy
```

## 📋 Configuration Examples

### 1. Basic Public Load Balancer (`01-basic-load-balancer`)

Simple public-facing load balancer with 3 backend VMs.

**Features:**
- Public IP address
- Load balancing rules for HTTP/HTTPS
- Health probes
- Backend pool with 3 VMs
- Network security group

**Deploy:**
```bash
cd 01-basic-load-balancer
terraform init
terraform plan
terraform apply
```

### 2. Internal Load Balancer (`02-internal-load-balancer`)

Internal load balancer for multi-tier applications.

**Features:**
- Private IP address
- Load balancing rules for internal traffic
- Multiple backend pools
- Health probes configured
- Security hardened for private network

**Deploy:**
```bash
cd 02-internal-load-balancer
terraform init
terraform plan
terraform apply
```

### 3. Multi-Tier Setup (`03-multi-tier-setup`)

Complete 3-tier application with public and internal load balancers.

**Features:**
- Web tier with public load balancer
- API tier with internal load balancer
- Database tier with internal load balancer
- Proper subnet segmentation
- NSG rules per tier
- Multiple zones for HA

**Deploy:**
```bash
cd 03-multi-tier-setup
terraform init
terraform plan
terraform apply
```

### 4. Advanced Configuration (`04-advanced-config`)

Advanced setup with all features enabled.

**Features:**
- Zone-redundant deployment
- Multiple availability zones
- Session persistence
- TCP reset
- Outbound rules configured
- SNAT port management
- Diagnostics and monitoring
- Alert rules

**Deploy:**
```bash
cd 04-advanced-config
terraform init
terraform plan
terraform apply
```

## 🔧 Variables

Common variables across all configurations:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `location` | string | "East US" | Azure region |
| `resource_group_name` | string | "rg-lb" | Resource group name |
| `environment` | string | "prod" | Environment name |
| `vm_count` | number | 3 | Number of backend VMs |
| `vm_size` | string | "Standard_B2s" | VM size |
| `instance_count` | number | 2 | Number of instances per zone |
| `enable_monitoring` | bool | true | Enable diagnostics |
| `enable_alerts` | bool | true | Enable alert rules |

## 📤 Outputs

Each configuration provides:

```
load_balancer_ip          - Public IP address
load_balancer_id          - Load balancer resource ID
load_balancer_name        - Load balancer name
backend_pool_id           - Backend pool ID
health_probe_id           - Health probe ID
frontend_ip_id            - Frontend IP ID
```

## 🗂️ Module Usage

### Load Balancer Module

```hcl
module "load_balancer" {
  source = "./modules/load_balancer"

  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  environment        = "prod"
  
  # Load balancer configuration
  lb_name            = "lb-prod"
  lb_sku             = "Standard"
  lb_type            = "Public"
  
  # Frontend configuration
  frontend_subnet_id = azurerm_subnet.frontend.id
  frontend_ip_name   = "pip-lb"
  
  # Backend configuration
  backend_pool_name  = "bp-backend"
  backend_vms        = azurerm_network_interface.backend.*.id
  
  # Health probe
  health_probe_name  = "hp-http"
  health_probe_port  = 80
  health_probe_path  = "/health"
}
```

### Networking Module

```hcl
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  
  vnet_name          = "vnet-prod"
  vnet_cidr          = "10.0.0.0/16"
  
  subnets = {
    frontend = {
      cidr = "10.0.1.0/24"
    }
    backend = {
      cidr = "10.0.2.0/24"
    }
  }
}
```

## 📊 Backend State Management

### Local State (Development)

```bash
# Default - stores state locally
terraform init
```

### Remote State (Production)

```bash
# Create storage account for state
az storage account create \
  --name tfstate \
  --resource-group rg-terraform \
  --location eastus

# Configure backend
cat > backend.tf << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
EOF

# Reinitialize with remote backend
terraform init
```

## 🔐 Security Best Practices

### 1. Secure Variables

```bash
# Use environment variables (sensitive data)
export TF_VAR_admin_username="azureuser"
export TF_VAR_admin_password="$(openssl rand -base64 32)"

# Or use terraform.tfvars.json with restricted permissions
chmod 600 terraform.tfvars.json
```

### 2. Backend Security

```hcl
# Restrict remote state access
data "azurerm_storage_account" "terraform_backend" {
  name                = "tfstate"
  resource_group_name = "rg-terraform"
}

resource "azurerm_storage_account_network_rule" "terraform_backend" {
  storage_account_id = data.azurerm_storage_account.terraform_backend.id

  default_action             = "Deny"
  ip_rules                   = ["YOUR_IP/32"]
  virtual_network_subnet_ids = [azurerm_subnet.management.id]
  bypass                     = ["AzureServices"]
}
```

### 3. Encrypt Sensitive Outputs

```hcl
output "lb_password" {
  value       = random_password.lb_password.result
  sensitive   = true
  description = "Sensitive output - will not be displayed"
}
```

## 📈 Scaling Configurations

### Horizontal Scaling

```bash
# Scale backend pool
terraform apply \
  -var="vm_count=5" \
  -var="instance_count=3"
```

### Update Load Balancer Rules

```bash
# Modify rules in terraform.tfvars
# Then apply
terraform apply
```

## 🐛 Troubleshooting

### Import Existing Resources

```bash
# Import existing load balancer
terraform import azurerm_lb.example \
  /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.Network/loadBalancers/LB_NAME

# Import backend pool
terraform import azurerm_lb_backend_address_pool.example \
  /subscriptions/SUBSCRIPTION_ID/resourceGroups/RG_NAME/providers/Microsoft.Network/loadBalancers/LB_NAME/backendAddressPools/POOL_NAME
```

### Validate Configuration

```bash
# Check syntax and structure
terraform validate

# Check formatting
terraform fmt -recursive

# Security scanning with tfsec
brew install tfsec
tfsec .
```

### Debug Issues

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Disable after debugging
unset TF_LOG
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: 'Terraform'

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Validate
        run: terraform validate
        
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply tfplan
```

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Load Balancer Documentation](https://learn.microsoft.com/en-us/azure/load-balancer/)
- [Terraform Best Practices](https://learn.hashicorp.com/terraform)

## 💡 Tips & Tricks

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate all configurations
terraform validate

# Generate and show an execution plan
terraform plan -out=tfplan

# Show a specific resource
terraform show -json | jq '.resources[] | select(.type == "azurerm_lb")'

# Refresh state
terraform refresh

# Show state
terraform show

# Remove resource from state (but not from Azure)
terraform state rm azurerm_lb.example
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the individual example README files
3. Consult [Terraform documentation](https://www.terraform.io/docs)
4. Check [Azure provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Last Updated:** October 2025  
**Terraform Version:** 1.0+  
**Azure Provider Version:** 3.0+
