# Azure Load Balancer - Complete Configuration Examples

## Example 1: Web Application Configuration

### Configuration Summary
- **Type**: Public Load Balancer
- **Use Case**: Enterprise web application (5000+ concurrent users)
- **Backends**: 3 web servers with auto-scaling
- **Health Check**: HTTP endpoint
- **Availability**: Zone-redundant

### Complete CLI Script

```bash
#!/bin/bash

# ============================================================================
# Azure Load Balancer - Web Application Setup
# ============================================================================

# Configuration Variables
RESOURCE_GROUP="web-app-rg"
LOCATION="eastus"
VNET_NAME="web-app-vnet"
SUBNET_NAME="web-subnet"
LB_NAME="web-app-lb"
NSG_NAME="web-nsg"
PUBLIC_IP_NAME="web-app-pip"
FRONTEND_NAME="web-frontend"
BACKEND_POOL_NAME="web-backend"
PROBE_NAME="web-health-probe"
RULE_HTTP_NAME="web-http-rule"
RULE_HTTPS_NAME="web-https-rule"
OUTBOUND_RULE_NAME="web-outbound"
OUTBOUND_IP_NAME="web-outbound-pip"

echo "Starting Web Application Load Balancer Setup..."
echo "==============================================="

# Step 1: Create Resource Group
echo "1. Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Step 2: Create Network Security Group with rules
echo "2. Creating Network Security Group..."
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $NSG_NAME

# Allow HTTP from internet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowHTTP \
  --priority 100 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80 \
  --access Allow \
  --protocol Tcp

# Allow HTTPS from internet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowHTTPS \
  --priority 101 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 443 \
  --access Allow \
  --protocol Tcp

# Allow SSH for management
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowSSH \
  --priority 102 \
  --source-address-prefixes '203.0.113.0/24' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp

# Step 3: Create Virtual Network
echo "3. Creating Virtual Network..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/24 \
  --network-security-group $NSG_NAME

# Step 4: Create Public IP (Zone-redundant)
echo "4. Creating Public IP..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $PUBLIC_IP_NAME \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# Get the public IP address
PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name $PUBLIC_IP_NAME \
  --query ipAddress -o tsv)

echo "   Public IP Address: $PUBLIC_IP"

# Step 5: Create Public IP for Outbound
echo "5. Creating Outbound Public IP..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $OUTBOUND_IP_NAME \
  --sku Standard \
  --allocation-method Static

# Step 6: Create Load Balancer
echo "6. Creating Load Balancer..."
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_NAME \
  --sku Standard \
  --public-ip-address $PUBLIC_IP_NAME \
  --frontend-ip-name $FRONTEND_NAME \
  --backend-pool-name $BACKEND_POOL_NAME

# Step 7: Create Health Probe (HTTP)
echo "7. Creating Health Probe..."
az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_NAME \
  --name $PROBE_NAME \
  --protocol http \
  --port 8080 \
  --path /health \
  --interval 15 \
  --threshold 2

# Step 8: Create Load Balancing Rule for HTTP
echo "8. Creating Load Balancing Rules..."
az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_NAME \
  --name $RULE_HTTP_NAME \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080 \
  --frontend-ip-name $FRONTEND_NAME \
  --backend-pool-name $BACKEND_POOL_NAME \
  --probe-name $PROBE_NAME \
  --idle-timeout 30 \
  --load-distribution SourceIP

# Note: For HTTPS, you would use Application Gateway with SSL termination

# Step 9: Create Outbound Rule
echo "9. Creating Outbound Rule..."
az network lb outbound-rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_NAME \
  --name $OUTBOUND_RULE_NAME \
  --frontend-ip-config $FRONTEND_NAME \
  --backend-pool $BACKEND_POOL_NAME \
  --protocol All \
  --outbound-ports 0 \
  --idle-timeout 15 \
  --public-ips $OUTBOUND_IP_NAME

# Step 10: Create Network Interfaces
echo "10. Creating Network Interfaces..."
for i in {1..3}; do
  NIC_NAME="web-nic-$i"
  IP_ADDR="10.0.0.$((i + 3))"
  
  echo "    Creating $NIC_NAME with IP $IP_ADDR"
  
  az network nic create \
    --resource-group $RESOURCE_GROUP \
    --name $NIC_NAME \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_NAME \
    --network-security-group $NSG_NAME \
    --private-ip-address $IP_ADDR \
    --lb-name $LB_NAME \
    --lb-address-pools $BACKEND_POOL_NAME
done

echo ""
echo "==============================================="
echo "Setup Complete!"
echo "==============================================="
echo ""
echo "Load Balancer Details:"
echo "  Name: $LB_NAME"
echo "  Public IP: $PUBLIC_IP"
echo "  Access URL: http://$PUBLIC_IP"
echo "  Backend Pool: $BACKEND_POOL_NAME"
echo "  Health Probe: $PROBE_NAME"
echo ""
echo "Next Steps:"
echo "1. Create or attach VMs to the backend pool"
echo "2. Configure your application on port 8080"
echo "3. Ensure health check endpoint returns 200 OK"
echo "4. Monitor the load balancer in Azure Portal"
```

---

## Example 2: Multi-Tier Application Configuration

### Architecture
```
┌─────────────────────────────────────────┐
│         Internet Traffic                │
└──────────────────┬──────────────────────┘
                   ↓
        ┌──────────────────────┐
        │  Public LB           │
        │  (External IP:80)    │
        └──────────┬───────────┘
                   ↓
        ┌──────────────────────────┐
        │  Web Tier (Nginx)        │
        │  ├─ web-vm-1             │
        │  ├─ web-vm-2             │
        │  └─ web-vm-3             │
        └──────────┬───────────────┘
                   ↓ (Private, 10.0.1.10:8080)
        ┌──────────────────────────┐
        │  API Tier (Node.js)      │
        │  ├─ api-vm-1             │
        │  ├─ api-vm-2             │
        │  └─ api-vm-3             │
        └──────────┬───────────────┘
                   ↓ (Private, 10.0.2.10:5432)
        ┌──────────────────────────┐
        │  Database Tier (SQL)     │
        │  ├─ db-vm-1              │
        │  ├─ db-vm-2              │
        │  └─ db-vm-3              │
        └──────────────────────────┘
```

### Configuration Script

```bash
#!/bin/bash

# Multi-Tier Application Load Balancer Setup

RESOURCE_GROUP="multi-tier-app-rg"
LOCATION="eastus"
VNET_NAME="app-vnet"
LB_PUBLIC_NAME="app-public-lb"
LB_API_NAME="app-api-lb"
LB_DB_NAME="app-db-lb"

echo "Creating Multi-Tier Application Infrastructure..."

# 1. Create VNET with multiple subnets
echo "1. Creating Virtual Network..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16

# 2. Create subnets for each tier
echo "2. Creating Subnets..."
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name web-subnet \
  --address-prefix 10.0.0.0/24

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name api-subnet \
  --address-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name db-subnet \
  --address-prefix 10.0.2.0/24

# 3. Create NSGs for each tier
echo "3. Creating Network Security Groups..."

# Web tier NSG
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name web-nsg

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name web-nsg \
  --name AllowHTTP \
  --priority 100 \
  --destination-port-ranges 80 443 \
  --access Allow

# API tier NSG
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name api-nsg

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name api-nsg \
  --name AllowFromWeb \
  --priority 100 \
  --source-address-prefixes 10.0.0.0/24 \
  --destination-port-ranges 8080 \
  --access Allow

# DB tier NSG
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name db-nsg

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name db-nsg \
  --name AllowFromAPI \
  --priority 100 \
  --source-address-prefixes 10.0.1.0/24 \
  --destination-port-ranges 5432 \
  --access Allow

# 4. Associate NSGs with subnets
echo "4. Associating NSGs with Subnets..."
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name web-subnet \
  --network-security-group web-nsg

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name api-subnet \
  --network-security-group api-nsg

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name db-subnet \
  --network-security-group db-nsg

# 5. Create Public LB for web tier
echo "5. Creating Public Load Balancer..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name app-public-pip \
  --sku Standard

az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_PUBLIC_NAME \
  --sku Standard \
  --public-ip-address app-public-pip \
  --frontend-ip-name web-frontend \
  --backend-pool-name web-backend

az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_PUBLIC_NAME \
  --name web-health \
  --protocol http \
  --port 8080 \
  --path /health

az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_PUBLIC_NAME \
  --name web-rule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080 \
  --frontend-ip-name web-frontend \
  --backend-pool-name web-backend \
  --probe-name web-health

# 6. Create Internal LB for API tier
echo "6. Creating Internal Load Balancer for API..."
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_API_NAME \
  --sku Standard \
  --vnet-name $VNET_NAME \
  --subnet api-subnet \
  --frontend-ip-name api-frontend \
  --backend-pool-name api-backend \
  --private-ip-address 10.0.1.10

az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_API_NAME \
  --name api-health \
  --protocol http \
  --port 8080 \
  --path /health

az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_API_NAME \
  --name api-rule \
  --protocol tcp \
  --frontend-port 8080 \
  --backend-port 8080 \
  --frontend-ip-name api-frontend \
  --backend-pool-name api-backend \
  --probe-name api-health

# 7. Create Internal LB for Database tier
echo "7. Creating Internal Load Balancer for Database..."
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_DB_NAME \
  --sku Standard \
  --vnet-name $VNET_NAME \
  --subnet db-subnet \
  --frontend-ip-name db-frontend \
  --backend-pool-name db-backend \
  --private-ip-address 10.0.2.10

az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_DB_NAME \
  --name db-health \
  --protocol tcp \
  --port 5432

az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_DB_NAME \
  --name db-rule \
  --protocol tcp \
  --frontend-port 5432 \
  --backend-port 5432 \
  --frontend-ip-name db-frontend \
  --backend-pool-name db-backend \
  --probe-name db-health

echo ""
echo "Multi-tier infrastructure created successfully!"
echo ""
echo "Configuration Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  VNET: $VNET_NAME"
echo "  Public LB: $LB_PUBLIC_NAME (External: 80)"
echo "  API LB: $LB_API_NAME (Internal: 10.0.1.10:8080)"
echo "  DB LB: $LB_DB_NAME (Internal: 10.0.2.10:5432)"
```

---

## Example 3: High-Availability Gaming Service

### Configuration

```bash
#!/bin/bash

# Gaming Service Load Balancer (UDP-based)

RESOURCE_GROUP="game-service-rg"
LOCATION="eastus"
LB_NAME="game-server-lb"

echo "Setting up Gaming Service Infrastructure..."

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create VNET
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name game-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name game-subnet \
  --subnet-prefix 10.0.0.0/24

# Create Public IP (Zone-redundant)
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name game-pip \
  --sku Standard \
  --zone 1 2 3

# Create Load Balancer
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_NAME \
  --sku Standard \
  --public-ip-address game-pip \
  --frontend-ip-name game-frontend \
  --backend-pool-name game-backend

# Create TCP probe for game server status
az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_NAME \
  --name game-probe \
  --protocol tcp \
  --port 27015 \
  --interval 5 \
  --threshold 1

# Create UDP load balancing rule (game traffic)
az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LB_NAME \
  --name game-udp-rule \
  --protocol udp \
  --frontend-port 27015 \
  --backend-port 27015 \
  --frontend-ip-name game-frontend \
  --backend-pool-name game-backend \
  --probe-name game-probe \
  --idle-timeout 4 \
  --load-distribution SourceIP

# Get Public IP
PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name game-pip \
  --query ipAddress -o tsv)

echo "Gaming Service Setup Complete!"
echo "Public IP: $PUBLIC_IP:27015"
```

---

## Example 4: Monitoring & Alerts Configuration

```bash
#!/bin/bash

# Enable comprehensive monitoring

RESOURCE_GROUP="app-rg"
LB_NAME="app-lb"
WORKSPACE_NAME="app-analytics"

# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME

WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE_NAME \
  --query id -o tsv)

# Get Load Balancer Resource ID
LB_ID=$(az network lb show \
  --resource-group $RESOURCE_GROUP \
  --name $LB_NAME \
  --query id -o tsv)

# Enable Diagnostics
az monitor diagnostic-settings create \
  --name lb-diagnostics \
  --resource $LB_ID \
  --logs '[
    {
      "category": "LoadBalancerAlertEvent",
      "enabled": true
    },
    {
      "category": "LoadBalancerProbeHealthStatus",
      "enabled": true
    }
  ]' \
  --metrics '[
    {
      "category": "AllMetrics",
      "enabled": true,
      "retentionPolicy": {
        "enabled": true,
        "days": 30
      }
    }
  ]' \
  --workspace $WORKSPACE_ID

# Create alerts
az monitor metrics alert create \
  --name "LB-HealthProbeFailure" \
  --resource-group $RESOURCE_GROUP \
  --scopes $LB_ID \
  --condition "avg HealthProbeStatus < 0.5" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2

az monitor metrics alert create \
  --name "LB-SNATExhaustion" \
  --resource-group $RESOURCE_GROUP \
  --scopes $LB_ID \
  --condition "total FailedSNATConnections > 100" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1

echo "Monitoring and alerts configured!"
```

---

## Important Configuration Parameters Reference

| Parameter | Default | Recommended | Notes |
|-----------|---------|-------------|-------|
| **Health Probe Interval** | 15s | 15s | Good balance between responsiveness and overhead |
| **Probe Threshold** | 2 | 2 | Prevents flapping, tolerates temporary glitches |
| **Idle Timeout** | 4 min | 4-30 min | Depends on application (web=4, streaming=30) |
| **Backend Pool Size** | 1+ | 3+ | Minimum 2 for HA, 3+ recommended |
| **Frontend Port** | 1-65535 | 80, 443 | Use standard ports for clarity |
| **Load Distribution** | Default | SourceIP | SourceIP for stateful, Default for stateless |
| **Outbound Port Allocation** | Auto | 0 (auto) | 0 means automatic allocation |

---

## Deployment Checklist

```markdown
Pre-Deployment
□ Plan resource naming convention
□ Define IP addressing scheme
□ Design NSG rules for security
□ Plan backend pool composition
□ Define health check requirements
□ Plan monitoring and alerts

During Deployment
□ Create resource group
□ Create VNET and subnets
□ Create NSGs and rules
□ Create public IPs
□ Create load balancer
□ Configure probes
□ Create rules
□ Create outbound rules
□ Add backends to pool

Post-Deployment
□ Verify health probes
□ Test traffic distribution
□ Monitor for errors
□ Configure alerts
□ Document configuration
□ Run load tests
□ Test failover scenarios

