# Azure Load Balancer - Code Snippets & Examples

## 1. ARM Template - Complete Load Balancer Setup

### File: `load-balancer-template.json`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for resources"
      }
    },
    "vmCount": {
      "type": "int",
      "defaultValue": 3,
      "metadata": {
        "description": "Number of VMs in backend pool"
      }
    }
  },
  "variables": {
    "vnetName": "myVNet",
    "subnetName": "mySubnet",
    "lbName": "myLoadBalancer",
    "publicIPName": "myPublicIP",
    "nsgName": "myNSG",
    "vmNamePrefix": "vm"
  },
  "resources": [
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2021-02-01",
      "name": "[variables('nsgName')]",
      "location": "[parameters('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "AllowHTTP",
            "properties": {
              "description": "Allow HTTP traffic",
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            }
          },
          {
            "name": "AllowAppPort",
            "properties": {
              "description": "Allow app traffic on port 8080",
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "8080",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 110,
              "direction": "Inbound"
            }
          },
          {
            "name": "AllowSSH",
            "properties": {
              "description": "Allow SSH traffic",
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "22",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 120,
              "direction": "Inbound"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2021-02-01",
      "name": "[variables('vnetName')]",
      "location": "[parameters('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "10.0.0.0/16"
          ]
        },
        "subnets": [
          {
            "name": "[variables('subnetName')]",
            "properties": {
              "addressPrefix": "10.0.0.0/24",
              "networkSecurityGroup": {
                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]"
              }
            }
          }
        ]
      },
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]"
      ]
    },
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2021-02-01",
      "name": "[variables('publicIPName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "publicIPAllocationMethod": "Static",
        "publicIPAddressVersion": "IPv4"
      }
    },
    {
      "type": "Microsoft.Network/loadBalancers",
      "apiVersion": "2021-02-01",
      "name": "[variables('lbName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "frontendIPConfigurations": [
          {
            "name": "myFrontendIP",
            "properties": {
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPName'))]"
              }
            }
          }
        ],
        "backendAddressPools": [
          {
            "name": "myBackendPool"
          }
        ],
        "loadBalancingRules": [
          {
            "name": "myLBRule",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('lbName')), '/frontendIPConfigurations/myFrontendIP')]"
              },
              "backendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('lbName')), '/backendAddressPools/myBackendPool')]"
              },
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', variables('lbName')), '/probes/myHealthProbe')]"
              },
              "protocol": "Tcp",
              "frontendPort": 80,
              "backendPort": 8080,
              "idleTimeoutInMinutes": 15,
              "loadDistribution": "SourceIP"
            }
          }
        ],
        "probes": [
          {
            "name": "myHealthProbe",
            "properties": {
              "protocol": "Http",
              "port": 8080,
              "requestPath": "/health",
              "intervalInSeconds": 15,
              "numberOfProbes": 2
            }
          }
        ]
      },
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPName'))]"
      ]
    }
  ],
  "outputs": {
    "loadBalancerPublicIP": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPName'))).ipAddress]"
    }
  }
}
```

### Deploy Template
```bash
# Deploy the template
az deployment group create \
  --resource-group myResourceGroup \
  --template-file load-balancer-template.json \
  --parameters location=eastus vmCount=3
```

---

## 2. Bicep - Infrastructure as Code

### File: `load-balancer.bicep`

```bicep
param location string = resourceGroup().location
param environment string = 'prod'
param vmCount int = 3
param vmSize string = 'Standard_B2s'

// Variable definitions
var uniqueSuffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${environment}-${uniqueSuffix}'
var lbName = 'lb-${environment}-${uniqueSuffix}'
var nsgName = 'nsg-${environment}-${uniqueSuffix}'
var publicIPName = 'pip-lb-${environment}-${uniqueSuffix}'
var subnetName = 'subnet-backend'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAppPort'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Public IP for Load Balancer
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Load Balancer
resource loadBalancer 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontendIP'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'httpRule'
        properties: {
          frontendIPConfiguration: {
            id: '${loadBalancer.id}/frontendIPConfigurations/frontendIP'
          }
          backendAddressPool: {
            id: '${loadBalancer.id}/backendAddressPools/backendPool'
          }
          probe: {
            id: '${loadBalancer.id}/probes/healthProbe'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 8080
          idleTimeoutInMinutes: 15
          loadDistribution: 'SourceIP'
        }
      }
    ]
    probes: [
      {
        name: 'healthProbe'
        properties: {
          protocol: 'Http'
          port: 8080
          requestPath: '/health'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}

// Output
output loadBalancerPublicIP string = publicIP.properties.ipAddress
output loadBalancerId string = loadBalancer.id
```

### Deploy Bicep
```bash
# Compile and deploy Bicep template
az deployment group create \
  --resource-group myResourceGroup \
  --template-file load-balancer.bicep \
  --parameters environment=prod vmCount=3
```

---

## 3. PowerShell - Automated Load Balancer Setup

### File: `Setup-LoadBalancer.ps1`

```powershell
<#
.SYNOPSIS
    Creates and configures an Azure Load Balancer with VMs

.DESCRIPTION
    This script creates a complete load balancer setup with:
    - Resource Group
    - Virtual Network and Subnet
    - Network Security Group
    - Load Balancer with health probes
    - Backend VMs

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER Location
    Azure location for resources

.PARAMETER VMCount
    Number of VMs to create (default: 3)

.EXAMPLE
    .\Setup-LoadBalancer.ps1 -ResourceGroupName "myRG" -Location "eastus" -VMCount 3
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [int]$VMCount = 3
)

# Error handling
$ErrorActionPreference = "Stop"

# Variables
$VNetName = "myVNet"
$SubnetName = "mySubnet"
$NSGName = "myNSG"
$LBName = "myLoadBalancer"
$PublicIPName = "myPublicIP"
$BackendPoolName = "myBackendPool"
$ProbeName = "myHealthProbe"
$RuleName = "myLBRule"

Write-Host "Starting Load Balancer setup..." -ForegroundColor Green

# Step 1: Create Resource Group
Write-Host "Creating resource group: $ResourceGroupName"
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Step 2: Create Network Security Group
Write-Host "Creating Network Security Group: $NSGName"
$nsgRules = @(
    (New-AzNetworkSecurityRuleConfig -Name "AllowHTTP" -Description "Allow HTTP" `
        -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
        -SourceAddressPrefix * -SourcePortRange * `
        -DestinationAddressPrefix * -DestinationPortRange 80),

    (New-AzNetworkSecurityRuleConfig -Name "AllowAppPort" -Description "Allow app port 8080" `
        -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
        -SourceAddressPrefix * -SourcePortRange * `
        -DestinationAddressPrefix * -DestinationPortRange 8080),

    (New-AzNetworkSecurityRuleConfig -Name "AllowSSH" -Description "Allow SSH" `
        -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
        -SourceAddressPrefix * -SourcePortRange * `
        -DestinationAddressPrefix * -DestinationPortRange 22)
)

$nsg = New-AzNetworkSecurityGroup -Name $NSGName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -SecurityRules $nsgRules

# Step 3: Create Virtual Network
Write-Host "Creating Virtual Network: $VNetName"
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName `
    -AddressPrefix "10.0.0.0/24" `
    -NetworkSecurityGroup $nsg

$vnet = New-AzVirtualNetwork -Name $VNetName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnetConfig

# Step 4: Create Public IP for Load Balancer
Write-Host "Creating Public IP: $PublicIPName"
$publicIP = New-AzPublicIpAddress -Name $PublicIPName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AllocationMethod Static `
    -Sku Standard

# Step 5: Create Load Balancer
Write-Host "Creating Load Balancer: $LBName"
$frontendIP = New-AzLoadBalancerFrontendIpConfig -Name "myFrontendIP" `
    -PublicIpAddress $publicIP

$backendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $BackendPoolName

$lb = New-AzLoadBalancer -Name $LBName `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Sku Standard `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool

# Step 6: Create Health Probe
Write-Host "Creating Health Probe: $ProbeName"
$probe = Add-AzLoadBalancerProbeConfig -Name $ProbeName `
    -LoadBalancer $lb `
    -Protocol Http `
    -Port 8080 `
    -RequestPath "/health" `
    -IntervalInSeconds 15 `
    -ProbeCount 2

Set-AzLoadBalancer -LoadBalancer $lb

# Step 7: Create Load Balancing Rule
Write-Host "Creating Load Balancing Rule: $RuleName"
$rule = Add-AzLoadBalancerRuleConfig -Name $RuleName `
    -LoadBalancer $lb `
    -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
    -BackendAddressPool $lb.BackendAddressPools[0] `
    -Probe $lb.Probes[0] `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 8080 `
    -IdleTimeoutInMinutes 15 `
    -LoadDistribution SourceIP

Set-AzLoadBalancer -LoadBalancer $lb

# Step 8: Create Network Interfaces and VMs
Write-Host "Creating $VMCount Virtual Machines..."
$vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$subnet = $vnet.Subnets[0]
$lb = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LBName
$backendPool = $lb.BackendAddressPools[0]

for ($i = 1; $i -le $VMCount; $i++) {
    $nicName = "myNIC$i"
    $vmName = "myVM$i"
    $ipAddress = "10.0.0.$($i + 3)"

    Write-Host "Creating NIC: $nicName"
    $nic = New-AzNetworkInterface -Name $nicName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Subnet $subnet `
        -PrivateIpAddress $ipAddress `
        -LoadBalancerBackendAddressPool $backendPool

    Write-Host "Creating VM: $vmName"
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_B2s"
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
        -Linux -ComputerName $vmName `
        -Credential (Get-Credential -UserName azureuser -Message "Enter VM admin credential")
    $vmConfig = Set-AzVMSourceImage -VM $vmConfig `
        -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS" -Version "latest"
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

    New-AzVM -ResourceGroupName $ResourceGroupName `
        -VM $vmConfig -GenerateSshKeysIfMissing
}

# Step 9: Display results
Write-Host "`n" -ForegroundColor Green
Write-Host "Load Balancer setup completed successfully!" -ForegroundColor Green
Write-Host "`nLoad Balancer Details:" -ForegroundColor Yellow
Write-Host "  Name: $LBName"
Write-Host "  Public IP: $($publicIP.IpAddress)"
Write-Host "  Backend Pool: $BackendPoolName"
Write-Host "  VMs created: $VMCount"
Write-Host "`nAccess your application at: http://$($publicIP.IpAddress)" -ForegroundColor Cyan
```

### Run PowerShell Script
```powershell
# Execute the script
.\Setup-LoadBalancer.ps1 -ResourceGroupName "myResourceGroup" -Location "eastus" -VMCount 3
```

---

## 4. Python - Azure SDK Example

### File: `azure_lb_setup.py`

```python
"""
Azure Load Balancer Setup using Azure SDK for Python
Install dependencies: pip install azure-identity azure-mgmt-network azure-mgmt-compute
"""

import os
import sys
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.core.exceptions import AzureError

# Configuration
RESOURCE_GROUP = "myResourceGroup"
LOCATION = "eastus"
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID", "your-subscription-id")

# Resource names
VNET_NAME = "myVNet"
SUBNET_NAME = "mySubnet"
NSG_NAME = "myNSG"
LB_NAME = "myLoadBalancer"
PUBLIC_IP_NAME = "myPublicIP"
BACKEND_POOL_NAME = "myBackendPool"
PROBE_NAME = "myHealthProbe"
RULE_NAME = "myLBRule"
VM_COUNT = 3

class AzureLoadBalancerSetup:
    def __init__(self, subscription_id: str, resource_group: str, location: str):
        self.subscription_id = subscription_id
        self.resource_group = resource_group
        self.location = location

        # Initialize credentials and clients
        credential = DefaultAzureCredential()
        self.network_client = NetworkManagementClient(credential, subscription_id)
        self.compute_client = ComputeManagementClient(credential, subscription_id)

    def create_network_security_group(self) -> dict:
        """Create Network Security Group with inbound rules"""
        print(f"Creating Network Security Group: {NSG_NAME}")

        security_rules = [
            {
                "name": "AllowHTTP",
                "properties": {
                    "protocol": "Tcp",
                    "sourcePortRange": "*",
                    "destinationPortRange": "80",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 100,
                    "direction": "Inbound"
                }
            },
            {
                "name": "AllowAppPort",
                "properties": {
                    "protocol": "Tcp",
                    "sourcePortRange": "*",
                    "destinationPortRange": "8080",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 110,
                    "direction": "Inbound"
                }
            },
            {
                "name": "AllowSSH",
                "properties": {
                    "protocol": "Tcp",
                    "sourcePortRange": "*",
                    "destinationPortRange": "22",
                    "sourceAddressPrefix": "*",
                    "destinationAddressPrefix": "*",
                    "access": "Allow",
                    "priority": 120,
                    "direction": "Inbound"
                }
            }
        ]

        nsg_params = {
            "location": self.location,
            "security_rules": security_rules
        }

        nsg = self.network_client.network_security_groups.begin_create_or_update(
            self.resource_group,
            NSG_NAME,
            nsg_params
        ).result()

        print(f"✓ Network Security Group created: {nsg.id}")
        return nsg

    def create_virtual_network(self, nsg: dict) -> dict:
        """Create Virtual Network with subnet"""
        print(f"Creating Virtual Network: {VNET_NAME}")

        vnet_params = {
            "location": self.location,
            "address_space": {
                "address_prefixes": ["10.0.0.0/16"]
            },
            "subnets": [
                {
                    "name": SUBNET_NAME,
                    "address_prefix": "10.0.0.0/24",
                    "network_security_group": nsg
                }
            ]
        }

        vnet = self.network_client.virtual_networks.begin_create_or_update(
            self.resource_group,
            VNET_NAME,
            vnet_params
        ).result()

        print(f"✓ Virtual Network created: {vnet.id}")
        return vnet

    def create_public_ip(self) -> dict:
        """Create Public IP for Load Balancer"""
        print(f"Creating Public IP: {PUBLIC_IP_NAME}")

        public_ip_params = {
            "location": self.location,
            "public_ip_allocation_method": "Static",
            "sku": {"name": "Standard"}
        }

        public_ip = self.network_client.public_ip_addresses.begin_create_or_update(
            self.resource_group,
            PUBLIC_IP_NAME,
            public_ip_params
        ).result()

        print(f"✓ Public IP created: {public_ip.ip_address}")
        return public_ip

    def create_load_balancer(self, public_ip: dict) -> dict:
        """Create Load Balancer"""
        print(f"Creating Load Balancer: {LB_NAME}")

        lb_params = {
            "location": self.location,
            "sku": {"name": "Standard"},
            "frontend_ip_configurations": [
                {
                    "name": "myFrontendIP",
                    "public_ip_address": public_ip
                }
            ],
            "backend_address_pools": [
                {
                    "name": BACKEND_POOL_NAME
                }
            ],
            "probes": [
                {
                    "name": PROBE_NAME,
                    "protocol": "Http",
                    "port": 8080,
                    "request_path": "/health",
                    "interval_in_seconds": 15,
                    "number_of_probes": 2
                }
            ],
            "load_balancing_rules": [
                {
                    "name": RULE_NAME,
                    "frontend_ip_configuration": {
                        "id": f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}/providers/Microsoft.Network/loadBalancers/{LB_NAME}/frontendIPConfigurations/myFrontendIP"
                    },
                    "backend_address_pool": {
                        "id": f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}/providers/Microsoft.Network/loadBalancers/{LB_NAME}/backendAddressPools/{BACKEND_POOL_NAME}"
                    },
                    "probe": {
                        "id": f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}/providers/Microsoft.Network/loadBalancers/{LB_NAME}/probes/{PROBE_NAME}"
                    },
                    "protocol": "Tcp",
                    "frontend_port": 80,
                    "backend_port": 8080,
                    "idle_timeout_in_minutes": 15,
                    "load_distribution": "SourceIP"
                }
            ]
        }

        lb = self.network_client.load_balancers.begin_create_or_update(
            self.resource_group,
            LB_NAME,
            lb_params
        ).result()

        print(f"✓ Load Balancer created: {lb.id}")
        return lb

    def create_network_interface(self, nic_name: str, ip_address: str, vnet: dict, lb: dict) -> dict:
        """Create Network Interface"""
        print(f"Creating Network Interface: {nic_name}")

        backend_pool_id = f"/subscriptions/{self.subscription_id}/resourceGroups/{self.resource_group}/providers/Microsoft.Network/loadBalancers/{LB_NAME}/backendAddressPools/{BACKEND_POOL_NAME}"

        nic_params = {
            "location": self.location,
            "ip_configurations": [
                {
                    "name": "ipconfig1",
                    "subnet": {
                        "id": f"{vnet.id}/subnets/{SUBNET_NAME}"
                    },
                    "private_ip_address": ip_address,
                    "private_ip_allocation_method": "Static",
                    "load_balancer_backend_address_pools": [
                        {"id": backend_pool_id}
                    ]
                }
            ]
        }

        nic = self.network_client.network_interfaces.begin_create_or_update(
            self.resource_group,
            nic_name,
            nic_params
        ).result()

        print(f"✓ Network Interface created: {nic.id}")
        return nic

    def setup_all(self):
        """Main setup function"""
        try:
            print("=" * 60)
            print("Azure Load Balancer Setup")
            print("=" * 60)

            # Step 1: Create NSG
            nsg = self.create_network_security_group()

            # Step 2: Create VNET
            vnet = self.create_virtual_network(nsg)

            # Step 3: Create Public IP
            public_ip = self.create_public_ip()

            # Step 4: Create Load Balancer
            lb = self.create_load_balancer(public_ip)

            # Step 5: Create Network Interfaces
            print(f"\nCreating {VM_COUNT} Network Interfaces...")
            nics = []
            for i in range(1, VM_COUNT + 1):
                nic_name = f"myNIC{i}"
                ip_address = f"10.0.0.{i + 3}"
                nic = self.create_network_interface(nic_name, ip_address, vnet, lb)
                nics.append(nic)

            print("\n" + "=" * 60)
            print("Setup completed successfully!")
            print("=" * 60)
            print(f"\nLoad Balancer Details:")
            print(f"  Name: {LB_NAME}")
            print(f"  Public IP: {public_ip.ip_address}")
            print(f"  Access URL: http://{public_ip.ip_address}")
            print(f"  Backend Pool: {BACKEND_POOL_NAME}")
            print(f"  Network Interfaces created: {len(nics)}")

        except AzureError as e:
            print(f"✗ Error: {e}")
            sys.exit(1)

if __name__ == "__main__":
    setup = AzureLoadBalancerSetup(SUBSCRIPTION_ID, RESOURCE_GROUP, LOCATION)
    setup.setup_all()
```

### Run Python Script
```bash
# Install dependencies
pip install azure-identity azure-mgmt-network azure-mgmt-compute

# Run the setup
python azure_lb_setup.py
```

---

## 5. Terraform Configuration

### File: `main.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  default = "myResourceGroup"
}

variable "location" {
  default = "eastus"
}

variable "environment" {
  default = "prod"
}

variable "vm_count" {
  default = 3
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-backend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "pip-lb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "main" {
  name                = "lb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "backend-pool"
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "health-probe"
  protocol        = "Http"
  request_path    = "/health"
  port            = 8080
}

resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

output "load_balancer_public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "load_balancer_url" {
  value = "http://${azurerm_public_ip.main.ip_address}"
}
```

### Deploy with Terraform
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan

# View outputs
terraform output
```

---

## 6. Health Check Monitoring Script

### File: `monitor-health-probes.py`

```python
"""
Monitor Azure Load Balancer Health Probes
Provides real-time visibility into probe status
"""

import time
import json
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient

class HealthProbeMonitor:
    def __init__(self, subscription_id: str, resource_group: str, lb_name: str):
        self.subscription_id = subscription_id
        self.resource_group = resource_group
        self.lb_name = lb_name

        credential = DefaultAzureCredential()
        self.network_client = NetworkManagementClient(credential, subscription_id)

    def get_backend_pool_status(self):
        """Get current status of backend resources"""
        try:
            lb = self.network_client.load_balancers.get(
                self.resource_group,
                self.lb_name
            )

            backend_pool = lb.backend_address_pools[0]
            print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Backend Pool Status")
            print("=" * 70)

            if hasattr(backend_pool, 'backend_ip_configurations'):
                for i, config in enumerate(backend_pool.backend_ip_configurations, 1):
                    print(f"Backend {i}:")
                    print(f"  ID: {config.id}")
                    print(f"  Status: {'✓ Healthy' if 'Healthy' in str(config) else '✗ Checking'}")
                    print()

        except Exception as e:
            print(f"Error retrieving status: {e}")

    def get_probe_configuration(self):
        """Display probe configuration"""
        try:
            lb = self.network_client.load_balancers.get(
                self.resource_group,
                self.lb_name
            )

            print("\nProbe Configuration:")
            print("=" * 70)
            for probe in lb.probes:
                print(f"Probe: {probe.name}")
                print(f"  Protocol: {probe.protocol}")
                print(f"  Port: {probe.port}")
                print(f"  Path: {probe.request_path}")
                print(f"  Interval: {probe.interval_in_seconds}s")
                print(f"  Threshold: {probe.number_of_probes}")
                print()

        except Exception as e:
            print(f"Error: {e}")

    def monitor_continuous(self, interval: int = 30):
        """Continuously monitor health probes"""
        print(f"Starting continuous monitoring (interval: {interval}s)...")
        print("Press Ctrl+C to stop\n")

        try:
            while True:
                self.get_backend_pool_status()
                time.sleep(interval)

        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")

if __name__ == "__main__":
    import os

    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID", "your-subscription-id")
    resource_group = "myResourceGroup"
    lb_name = "myLoadBalancer"

    monitor = HealthProbeMonitor(subscription_id, resource_group, lb_name)
    monitor.get_probe_configuration()
    monitor.monitor_continuous()
```

---

## 7. Load Testing Script

### File: `load-test.sh`

```bash
#!/bin/bash

# Load Testing Script for Azure Load Balancer
# Tests the load balancer with concurrent requests

LB_IP=$1
CONCURRENT_REQUESTS=${2:-100}
TOTAL_REQUESTS=${3:-1000}
RATE_LIMIT=${4:-10}

if [ -z "$LB_IP" ]; then
    echo "Usage: $0 <LB_PUBLIC_IP> [concurrent_requests] [total_requests] [rate_limit]"
    echo "Example: $0 20.245.123.45 100 1000 10"
    exit 1
fi

echo "Azure Load Balancer - Load Test"
echo "=================================="
echo "Load Balancer IP: $LB_IP"
echo "Concurrent Requests: $CONCURRENT_REQUESTS"
echo "Total Requests: $TOTAL_REQUESTS"
echo "Rate Limit: $RATE_LIMIT req/s"
echo ""

# Check if the load balancer is reachable
echo "Checking connectivity..."
if ! curl -s -m 5 "http://$LB_IP" > /dev/null 2>&1; then
    echo "Error: Cannot reach Load Balancer at http://$LB_IP"
    exit 1
fi

echo "✓ Load Balancer is reachable"
echo ""

# Perform warmup requests
echo "Performing warmup..."
for i in {1..10}; do
    curl -s "http://$LB_IP" > /dev/null
done

echo "✓ Warmup complete"
echo ""

# Run Apache Bench if available
if command -v ab &> /dev/null; then
    echo "Running Apache Bench load test..."
    ab -n $TOTAL_REQUESTS -c $CONCURRENT_REQUESTS "http://$LB_IP/"
else
    echo "Apache Bench not found. Installing..."
    # For macOS
    if command -v brew &> /dev/null; then
        brew install httpd
    # For Linux
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y apache2-utils
    fi

    if command -v ab &> /dev/null; then
        echo "✓ Apache Bench installed. Running test..."
        ab -n $TOTAL_REQUESTS -c $CONCURRENT_REQUESTS "http://$LB_IP/"
    else
        echo "Using curl for testing..."

        # Simple curl-based load test
        total_time=0
        success_count=0
        error_count=0

        for ((i=1; i<=$TOTAL_REQUESTS; i++)); do
            start_time=$(date +%s%N)

            response=$(curl -s -w "%{http_code}" -o /dev/null "http://$LB_IP/")

            end_time=$(date +%s%N)
            elapsed=$((($end_time - $start_time) / 1000000))  # Convert to ms

            total_time=$((total_time + elapsed))

            if [ "$response" == "200" ]; then
                ((success_count++))
            else
                ((error_count++))
            fi

            # Display progress
            if (( $i % 100 == 0 )); then
                echo "Progress: $i / $TOTAL_REQUESTS"
            fi

            # Rate limiting
            sleep 0.$(printf "%03d" $((1000 / $RATE_LIMIT)))
        done

        # Calculate statistics
        avg_time=$((total_time / $TOTAL_REQUESTS))
        requests_per_sec=$((($TOTAL_REQUESTS * 1000) / total_time))

        echo ""
        echo "Test Results:"
        echo "============="
        echo "Total Requests: $TOTAL_REQUESTS"
        echo "Successful: $success_count"
        echo "Failed: $error_count"
        echo "Average Response Time: ${avg_time}ms"
        echo "Requests/Second: $requests_per_sec"
    fi
fi

echo ""
echo "Load test complete!"
```

### Run Load Test
```bash
chmod +x load-test.sh
./load-test.sh 20.245.123.45 100 1000 10
```

