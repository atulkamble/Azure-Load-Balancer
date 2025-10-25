# Azure Load Balancer - Practical Implementation Guide

## Part 1: Step-by-Step Implementation

### Prerequisites
- Azure Subscription
- Azure CLI installed
- At least 2 Virtual Machines in same VNET
- Basic networking knowledge

---

## Step 1: Create Resource Group

### Using Azure CLI
```bash
# Set variables
RESOURCE_GROUP="myResourceGroup"
LOCATION="eastus"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### Using Azure Portal
1. Click "Create a resource" → Search "Resource Group"
2. Enter resource group name and location
3. Click "Review + Create" → "Create"

---

## Step 2: Create Virtual Network and Subnet

### Using Azure CLI
```bash
# Create VNET
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefix 10.0.0.0/24

# Output: Will show VNET details including subnet ID
```

### Expected Output
```json
{
  "newVNet": {
    "name": "myVNet",
    "subnets": [
      {
        "name": "mySubnet",
        "addressPrefix": "10.0.0.0/24"
      }
    ]
  }
}
```

---

## Step 3: Create Network Security Group (NSG)

### Using Azure CLI
```bash
# Create NSG
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name myNetworkSecurityGroup

# Add inbound rule for HTTP
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name myNetworkSecurityGroup \
  --name Allow-HTTP \
  --priority 100 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80 \
  --access Allow \
  --protocol Tcp

# Add inbound rule for custom app (port 8080)
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name myNetworkSecurityGroup \
  --name Allow-AppPort \
  --priority 110 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 8080 \
  --access Allow \
  --protocol Tcp
```

---

## Step 4: Create Network Interfaces

### Using Azure CLI
```bash
# Create first NIC
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name myNIC1 \
  --vnet-name myVNet \
  --subnet mySubnet \
  --network-security-group myNetworkSecurityGroup \
  --private-ip-address 10.0.0.4

# Create second NIC
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name myNIC2 \
  --vnet-name myVNet \
  --subnet mySubnet \
  --network-security-group myNetworkSecurityGroup \
  --private-ip-address 10.0.0.5

# Create third NIC
az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name myNIC3 \
  --vnet-name myVNet \
  --subnet mySubnet \
  --network-security-group myNetworkSecurityGroup \
  --private-ip-address 10.0.0.6
```

---

## Step 5: Create Virtual Machines

### Using Azure CLI
```bash
# Create first VM
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name myVM1 \
  --nics myNIC1 \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data <(cat <<EOF
#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask
cat > /home/azureuser/app.py << 'PYEOF'
from flask import Flask
import socket
app = Flask(__name__)

@app.route('/')
def index():
    hostname = socket.gethostname()
    return f'Hello from {hostname}! Server is healthy.\\n'

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF
cd /home/azureuser
python3 app.py
EOF
)

# Create second VM
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name myVM2 \
  --nics myNIC2 \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data <(cat <<EOF
#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask
cat > /home/azureuser/app.py << 'PYEOF'
from flask import Flask
import socket
app = Flask(__name__)

@app.route('/')
def index():
    hostname = socket.gethostname()
    return f'Hello from {hostname}! Server is healthy.\\n'

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF
cd /home/azureuser
python3 app.py
EOF
)

# Create third VM
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name myVM3 \
  --nics myNIC3 \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data <(cat <<EOF
#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask
cat > /home/azureuser/app.py << 'PYEOF'
from flask import Flask
import socket
app = Flask(__name__)

@app.route('/')
def index():
    hostname = socket.gethostname()
    return f'Hello from {hostname}! Server is healthy.\\n'

@app.route('/health')
def health():
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF
cd /home/azureuser
python3 app.py
EOF
)
```

---

## Step 6: Create Public Load Balancer

### Using Azure CLI
```bash
# Create public IP for load balancer
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name myPublicIP \
  --sku Standard \
  --allocation-method Static \
  --zone 1 2 3

# Get the public IP address
PUBLICIP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name myPublicIP \
  --query ipAddress -o tsv)

echo "Public IP: $PUBLICIP"

# Create load balancer
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name myLoadBalancer \
  --sku Standard \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontendIP \
  --backend-pool-name myBackendPool
```

### Output Example
```
Public IP: 20.245.123.45
```

---

## Step 7: Create Health Probe

### Using Azure CLI
```bash
# Create HTTP health probe
az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myHealthProbe \
  --protocol http \
  --port 8080 \
  --path /health \
  --interval 15 \
  --threshold 2

# Verify probe creation
az network lb probe show \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myHealthProbe
```

### Probe Configuration Details
```json
{
  "id": "/subscriptions/.../providers/Microsoft.Network/loadBalancers/myLoadBalancer/probes/myHealthProbe",
  "intervalInSeconds": 15,
  "name": "myHealthProbe",
  "numberOfProbes": 2,
  "port": 8080,
  "protocol": "Http",
  "requestPath": "/health",
  "type": "Microsoft.Network/loadBalancers/probes"
}
```

---

## Step 8: Create Backend Pool and Add VMs

### Using Azure CLI
```bash
# Get network interface IDs
NIC1_ID=$(az network nic show \
  --resource-group $RESOURCE_GROUP \
  --name myNIC1 \
  --query id -o tsv)

NIC2_ID=$(az network nic show \
  --resource-group $RESOURCE_GROUP \
  --name myNIC2 \
  --query id -o tsv)

NIC3_ID=$(az network nic show \
  --resource-group $RESOURCE_GROUP \
  --name myNIC3 \
  --query id -o tsv)

# Add NICs to backend pool
az network nic ip-config address-pool add \
  --resource-group $RESOURCE_GROUP \
  --nic-name myNIC1 \
  --ip-config-name ipconfig1 \
  --lb-name myLoadBalancer \
  --address-pool myBackendPool

az network nic ip-config address-pool add \
  --resource-group $RESOURCE_GROUP \
  --nic-name myNIC2 \
  --ip-config-name ipconfig1 \
  --lb-name myLoadBalancer \
  --address-pool myBackendPool

az network nic ip-config address-pool add \
  --resource-group $RESOURCE_GROUP \
  --nic-name myNIC3 \
  --ip-config-name ipconfig1 \
  --lb-name myLoadBalancer \
  --address-pool myBackendPool

# Verify backend pool
az network lb address-pool show \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myBackendPool
```

---

## Step 9: Create Load Balancing Rule

### Using Azure CLI
```bash
# Create load balancing rule
az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myLBRule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080 \
  --frontend-ip-name myFrontendIP \
  --backend-pool-name myBackendPool \
  --probe-name myHealthProbe \
  --idle-timeout 15 \
  --enable-floating-ip false \
  --load-distribution SourceIP

# Verify rule
az network lb rule show \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myLBRule
```

### Load Balancing Rule Details
```json
{
  "name": "myLBRule",
  "protocol": "Tcp",
  "frontendPort": 80,
  "backendPort": 8080,
  "idleTimeoutInMinutes": 15,
  "loadDistribution": "SourceIP",
  "enableFloatingIP": false,
  "enableTcpReset": false,
  "probeId": "/subscriptions/.../probes/myHealthProbe"
}
```

---

## Step 10: Test the Load Balancer

### Using Azure CLI - Get Public IP
```bash
# Get the public IP
PUBLICIP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name myPublicIP \
  --query ipAddress -o tsv)

echo "Access your app at: http://$PUBLICIP"
```

### Using curl to Test
```bash
# Test the load balancer multiple times
for i in {1..10}; do
  echo "Request $i:"
  curl -v http://$PUBLICIP
  echo -e "\n---\n"
  sleep 1
done
```

### Expected Output
```
Request 1:
Hello from myVM1! Server is healthy.
---

Request 2:
Hello from myVM2! Server is healthy.
---

Request 3:
Hello from myVM3! Server is healthy.
---
```

---

## Step 11: Monitor Health Probes

### Using Azure CLI
```bash
# Check health probe status
az network lb show \
  --resource-group $RESOURCE_GROUP \
  --name myLoadBalancer \
  --query "backendAddressPools[].backendIpConfigurations[].id" -o json

# Enable diagnostics logging
az monitor diagnostic-settings create \
  --resource /subscriptions/{subscriptionId}/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/loadBalancers/myLoadBalancer \
  --name myLBDiagnostics \
  --logs '[{"category": "LoadBalancerAlertEvent", "enabled": true}, {"category": "LoadBalancerProbeHealthStatus", "enabled": true}]' \
  --workspace /subscriptions/{subscriptionId}/resourceGroups/$RESOURCE_GROUP/providers/microsoft.operationalinsights/workspaces/myWorkspace
```

---

## Step 12: Create Outbound Rules (Optional)

### Using Azure CLI
```bash
# Create public IP for outbound traffic
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name myOutboundPublicIP \
  --sku Standard \
  --allocation-method Static

# Create outbound rule
az network lb outbound-rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name myLoadBalancer \
  --name myOutboundRule \
  --frontend-ip-config myFrontendIP \
  --backend-pool myBackendPool \
  --protocol All \
  --outbound-ports 0 \
  --idle-timeout 15 \
  --public-ips myOutboundPublicIP
```

---

## Step 13: Create Internal Load Balancer (Optional)

### Use Case: Multi-tier application with internal communication

### Using Azure CLI
```bash
# Create second subnet for backend tier
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name myVNet \
  --name backendSubnet \
  --address-prefix 10.0.1.0/24

# Create internal load balancer (no public IP)
az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name myInternalLB \
  --sku Standard \
  --vnet-name myVNet \
  --subnet backendSubnet \
  --frontend-ip-name myInternalFrontendIP \
  --backend-pool-name myInternalBackendPool \
  --private-ip-address 10.0.1.10

# Remaining configuration same as public LB (probe, rules, etc.)
```

---

## Step 14: Clean Up Resources

### Using Azure CLI
```bash
# Delete entire resource group (deletes all resources)
az group delete \
  --name $RESOURCE_GROUP \
  --yes

# Or delete individual resources
# Delete load balancer
az network lb delete \
  --resource-group $RESOURCE_GROUP \
  --name myLoadBalancer

# Delete VMs
az vm delete \
  --resource-group $RESOURCE_GROUP \
  --name myVM1 \
  --yes

az vm delete \
  --resource-group $RESOURCE_GROUP \
  --name myVM2 \
  --yes

az vm delete \
  --resource-group $RESOURCE_GROUP \
  --name myVM3 \
  --yes
```

---

## Complete Setup Script

Save as `setup-lb.sh` and run:

```bash
#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="myResourceGroup"
LOCATION="eastus"
VNET_NAME="myVNet"
SUBNET_NAME="mySubnet"
LB_NAME="myLoadBalancer"
NSG_NAME="myNetworkSecurityGroup"

echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "Creating VNET and subnet..."
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/24

echo "Creating NSG..."
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $NSG_NAME

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name Allow-HTTP \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-port-ranges 80 \
  --access Allow \
  --protocol Tcp

echo "Creating load balancer..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name myPublicIP \
  --sku Standard

az network lb create \
  --resource-group $RESOURCE_GROUP \
  --name $LB_NAME \
  --sku Standard \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontendIP \
  --backend-pool-name myBackendPool

echo "Setup completed successfully!"
```

Run the script:
```bash
chmod +x setup-lb.sh
./setup-lb.sh
```

