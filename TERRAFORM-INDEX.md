# 📦 Terraform Folder - Quick Start

## ✨ What's New

A complete **Terraform configuration library** for Azure Load Balancer has been added to your package!

### 📁 Structure

```
terraform/
├── README.md                          # Main documentation
├── GUIDE.md                           # Comprehensive guide
├── deploy.sh                          # Interactive deployment script
├── 01-basic-load-balancer/           # Simple public LB
├── 02-internal-load-balancer/        # Private internal LB
├── 03-multi-tier-setup/              # 3-tier production setup
├── 04-advanced-config/               # Zone-redundant with monitoring
└── modules/                           # Reusable components
    ├── load_balancer/                # LB module
    └── networking/                   # Network module
```

## 🚀 Quick Start (30 seconds)

### Step 1: Check Prerequisites
```bash
brew install terraform
brew install azure-cli
az login
```

### Step 2: Deploy
```bash
cd terraform/01-basic-load-balancer
terraform init
terraform plan
terraform apply
```

### Step 3: Get Outputs
```bash
terraform output
# Or use the interactive script:
# cd terraform && ./deploy.sh
```

## 📚 Documentation

| File | Purpose | Read Time |
|------|---------|-----------|
| **README.md** | Overview and quick reference | 5 min |
| **GUIDE.md** | Comprehensive guide with examples | 30 min |
| **deploy.sh** | Interactive deployment script | N/A |

## 🎯 Choose Your Configuration

### 1️⃣ Basic Load Balancer
- **Perfect for:** Learning, small apps, POC
- **Includes:** 1 Public LB, 3 Windows VMs, Health probes
- **Time:** 5 minutes to deploy
- **Cost:** $50-100/month

**Deploy:**
```bash
cd 01-basic-load-balancer
terraform init && terraform plan && terraform apply
```

### 2️⃣ Internal Load Balancer
- **Perfect for:** Backend services, multi-tier apps
- **Includes:** 1 Internal LB, 2 Linux VMs, NSGs
- **Time:** 7 minutes to deploy
- **Cost:** $30-50/month

**Deploy:**
```bash
cd 02-internal-load-balancer
terraform init && terraform plan && terraform apply
```

### 3️⃣ Multi-Tier Setup
- **Perfect for:** Production applications
- **Includes:** 3 tiers, 6 VMs, 3 LBs (1 public, 2 internal)
- **Time:** 15 minutes to deploy
- **Cost:** $200-300/month

**Architecture:**
```
[Internet] → [Public LB:80] → [Web Tier]
                              ↓
                         [Internal LB:8080] → [API Tier]
                                              ↓
                                         [Internal LB:3306] → [DB Tier]
```

**Deploy:**
```bash
cd 03-multi-tier-setup
terraform init && terraform plan && terraform apply
```

### 4️⃣ Advanced Configuration
- **Perfect for:** High availability, production
- **Includes:** Zone redundancy, 3 zones, monitoring, alerts
- **Time:** 20 minutes to deploy
- **Cost:** $150-250/month

**Deploy:**
```bash
cd 04-advanced-config
terraform init && terraform plan && terraform apply
```

## 🎮 Interactive Deployment

Use the interactive script for guided deployment:

```bash
cd terraform
./deploy.sh

# Follow the menu:
# 1) Deploy configuration
# 2) Show deployment status
# 3) Destroy resources
# 4) Check prerequisites
# 5) Exit
```

## 📊 File Breakdown

### Configuration Files (50 total)
- **5 files × 4 configurations** = 20 configuration files
- Each includes: `provider.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars`

### Module Files (6 total)
- **Load Balancer Module** (3 files): Reusable LB component
- **Networking Module** (3 files): Reusable networking component

### Documentation (3 files)
- `README.md` - Quick reference
- `GUIDE.md` - Comprehensive guide
- `deploy.sh` - Deployment automation

## 🔧 Common Commands

### Initialize
```bash
cd 01-basic-load-balancer
terraform init
```

### Plan
```bash
terraform plan                           # Show what will be created
terraform plan -out=tfplan               # Save plan to file
terraform plan -destroy                  # Show what will be destroyed
```

### Deploy
```bash
terraform apply                          # Interactive apply
terraform apply tfplan                   # Apply saved plan
terraform apply -auto-approve           # Auto-approve (non-interactive)
```

### Check Status
```bash
terraform show                           # Show current state
terraform output                         # Show outputs only
terraform state list                     # List all resources
```

### Cleanup
```bash
terraform destroy                        # Interactive destroy
terraform destroy -auto-approve         # Auto-approve (non-interactive)
```

## 🔐 Security Tips

### 1. Never commit secrets
```bash
# Add to .gitignore
echo "terraform.tfvars" >> .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore
```

### 2. Use remote state
```hcl
# Create backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "prod.tfstate"
  }
}
```

### 3. Mark outputs as sensitive
```hcl
output "admin_password" {
  value     = azurerm_windows_virtual_machine.vm.admin_password
  sensitive = true
}
```

## 📈 Configuration Comparison

| Feature | Basic | Internal | Multi-Tier | Advanced |
|---------|:-----:|:--------:|:----------:|:--------:|
| Public Load Balancer | ✅ | ❌ | ✅ | ✅ |
| Internal Load Balancer | ❌ | ✅ | ✅ | ❌ |
| Multiple Tiers | ❌ | ❌ | ✅ | ❌ |
| Zone Redundancy | ❌ | ❌ | ❌ | ✅ |
| Monitoring | ❌ | ❌ | ❌ | ✅ |
| **Complexity** | Low | Low | High | Very High |
| **Deployment Time** | 5 min | 7 min | 15 min | 20 min |
| **Monthly Cost** | $50-100 | $30-50 | $200-300 | $150-250 |

## 🎓 Learning Path

### Day 1: Learn Basics
1. Read `terraform/README.md`
2. Review `01-basic-load-balancer/main.tf`
3. Deploy basic configuration

### Day 2: Explore Variations
1. Deploy `02-internal-load-balancer`
2. Review networking with NSG rules
3. Understand health probes

### Day 3: Advanced Setup
1. Deploy `03-multi-tier-setup`
2. Understand 3-tier architecture
3. Review multiple load balancers

### Day 4: Production Ready
1. Study `04-advanced-config`
2. Implement monitoring
3. Learn zone redundancy

## 🐛 Troubleshooting

### Issue: "terraform: command not found"
```bash
# Solution: Install Terraform
brew install terraform
```

### Issue: "Azure CLI not installed"
```bash
# Solution: Install Azure CLI
brew install azure-cli
```

### Issue: "Not authenticated with Azure"
```bash
# Solution: Login to Azure
az login
```

### Issue: Resource already exists
```bash
# Solution: Import the resource
terraform import azurerm_lb.lb "/subscriptions/SUB_ID/resourceGroups/RG/providers/Microsoft.Network/loadBalancers/LB_NAME"
```

### Issue: State file conflicts
```bash
# Solution: Refresh state
terraform refresh

# Or reimport:
terraform state rm azurerm_lb.lb
terraform import azurerm_lb.lb <resource-id>
```

## 📞 Next Steps

### 1. Read the Documentation
```bash
# Start with quick reference
cat terraform/README.md

# Then read comprehensive guide
cat terraform/GUIDE.md
```

### 2. Deploy Your First Configuration
```bash
# Use interactive script
cd terraform
./deploy.sh

# Or manual deployment
cd 01-basic-load-balancer
terraform init
terraform plan
terraform apply
```

### 3. Customize for Your Needs
```bash
# Edit variables
vim terraform.tfvars

# Deploy with custom values
terraform apply
```

### 4. Learn and Iterate
- Start with basic configuration
- Gradually move to advanced setups
- Use modules for reusability
- Implement monitoring and alerts

## 📚 Additional Resources

### Documentation
- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Load Balancer Docs](https://learn.microsoft.com/azure/load-balancer/)

### Quick References
- `GUIDE.md` - Comprehensive guide with examples
- `README.md` - Quick reference and troubleshooting
- Each configuration folder has comments explaining all resources

### Courses & Learning
- [HashiCorp Learn - Terraform](https://learn.hashicorp.com/terraform)
- [Microsoft Learn - Terraform on Azure](https://learn.microsoft.com/training/paths/terraform-azure/)

## ✅ Verification Checklist

After deployment, verify everything works:

- [ ] Terraform initialized successfully
- [ ] Plan shows expected resources
- [ ] Apply completes without errors
- [ ] Resources created in Azure Portal
- [ ] Load balancer is healthy
- [ ] Backend pools have healthy members
- [ ] Can reach load balancer public IP
- [ ] Outputs displayed correctly
- [ ] All tags applied to resources
- [ ] Monitoring configured (if applicable)

## 🎉 You're Ready!

**Next Action:**
```bash
cd terraform/01-basic-load-balancer
terraform init
terraform plan
```

**Questions?** Check:
1. `terraform/README.md` - Quick answers
2. `terraform/GUIDE.md` - Detailed guide
3. Run `terraform -help` - CLI help
4. Check Azure Portal - Visual verification

---

**Happy Terraform!** 🚀

*Created: October 2025*  
*Terraform Version: 1.0+*  
*Azure Provider: 3.0+*
