# Azure Load Balancer - Complete Learning Guide

Welcome to the comprehensive Azure Load Balancer learning guide! This repository contains everything you need to understand, configure, and deploy Azure Load Balancers effectively.

# Azure Public and Private Load Balancer Setup

## Prerequisites

* Azure subscription
* SSH key pair downloaded

---

## 🚀 Public Load Balancer Setup

### 1. Create Resources

* **Resource Group**: `LB`
* **Virtual Network**: `LBVNET`
* **Virtual Machines**: `VM1`, `VM2`

  * Ubuntu Server
  * Size: `Standard_D2s_v3`
  * NSG Rules: `HTTP-80`, `HTTPS-443`, `SSH-22`

### 2. SSH into Both VMs

```bash
cd Downloads
chmod 400 key.pem
ssh -i key.pem atul@20.51.112.68
ssh -i key.pem atul@48.221.120.162
```

### 3. Install Apache on Each VM

```bash
sudo apt update
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
cd /var/www/html
sudo rm index.html
sudo touch index.html
sudo nano index.html
```

* VM1 → `<h1>Webserver 1</h1>`
* VM2 → `<h1>Webserver 2</h1>`

### 4. Note Public IPs of VM1 & VM2

### 5. Create Public Load Balancer

* Azure Portal → **Load Balancers → Create → Standard → Public**

### 6. Configure

* **Frontend IP** → Create Public IP
* **Backend Pool** → `mybackendpool` (select VM1 & VM2 via VNet)
* **Health Probe** → `myhealthprobe` (Port `80`)
* **Load Balancing Rule** → Port `80 → 80`

### 7. Test

* Open the Load Balancer Public IP in browser → traffic should switch between VM1 & VM2

---

## 🔒 Private Internal Load Balancer Setup

### 1. Create VM3

* OS: **Windows Server 2025**
* **Login using RDP** → Open Edge/Chrome Browser

### 2. Create Internal Load Balancer

* Azure Portal → **Load Balancers → Create → Standard → Internal**

### 3. Configure

* **Frontend IP** → Create private IP allocation
* **Backend Pool** → `mybackendpool` (select VM1 & VM2)
* **Health Probe** → Port `80`
* **LB Rule** → `80 → 80`

### 4. Test

* From VM3, browse internal **Load Balancer IP** → Should load Webserver 1 & 2

---

✅ **Public LB = Internet-facing access**
✅ **Private LB = Internal VNet-only access**

## 📚 Documentation Structure

### 1. **01-THEORY.md** - Comprehensive Theory Guide
Complete theoretical foundation covering:
- Overview and core concepts
- Types of Load Balancers (Public, Internal, Gateway)
- Important components explained
- How health checks work (with diagrams)
- Load Balancer SKUs
- Configuration hierarchy
- Traffic flow patterns
- Session persistence
- Pricing model
- Limitations and constraints
- Best practices overview
- Common use cases
- Comparison with other Azure services

**Best for**: Understanding concepts, studying for certifications

---

### 2. **02-PRACTICAL-STEPS.md** - Step-by-Step Implementation
Detailed practical guide with 14 implementation steps:
- Prerequisites setup
- Resource group creation
- Virtual network setup
- Network security groups
- Network interfaces
- Virtual machines
- Public load balancer creation
- Health probe configuration
- Backend pool setup
- Load balancing rules
- Testing and monitoring
- Outbound rules
- Internal load balancer
- Cleanup procedures
- Complete setup script

**Best for**: Hands-on implementation, learning CLI commands

---

### 3. **03-CODE-SNIPPETS.md** - Code Examples & Templates
Ready-to-use code snippets in multiple formats:
- ARM Templates (JSON) - Complete load balancer setup
- Bicep - Modern IaC approach
- PowerShell - Automated deployment
- Python SDK - Programmatic setup
- Terraform - Open-source IaC
- Health check monitoring script
- Load testing script

**Best for**: Quick reference, copy-paste deployment, scripting

---

### 4. **04-USE-CASES-BEST-PRACTICES.md** - Real-World Scenarios
Six detailed use cases with architecture diagrams:
1. High-Availability Web Application
2. Multi-Tier Application with Internal LB
3. E-commerce with Session Persistence
4. Real-Time Communication (WebSockets)
5. High-Performance Gaming
6. IoT Data Ingestion Platform

Plus comprehensive best practices:
- Design & Architecture
- Performance optimization
- Monitoring & logging
- Security configuration
- Cost optimization

**Best for**: Understanding real-world applications, best practices

---

### 5. **05-QUICK-REFERENCE-TROUBLESHOOTING.md** - Quick Commands & Fixes
Fast reference guide including:
- Common Azure CLI commands
- Configuration checklist
- Pricing quick reference
- Troubleshooting guide for 6 common issues
- Performance tuning checklist
- Decision tree for problem-solving
- Useful links and resources

**Best for**: Quick lookups, troubleshooting, checklists

---

### 6. **06-CONFIGURATION-EXAMPLES.md** - Real Configuration Setups
Four complete configuration examples:
1. Web Application Setup (with script)
2. Multi-Tier Application (with architecture)
3. Gaming Service (UDP-based)
4. Monitoring & Alerts

**Best for**: Copy working configurations, understanding complete setups

---

## 🚀 Quick Start Guide

### For Beginners
1. Start with **01-THEORY.md** (read for 30 minutes)
2. Review **04-USE-CASES-BEST-PRACTICES.md** (understand use cases)
3. Follow **02-PRACTICAL-STEPS.md** (hands-on deployment)
4. Reference **05-QUICK-REFERENCE-TROUBLESHOOTING.md** (when needed)

### For Experienced Users
1. Skim **01-THEORY.md** (5 minutes - refresh concepts)
2. Jump to **03-CODE-SNIPPETS.md** (pick your IaC language)
3. Reference **06-CONFIGURATION-EXAMPLES.md** (copy template)
4. Use **05-QUICK-REFERENCE-TROUBLESHOOTING.md** (when debugging)

### For Specific Tasks
| Task | Document |
|------|----------|
| Learn Load Balancer | 01-THEORY.md |
| Deploy manually via CLI | 02-PRACTICAL-STEPS.md |
| Deploy via IaC (ARM/Bicep/Terraform) | 03-CODE-SNIPPETS.md |
| Real-world scenario | 04-USE-CASES-BEST-PRACTICES.md |
| Quick command lookup | 05-QUICK-REFERENCE-TROUBLESHOOTING.md |
| Complete working setup | 06-CONFIGURATION-EXAMPLES.md |
| Troubleshoot issue | 05-QUICK-REFERENCE-TROUBLESHOOTING.md |

---

## 📋 Key Topics Covered

### Theory Concepts
✓ Load Balancer architecture  
✓ OSI Layer 4 networking  
✓ High availability principles  
✓ Health probe mechanisms  
✓ Session persistence strategies  
✓ SNAT (Source NAT)  
✓ Connection pooling  
✓ Outbound connectivity  

### Practical Skills
✓ Azure CLI commands  
✓ PowerShell scripting  
✓ ARM template creation  
✓ Bicep configuration  
✓ Terraform deployment  
✓ Python SDK usage  
✓ Monitoring setup  
✓ Performance tuning  

### Real-World Scenarios
✓ Web applications  
✓ Multi-tier architectures  
✓ E-commerce platforms  
✓ Real-time communication  
✓ Gaming services  
✓ IoT platforms  
✓ High-frequency trading  
✓ Enterprise applications  

### Operational Excellence
✓ Health checks  
✓ Load distribution  
✓ Failover testing  
✓ Monitoring alerts  
✓ Troubleshooting  
✓ Performance optimization  
✓ Cost management  
✓ Security hardening  

---

## 🎯 Learning Objectives

After completing this guide, you will be able to:

### Knowledge
- [ ] Explain how Azure Load Balancer works at Layer 4
- [ ] Differentiate between Public, Internal, and Gateway LBs
- [ ] Understand health probe mechanisms and configurations
- [ ] Explain session persistence strategies
- [ ] Describe SNAT and outbound connectivity
- [ ] Compare Load Balancer with Application Gateway and Traffic Manager

### Skills
- [ ] Deploy Load Balancer using Azure CLI
- [ ] Create and configure health probes
- [ ] Set up load balancing rules
- [ ] Configure outbound rules
- [ ] Deploy via ARM templates
- [ ] Deploy via Bicep
- [ ] Deploy via Terraform
- [ ] Monitor and troubleshoot issues

### Application
- [ ] Design high-availability architectures
- [ ] Implement multi-tier applications
- [ ] Configure for different use cases
- [ ] Optimize for performance and cost
- [ ] Troubleshoot common issues
- [ ] Implement security best practices
- [ ] Set up monitoring and alerting

---

## 🔍 Core Concepts Quick Summary

### What is Azure Load Balancer?
Azure Load Balancer is a Layer 4 (Transport layer) service that distributes incoming network traffic across multiple backend resources to ensure high availability, scalability, and reliability.

### Key Characteristics
- **Layer**: 4 (TCP/UDP)
- **Throughput**: Up to 8 million packets/second
- **Connections**: Up to 1 million concurrent connections
- **SLA**: 99.99% (Standard SKU)
- **Cost**: Starting at $0.25/rule/month
- **Scope**: Regional (not global)

### When to Use
✓ Simple TCP/UDP traffic distribution  
✓ High throughput requirements  
✓ Non-HTTP protocols (IoT, gaming)  
✓ Cost-sensitive scenarios  

### When to Use Alternatives
✗ Need Layer 7 routing (use Application Gateway)  
✗ Need global distribution (use Traffic Manager)  
✗ Need advanced features like WAF (use Application Gateway)  

---

## 📊 Architecture Decision Tree

```
Need Load Balancing?
│
├─ Layer 7 routing needed (URL path, hostname)?
│  └─ YES → Use Application Gateway
│
├─ Global (multi-region) distribution?
│  └─ YES → Use Traffic Manager
│
├─ High throughput, simple TCP/UDP?
│  └─ YES → Use Load Balancer ✓
│
├─ Non-HTTP protocol (gaming, IoT)?
│  └─ YES → Use Load Balancer ✓
│
├─ Cost is a major factor?
│  └─ YES → Use Load Balancer ✓
│
└─ Internal service communication?
   └─ YES → Use Internal Load Balancer ✓
```

---

## 🛠️ Tools & Technologies

### Deployment Options
- **Azure CLI** - Command-line interface
- **Azure Portal** - GUI-based
- **ARM Templates** - JSON-based IaC
- **Bicep** - Modern IaC language
- **Terraform** - Open-source IaC
- **PowerShell** - Scripting automation
- **Python SDK** - Programmatic deployment

### Monitoring & Management
- **Azure Monitor** - Metrics and alerts
- **Log Analytics** - Query and analyze logs
- **Application Insights** - Application monitoring
- **Network Watcher** - Network diagnostics

---

## 💡 Pro Tips & Tricks

### Performance
- Use connection pooling to improve throughput 10x
- Configure explicit outbound rules to prevent SNAT exhaustion
- Enable TCP reset for faster connection cleanup
- Tune idle timeout based on application type

### Cost Optimization
- Use private load balancers when possible (saves $3/month per IP)
- Consolidate rules to reduce per-rule charges
- Use smaller VM sizes with auto-scaling
- Monitor data transfer to avoid excess charges

### Security
- Restrict NSG rules to minimum required ports
- Use DDoS Protection Standard for public IPs
- Implement WAF via Application Gateway if needed
- Monitor and log all access

### Reliability
- Always use 3+ backends for redundancy
- Distribute across availability zones
- Implement proper health checks
- Regular failover testing
- Monitor probe failures

---

## 🐛 Common Mistakes to Avoid

1. **Not validating health check endpoint** - Ensure it actually checks service health
2. **Too aggressive health checks** - Can cause unnecessary flapping
3. **Ignoring SNAT port exhaustion** - Results in connection failures
4. **Never testing failover** - Unknown behavior during actual failure
5. **Misunderstanding session persistence** - Mobile users with changing IPs lose session
6. **Using Basic SKU in production** - No SLA guarantee
7. **Not distributing across zones** - Single zone failure takes down service
8. **Implicit SNAT for scale** - Unreliable, use explicit outbound rules

---

## 📞 Getting Help

### Resources
- [Azure Load Balancer Documentation](https://docs.microsoft.com/azure/load-balancer/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure Pricing](https://azure.microsoft.com/pricing/details/load-balancer/)
- [Health Probe Documentation](https://docs.microsoft.com/azure/load-balancer/load-balancer-custom-probe-overview)

### Troubleshooting
- See **05-QUICK-REFERENCE-TROUBLESHOOTING.md** for common issues
- Check Azure Portal diagnostic logs
- Review health probe status in real-time
- Monitor backend pool membership changes
- Enable NSG flow logs for network debugging

---

## 📝 Document Maintenance

This guide was created on **October 25, 2025** and covers:
- Azure Load Balancer latest features
- Current pricing (as of Q4 2024)
- Best practices from production deployments
- Real-world scenarios and use cases

**Note**: Azure services are continuously updated. Check [official documentation](https://docs.microsoft.com/azure/load-balancer/) for the latest features.

---

## 🎓 Certification Preparation

This guide covers topics for:
- **AZ-104** - Azure Administrator
- **AZ-305** - Azure Solutions Architect Expert
- **AZ-900** - Azure Fundamentals

Use this guide to supplement official Microsoft Learn modules.

---

## 📈 Learning Path Recommendation

```
Week 1: Theory
├─ 01-THEORY.md (Days 1-2)
└─ 04-USE-CASES-BEST-PRACTICES.md (Days 3-4)

Week 2: Hands-On
├─ 02-PRACTICAL-STEPS.md (Days 1-2)
└─ 03-CODE-SNIPPETS.md (Days 3-4)

Week 3: Advanced
├─ 06-CONFIGURATION-EXAMPLES.md (Days 1-2)
├─ 05-QUICK-REFERENCE-TROUBLESHOOTING.md (Day 3)
└─ Mini-projects (Day 4)

Week 4: Projects & Practice
├─ Build multi-tier application
├─ Implement HA setup
├─ Troubleshoot scenarios
└─ Performance tuning
```

---

## 🎯 Project Ideas

1. **E-Commerce Platform**
   - Multi-tier architecture with public web tier and private API/DB tiers
   - Session persistence for shopping cart
   - Auto-scaling based on traffic

2. **Real-Time Chat Application**
   - WebSocket-based communication
   - UDP for voice/video
   - Failover testing

3. **IoT Data Collection**
   - High throughput requirements
   - MQTT protocol support
   - Massive concurrent connections

4. **Gaming Backend**
   - UDP load balancing
   - Low latency requirements
   - Connection persistence

5. **Enterprise Application**
   - Multi-region setup
   - DDoS protection
   - Comprehensive monitoring

---

## ✅ Verification Checklist

After completing this guide, verify you can:

### Theory
- [ ] Explain OSI Layer 4 load balancing
- [ ] Describe health probe operation
- [ ] Explain SNAT mechanism
- [ ] Compare LB SKUs and types

### Practical
- [ ] Deploy LB via CLI in 5 minutes
- [ ] Deploy via ARM/Bicep/Terraform
- [ ] Configure health probes correctly
- [ ] Set up monitoring and alerts

### Troubleshooting
- [ ] Diagnose unhealthy backend
- [ ] Fix SNAT exhaustion
- [ ] Resolve uneven distribution
- [ ] Optimize performance

---

## 📞 Questions & Feedback

If you have questions or suggestions for improving this guide:
1. Review the relevant documentation section
2. Check **05-QUICK-REFERENCE-TROUBLESHOOTING.md**
3. Reference the troubleshooting decision tree
4. Consult official Azure documentation

---

## 📄 Document Index

| # | Document | Pages | Topics |
|---|----------|-------|--------|
| 1 | 01-THEORY.md | 50+ | Concepts, architecture, types, SKUs, pricing |
| 2 | 02-PRACTICAL-STEPS.md | 40+ | CLI setup, step-by-step deployment, scripts |
| 3 | 03-CODE-SNIPPETS.md | 60+ | ARM, Bicep, PowerShell, Python, Terraform |
| 4 | 04-USE-CASES-BEST-PRACTICES.md | 70+ | 6 use cases, best practices, performance |
| 5 | 05-QUICK-REFERENCE-TROUBLESHOOTING.md | 50+ | CLI commands, troubleshooting, checklists |
| 6 | 06-CONFIGURATION-EXAMPLES.md | 40+ | 4 complete configurations with scripts |
| 7 | README.md | This file | Guide overview, learning paths |

**Total**: 310+ pages of comprehensive Azure Load Balancer knowledge!

---

## 🏆 Success Criteria

You've successfully mastered Azure Load Balancer when you can:

1. **Explain** how it works at Layer 4
2. **Deploy** a load balancer in multiple ways
3. **Configure** for your specific use case
4. **Monitor** and troubleshoot issues
5. **Optimize** for performance and cost
6. **Secure** following best practices
7. **Test** failover scenarios
8. **Design** HA architectures

---

## 📚 Additional Resources

### Microsoft Documentation
- [Azure Load Balancer Overview](https://docs.microsoft.com/azure/load-balancer/load-balancer-overview)
- [Azure Load Balancer SKUs](https://docs.microsoft.com/azure/load-balancer/skus)
- [Health Probes](https://docs.microsoft.com/azure/load-balancer/load-balancer-custom-probe-overview)
- [Troubleshooting Guide](https://docs.microsoft.com/azure/load-balancer/troubleshoot-load-balancer-imbalance)

### Related Services
- [Application Gateway](https://docs.microsoft.com/azure/application-gateway/) - Layer 7 LB
- [Traffic Manager](https://docs.microsoft.com/azure/traffic-manager/) - Global routing
- [Azure Firewall](https://docs.microsoft.com/azure/firewall/) - Network security
- [DDoS Protection](https://docs.microsoft.com/azure/ddos-protection/) - Security

---

## 🎬 Getting Started Now

**Pick your entry point:**

👨‍💼 **Business Decision Maker**
→ Start with: Theory overview, Cost analysis

👨‍💻 **Developer**
→ Start with: Code Snippets, Practical Steps

🏗️ **Solutions Architect**
→ Start with: Use Cases, Best Practices

🔧 **Operations/SRE**
→ Start with: Troubleshooting, Monitoring

---

**Happy Learning! 🚀**

For questions or updates, refer to the official [Azure documentation](https://docs.microsoft.com/azure/load-balancer/).

