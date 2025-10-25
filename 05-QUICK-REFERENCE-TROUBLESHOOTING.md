# Azure Load Balancer - Quick Reference & Troubleshooting

## Quick Reference Guide

### 1. Common Azure CLI Commands

#### Create Resources
```bash
# Create resource group
az group create -n myRG -l eastus

# Create virtual network and subnet
az network vnet create -n myVNet -g myRG --address-prefix 10.0.0.0/16 \
  --subnet-name mySubnet --subnet-prefix 10.0.0.0/24

# Create Network Security Group
az network nsg create -n myNSG -g myRG

# Create public IP
az network public-ip create -n myPublicIP -g myRG --sku Standard \
  --allocation-method Static --zone 1 2 3

# Create load balancer
az network lb create -n myLB -g myRG --sku Standard \
  --public-ip-address myPublicIP --frontend-ip-name myFrontend \
  --backend-pool-name myBackend

# Create health probe
az network lb probe create -n myProbe --lb-name myLB -g myRG \
  --protocol http --port 8080 --path /health --interval 15

# Create load balancing rule
az network lb rule create -n myRule --lb-name myLB -g myRG \
  --protocol tcp --frontend-port 80 --backend-port 8080 \
  --frontend-ip-name myFrontend --backend-pool myBackend --probe myProbe

# Create outbound rule
az network lb outbound-rule create --lb-name myLB -g myRG \
  --name outbound --frontend-ip-config myFrontend --backend-pool myBackend \
  --protocol All --outbound-ports 0
```

#### Get Information
```bash
# Get public IP address
az network public-ip show -n myPublicIP -g myRG --query ipAddress -o tsv

# Get load balancer details
az network lb show -n myLB -g myRG

# List all backend pools
az network lb address-pool list --lb-name myLB -g myRG

# Get rule details
az network lb rule show --lb-name myLB -n myRule -g myRG

# Get probe status
az network lb probe show --lb-name myLB -n myProbe -g myRG
```

#### Delete Resources
```bash
# Delete specific resource
az network lb delete -n myLB -g myRG

# Delete entire resource group
az group delete -n myRG --yes
```

---

### 2. Load Balancer Configuration Checklist

```markdown
□ Resource Group Created
□ Virtual Network Created
□ Subnets Configured (one per tier)
□ Network Security Groups Created
  □ NSG rules allow LB traffic to backends
  □ NSG rules allow outbound traffic
□ Public IP Created (if Public LB)
  □ Static allocation method
  □ Standard SKU
  □ Zone-redundant
□ Load Balancer Created
  □ Standard SKU
  □ Correct VNET and subnet
□ Health Probe Configured
  □ Protocol: HTTP/HTTPS/TCP
  □ Port: Correct application port
  □ Path: Valid health endpoint (if HTTP/HTTPS)
  □ Interval: 15 seconds (or appropriate)
  □ Threshold: 2 (or appropriate)
□ Backend Pool Created and Populated
  □ Contains 2+ backend resources
  □ Resources in correct subnet
□ Load Balancing Rules Created
  □ Frontend port specified
  □ Backend port specified
  □ Protocol correct
  □ Load distribution appropriate
  □ Idle timeout appropriate
  □ Probe associated
□ Outbound Rules Configured (if Public LB)
  □ Explicit outbound rules defined
  □ Outbound IP configured
□ Monitoring Enabled
  □ Diagnostics logging configured
  □ Alerts set for failures
```

---

### 3. Pricing Quick Reference

#### Standard SKU Costs
```
Load Balancing Rules: $0.25 per rule per month
Data Processed:       $0.006 per GB (first 100 TB)
Public IP:            $3 per month (if not used)

Example for 3-rule setup:
- 3 rules:           $0.75/month
- 50 GB/month:       $0.30/month
- 1 public IP:       $3.00/month
- 3 VMs (B2s):       ~$45/month
TOTAL:               ~$49/month
```

#### Cost Optimization
```
✓ Use private LBs for internal traffic (no IP cost)
✓ Consolidate rules to reduce per-rule charges
✓ Monitor data transfer to avoid excess charges
✓ Use smaller VM sizes if possible
✓ Consider reserved instances for committed workloads
```

---

## Troubleshooting Guide

### Issue 1: Backend Resources Show as Unhealthy

**Symptoms**:
- Health probe status shows "Down"
- No traffic reaching backends
- Portal shows red X on backend pool members

**Diagnostic Steps**:

```bash
# Step 1: Verify backend is running
ssh backend-vm "curl -s http://localhost:8080/health"
# Expected: HTTP 200 with response body

# Step 2: Check NSG allows LB traffic
az network nsg rule list --resource-group $RG --nsg-name $NSG_NAME
# Look for rule allowing port 8080 from AzureLoadBalancer

# Step 3: Verify health check endpoint
az network lb probe show --lb-name $LB --resource-group $RG \
  --name $PROBE | jq '.requestPath, .port'

# Step 4: Test health endpoint directly
for ip in 10.0.0.4 10.0.0.5 10.0.0.6; do
  echo "Testing $ip..."
  curl -s http://$ip:8080/health
done

# Step 5: Check probe timeout (4 seconds)
# Application must respond within 4 seconds
time curl -v http://localhost:8080/health
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| NSG blocking traffic | Add NSG rule: Allow source `AzureLoadBalancer` to port |
| Health endpoint returns non-200 | Fix application, ensure `/health` returns 200 |
| Backend not listening | SSH to VM and check app status |
| Firewall on VM blocking port | Disable or configure VM firewall |
| Resource overloaded | Check CPU/Memory, scale up or add replicas |
| Probe timeout (> 4s) | Optimize health check endpoint performance |

---

### Issue 2: Cannot Connect to Load Balancer from Internet

**Symptoms**:
- `curl http://<public-ip>` times out or refuses connection
- Network error when accessing via public IP
- Test traffic works from within VNET

**Diagnostic Steps**:

```bash
# Step 1: Verify public IP exists and is allocated
az network public-ip show -n $PUBLIC_IP --query ipAddress -o tsv
# Should return a valid IP like 20.245.123.45

# Step 2: Check load balancer frontend configuration
az network lb frontend-ip-config show --lb-name $LB --name myFrontend
# Verify public IP is properly linked

# Step 3: Verify load balancing rule
az network lb rule show --lb-name $LB -n $RULE
# Verify frontend port 80 is in the rule

# Step 4: Test from within Azure VNET
ssh backend-vm "curl -s http://<public-ip>"

# Step 5: Check NSG on frontend
# Frontend traffic typically not restricted by NSG

# Step 6: Check Azure Firewall (if deployed)
# Verify it allows traffic to public IP

# Step 7: Test specific port
telnet <public-ip> 80
# Should connect

# Step 8: Check if rule is enabled
az network lb rule list --lb-name $LB --resource-group $RG
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Public IP not allocated | Verify IP address is assigned and static |
| Frontend rule not created | Create load balancing rule for frontend port |
| Backend pool empty | Add resources to backend pool |
| All backends unhealthy | Fix health probes, ensure backends responsive |
| ISP blocking port 80 | Try different port or use ISP's allowed ports |
| Azure DDoS Protection blocking | Check DDoS protection logs |

---

### Issue 3: Uneven Traffic Distribution

**Symptoms**:
- Some backends receive more traffic than others
- Load distribution appears unbalanced
- Some VMs at 80% CPU while others at 20%

**Diagnostic Steps**:

```bash
# Step 1: Check load distribution setting
az network lb rule show --lb-name $LB -n $RULE \
  --query "loadDistribution" -o tsv
# Should be "Default", "SourceIP", or "SourceIPProtocol"

# Step 2: Monitor traffic per backend
# Option A: Application-level logging
tail -f /var/log/app/requests.log | wc -l

# Option B: Network monitoring
az network watcher flow-log create --name nsg-flow-logs \
  --nsg $NSG --storage-account $STORAGE

# Step 3: Check if session persistence is causing imbalance
# If using SourceIP, verify if certain IP ranges are larger

# Step 4: Check health probe settings
az network lb probe show --lb-name $LB -n $PROBE
# Ensure appropriate interval and threshold

# Step 5: Monitor backend pool status
while true; do
  for ip in 10.0.0.4 10.0.0.5 10.0.0.6; do
    echo -n "$ip: "
    curl -s -o /dev/null -w "%{http_code}" http://$ip:8080/health
    echo
  done
  sleep 5
done
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| SourceIP distribution with non-uniform clients | Use Default distribution |
| Backend performance differences | Scale up slower backends or optimize code |
| Health check failures on some backends | Fix health issues on struggling backends |
| Sticky sessions causing concentration | Use stateless design if possible |
| Incorrect probe threshold | Increase threshold to prevent flapping |

---

### Issue 4: SNAT Port Exhaustion

**Symptoms**:
- "Cannot create connection" errors
- Backend-to-external service failures
- Intermittent outbound connectivity issues
- Errors like "Cannot allocate memory" when connecting out

**Diagnostic Steps**:

```bash
# Step 1: Monitor SNAT connection status
az monitor metrics list-definitions --resource-group $RG \
  --resource-type "Microsoft.Network/loadBalancers" | grep -i snat

# Step 2: Check failed SNAT connections
az monitor metrics list --resource-group $RG \
  --resource-id /subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Network/loadBalancers/$LB \
  --metric FailedSNATConnections --start-time 2024-10-20T00:00:00Z \
  --end-time 2024-10-25T00:00:00Z --interval PT5M

# Step 3: Check outbound rule configuration
az network lb outbound-rule show --lb-name $LB -n outbound-rule

# Step 4: Monitor connection states
ssh backend-vm "netstat -an | grep ESTABLISHED | wc -l"

# Step 5: Check backend connection behavior
ssh backend-vm "ss -tnp | grep :* | head -20"

# Step 6: Monitor port allocation
ssh backend-vm "cat /proc/sys/net/ipv4/ip_local_port_range"
# Usually 32768-65535 = ~32k ports available
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Too many outbound connections | Add more public IPs to outbound rule |
| Implicit SNAT (no explicit rule) | Configure explicit outbound rules |
| Long connection idle times | Reduce idle timeout to free ports faster |
| Connection leak in application | Fix application to close connections properly |
| Limited backend pool | Scale backend pool size |

**Prevention**:

```bash
# CORRECT - Explicit outbound rule with multiple IPs
# Step 1: Create multiple public IPs
for i in {1..3}; do
  az network public-ip create \
    --name outbound-ip-$i \
    --resource-group $RG \
    --sku Standard
done

# Step 2: Create outbound rule with multiple IPs
az network lb outbound-rule create \
  --lb-name $LB \
  --name multi-ip-outbound \
  --frontend-ip-config myFrontend \
  --backend-pool myBackend \
  --protocol All \
  --outbound-ports 0 \
  --public-ips outbound-ip-1 outbound-ip-2 outbound-ip-3

# Each IP has ~32k ports = 96k total ports available
```

---

### Issue 5: Health Probe Continuously Failing

**Symptoms**:
- Probe status flapping between healthy and unhealthy
- Backends getting removed and re-added frequently
- Gateway timeouts in client applications

**Diagnostic Steps**:

```bash
# Step 1: Verify probe endpoint exists and is responsive
curl -v http://backend-ip:8080/health

# Step 2: Check probe timeout (must be < 4 seconds)
time curl http://backend-ip:8080/health
# If > 4 seconds, probe will timeout

# Step 3: Check backend logs
ssh backend-vm "tail -100 /var/log/app/app.log | grep health"

# Step 4: Verify endpoint implementation
# Check if health endpoint is properly implemented

# Step 5: Monitor probe execution
# Enable backend logging for every health check request
ssh backend-vm "tail -f /var/log/app/access.log | grep '/health'"

# Step 6: Check network connectivity
ssh backend-vm "telnet 8080"
# Should connect immediately

# Step 7: Check system resources
ssh backend-vm "top -b -n 1 | head -10"
# Check CPU and memory utilization
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Backend slow/overloaded | Scale up VM or reduce load |
| Health endpoint slow | Optimize health check logic |
| Intermittent errors in health check | Add retry logic or fix underlying issue |
| Network latency > 4s | Check network, move resources closer |
| Dependency in health check unavailable | Make health check less dependent |
| Threshold too low (1 probe) | Increase threshold to 2 or 3 |

**Recommended Configuration**:

```bash
# GOOD - Tolerates temporary glitches
az network lb probe create \
  --lb-name myLB \
  --name robust-probe \
  --protocol http \
  --port 8080 \
  --path /health \
  --interval 15 \
  --threshold 2  # 2 consecutive successes to mark healthy

# This means:
# - 1 failure doesn't remove backend
# - Must succeed twice (30s) to be marked healthy again
# - Prevents unnecessary flapping
```

---

### Issue 6: High Latency from Client to Load Balancer

**Symptoms**:
- Slow response times from load balancer
- RTT times are high
- Application response time increases after deploying LB

**Diagnostic Steps**:

```bash
# Step 1: Measure latency components
time curl -w "@curl-format.txt" -o /dev/null -s http://<lb-ip>/

# Create curl-format.txt:
# time_namelookup:  %{time_namelookup}
# time_connect:     %{time_connect}
# time_appconnect:  %{time_appconnect}
# time_pretransfer: %{time_pretransfer}
# time_starttransfer: %{time_starttransfer}
# time_total:       %{time_total}

# Step 2: Compare direct vs LB latency
time curl backend-ip:8080/endpoint  # Direct
time curl <lb-ip>/endpoint           # Through LB

# Step 3: Check load balancer metrics
az monitor metrics list --resource-group $RG \
  --resource-id <lb-resource-id> \
  --metric "SynCount" --start-time 2024-10-20T00:00:00Z \
  --end-time 2024-10-25T00:00:00Z

# Step 4: Check backend performance
ssh backend-vm "time curl localhost:8080/health"

# Step 5: Monitor idle timeout impact
# Connections timing out will need re-establishment
```

**Common Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Connection setup time | Reuse connections (connection pooling) |
| Health probe traffic overhead | Configure less frequent probes |
| Network distance (geo) | Deploy LB closer to clients |
| SNAT translation overhead | Not significant, but ensure adequate ports |
| Backend slow | Fix backend performance |
| Incorrect idle timeout | Tune idle timeout for workload |

---

## Performance Tuning Checklist

```markdown
Latency Optimization:
□ Enable connection pooling in client
□ Set idle timeout appropriate for workload
□ Verify probe endpoint performance
□ Check backend server CPU/memory
□ Disable TCP nagle for low-latency apps
□ Use zone-redundant deployment for location advantage

Throughput Optimization:
□ Configure explicit outbound rules
□ Add multiple public IPs for outbound
□ Monitor SNAT connection status
□ Scale backend pool size
□ Use connection pooling

Reliability Optimization:
□ Enable TCP reset for connection cleanup
□ Configure appropriate health probe interval/threshold
□ Implement graceful shutdown in applications
□ Monitor and alert on all metrics
□ Test failover scenarios regularly

Cost Optimization:
□ Use private LBs where possible (no IP cost)
□ Consolidate rules (reduce per-rule charges)
□ Monitor data transfer
□ Use appropriate VM sizing
□ Consider reserved instances
```

---

## Quick Decision Tree

```
Problem with Load Balancer
│
├─ Unhealthy backends
│  ├─ Check health endpoint responsive
│  ├─ Verify NSG rules allow traffic
│  └─ Validate probe configuration
│
├─ Cannot reach LB from internet
│  ├─ Verify public IP exists
│  ├─ Check frontend rule exists
│  └─ Verify backend pool has healthy members
│
├─ Uneven traffic distribution
│  ├─ Check load distribution algorithm
│  ├─ Verify all backends healthy
│  └─ Check for connection pooling on clients
│
├─ Connection failures from backend
│  ├─ Check outbound rules configured
│  ├─ Monitor SNAT port exhaustion
│  └─ Add more public IPs for outbound
│
├─ High latency
│  ├─ Check backend performance
│  ├─ Verify probe configuration
│  └─ Enable connection pooling
│
└─ SNAT port exhaustion
   ├─ Configure explicit outbound rules
   ├─ Add multiple public IPs
   └─ Monitor connection patterns
```

---

## Useful Links & Resources

- Azure Load Balancer Documentation: https://docs.microsoft.com/azure/load-balancer/
- Azure CLI Reference: https://docs.microsoft.com/cli/azure/
- Pricing Calculator: https://azure.microsoft.com/pricing/details/load-balancer/
- Health Probe Behavior: https://docs.microsoft.com/azure/load-balancer/load-balancer-custom-probe-overview
- SNAT Troubleshooting: https://docs.microsoft.com/azure/load-balancer/troubleshoot-snat

