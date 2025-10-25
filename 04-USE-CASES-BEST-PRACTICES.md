# Azure Load Balancer - Use Cases & Best Practices

## Part 1: Common Use Cases

### 1. High-Availability Web Application Tier

**Scenario**: Enterprise web application serving millions of daily users

**Architecture**:
```
Internet
    ↓
Public Load Balancer (20.245.123.45:80)
    ↓
Frontend IP Configuration
    ↓
Load Balancing Rule: 80 → 8080
    ↓
Health Probe: /health endpoint
    ├─ VM1 (10.0.0.4:8080) ✓ Healthy
    ├─ VM2 (10.0.0.5:8080) ✓ Healthy
    ├─ VM3 (10.0.0.6:8080) ✓ Healthy
    └─ VM4 (10.0.0.7:8080) ✗ Unhealthy (no traffic)
```

**Key Configuration**:
```json
{
  "loadDistribution": "SourceIP",
  "idleTimeoutInMinutes": 30,
  "enableFloatingIP": false,
  "probe": {
    "protocol": "Http",
    "port": 8080,
    "requestPath": "/health",
    "intervalInSeconds": 15,
    "numberOfProbes": 2
  }
}
```

**Implementation Steps**:
1. Create 3-4 VMs running web application (e.g., Nginx, IIS, Apache)
2. Configure health check endpoint that validates database connectivity
3. Set up public load balancer with SSL termination (via Application Gateway if needed)
4. Enable auto-scaling based on CPU/memory metrics
5. Configure monitoring and alerts

**Cost Estimate**:
- Standard Load Balancer: $0.25/rule × 1 = $0.25/month
- Data Processing: ~$0.006 per GB (varies by volume)
- Public IP: $3/month
- VMs: Varies by size

**Benefits**:
- ✓ 99.99% SLA uptime
- ✓ Automatic failover within seconds
- ✓ Zero downtime during updates
- ✓ Handles millions of connections

---

### 2. Multi-Tier Application with Internal Load Balancing

**Scenario**: 3-tier application (Web → API → Database)

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│                    Internet                             │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Public Load Balancer    │
        │  (External IP:80)        │
        └────────────┬─────────────┘
                     ↓
    ┌────────────────────────────────┐
    │  Web Tier (IIS/Nginx)          │
    │  ├─ WebVM1 (10.0.0.4)         │
    │  ├─ WebVM2 (10.0.0.5)         │
    │  └─ WebVM3 (10.0.0.6)         │
    └────────────┬───────────────────┘
                 ↓ (Internal LB: 10.0.1.10:80)
    ┌────────────────────────────────┐
    │  API Tier (Node.js/Java)       │
    │  ├─ APIVM1 (10.0.1.4)         │
    │  ├─ APIVM2 (10.0.1.5)         │
    │  └─ APIVM3 (10.0.1.6)         │
    └────────────┬───────────────────┘
                 ↓ (Internal LB: 10.0.2.10:5432)
    ┌────────────────────────────────┐
    │  Database Tier (PostgreSQL)    │
    │  ├─ DBNode1 (10.0.2.4:5432)   │
    │  ├─ DBNode2 (10.0.2.5:5432)   │
    │  └─ DBNode3 (10.0.2.6:5432)   │
    └────────────────────────────────┘
```

**Configuration Steps**:

```bash
# 1. Create 3 subnets
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name myVNet \
  --name web-subnet \
  --address-prefix 10.0.0.0/24

az network vnet subnet create \
  --resource-group $RG \
  --vnet-name myVNet \
  --name api-subnet \
  --address-prefix 10.0.1.0/24

az network vnet subnet create \
  --resource-group $RG \
  --vnet-name myVNet \
  --name db-subnet \
  --address-prefix 10.0.2.0/24

# 2. Create Internal Load Balancer for API tier
az network lb create \
  --resource-group $RG \
  --name api-internal-lb \
  --sku Standard \
  --vnet-name myVNet \
  --subnet api-subnet \
  --frontend-ip-name api-frontend \
  --backend-pool-name api-backend \
  --private-ip-address 10.0.1.10

# 3. Create Internal Load Balancer for Database tier
az network lb create \
  --resource-group $RG \
  --name db-internal-lb \
  --sku Standard \
  --vnet-name myVNet \
  --subnet db-subnet \
  --frontend-ip-name db-frontend \
  --backend-pool-name db-backend \
  --private-ip-address 10.0.2.10
```

**Benefits**:
- ✓ Secure internal communication
- ✓ No public exposure of backend tiers
- ✓ Independent scaling of each tier
- ✓ Network isolation between tiers

---

### 3. E-commerce Platform with Session Persistence

**Scenario**: Online retail platform with stateful shopping cart

**Key Requirement**: User sessions must persist during shopping

**Configuration**:
```json
{
  "loadDistribution": "SourceIP",  // Session persistence enabled
  "idleTimeoutInMinutes": 30,
  "enableConnectionDraining": true,
  "connectionDrainingTimeoutInSeconds": 300,
  "probe": {
    "protocol": "Http",
    "port": 8080,
    "requestPath": "/health",
    "intervalInSeconds": 10,
    "numberOfProbes": 3
  }
}
```

**Why SourceIP?**
- All requests from same client IP go to same backend
- Shopping cart data stays in application memory
- Prevents session loss during requests

**Implementation**:
```bash
# Create rule with SourceIP distribution
az network lb rule create \
  --resource-group $RG \
  --lb-name ecommerce-lb \
  --name http-rule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080 \
  --frontend-ip-name ecommerce-frontend \
  --backend-pool-name ecommerce-backend \
  --probe-name health-probe \
  --idle-timeout 30 \
  --load-distribution SourceIP
```

**Benefits**:
- ✓ Maintains shopping cart state
- ✓ Consistent user experience
- ✓ No need for distributed session store
- ✓ Reduced database queries

**Note**: Better approach is to use stateless design with Redis for sessions

---

### 4. Real-Time Communication Service (WebSockets)

**Scenario**: Chat application with WebSocket connections

**Challenge**: WebSockets maintain persistent connections that must not be interrupted

**Configuration**:
```json
{
  "protocol": "tcp",
  "frontendPort": 443,
  "backendPort": 8443,
  "enableTcpReset": true,
  "idleTimeoutInMinutes": 30,
  "loadDistribution": "SourceIPProtocol",
  "probe": {
    "protocol": "Tcp",  // TCP probe only for persistent connections
    "port": 8443,
    "intervalInSeconds": 15
  }
}
```

**Why Important**:
- TCP reset: Properly closes stale connections
- TCP probe: Doesn't disrupt WebSocket handshake
- 30-min timeout: Maintains long-lived connections
- SourceIPProtocol: Ensures same connection stays on same backend

**Implementation**:
```bash
az network lb rule create \
  --resource-group $RG \
  --lb-name chat-app-lb \
  --name websocket-rule \
  --protocol tcp \
  --frontend-port 443 \
  --backend-port 8443 \
  --frontend-ip-name chat-frontend \
  --backend-pool-name chat-backend \
  --probe-name tcp-probe \
  --idle-timeout 30 \
  --load-distribution SourceIPProtocol \
  --enable-tcp-reset
```

**Benefits**:
- ✓ Persistent connections maintained
- ✓ Real-time message delivery
- ✓ Proper connection cleanup
- ✓ High availability of chat service

---

### 5. High-Performance Gaming Service

**Scenario**: Multiplayer online game backend

**Requirements**:
- Ultra-low latency
- High throughput
- UDP protocol support
- Connection persistence

**Configuration**:
```bash
# Create UDP rule for game traffic
az network lb rule create \
  --resource-group $RG \
  --lb-name game-server-lb \
  --name udp-game-rule \
  --protocol udp \
  --frontend-port 27015 \
  --backend-port 27015 \
  --frontend-ip-name game-frontend \
  --backend-pool-name game-backend \
  --probe-name game-probe \
  --idle-timeout 4 \
  --load-distribution SourceIP

# Health probe for game servers
az network lb probe create \
  --resource-group $RG \
  --lb-name game-server-lb \
  --name game-probe \
  --protocol tcp \
  --port 27015 \
  --interval 10
```

**Architecture**:
```
Internet Gaming Clients
        ↓
Public Load Balancer (UDP:27015)
        ↓
Distribution across Game Servers
├─ GameServer1 (Seattle, 10.0.0.4) - Latency: 5ms
├─ GameServer2 (Seattle, 10.0.0.5) - Latency: 5ms
├─ GameServer3 (Seattle, 10.0.0.6) - Latency: 5ms
└─ GameServer4 (Seattle, 10.0.0.7) - Latency: 5ms

Support 1 million+ concurrent players
```

**Benefits**:
- ✓ Massive concurrent connection support
- ✓ UDP optimized for real-time gaming
- ✓ Minimal latency
- ✓ Global presence with multiple regions

---

### 6. IoT Data Ingestion Platform

**Scenario**: Collecting sensor data from millions of IoT devices

**Configuration**:
```json
{
  "frontendPort": 8883,
  "backendPort": 8883,
  "protocol": "tcp",
  "loadDistribution": "Default",  // Different devices can go to different backends
  "idleTimeoutInMinutes": 30,
  "probe": {
    "protocol": "Tcp",
    "port": 8883,
    "intervalInSeconds": 30,
    "numberOfProbes": 2
  }
}
```

**Architecture**:
```
Millions of IoT Devices
        ↓
Public Load Balancer (TCP:8883 - MQTT)
        ↓
Backend Pool (Data Ingestion Services)
├─ IngestNode1 (10.0.0.4:8883) - 250K connections
├─ IngestNode2 (10.0.0.5:8883) - 250K connections
├─ IngestNode3 (10.0.0.6:8883) - 250K connections
└─ IngestNode4 (10.0.0.7:8883) - 250K connections

Total Capacity: 1M+ concurrent IoT connections
```

**Implementation Benefits**:
- ✓ Handles millions of concurrent connections
- ✓ MQTT protocol support
- ✓ Automatic failover of devices
- ✓ Elastic scaling based on demand

---

## Part 2: Best Practices Detailed

### 1. Design & Architecture Best Practices

#### 1.1 Use Standard SKU in Production

```bash
# ✗ WRONG - Using Basic SKU
az network lb create \
  --name myLB \
  --sku Basic

# ✓ CORRECT - Using Standard SKU
az network lb create \
  --name myLB \
  --sku Standard
```

**Why**: 
- Basic SKU lacks SLA guarantee
- No availability zone support
- Limited to 100 backend resources
- No diagnostic logging

#### 1.2 Implement Proper Health Checks

```bash
# ✗ WRONG - Generic health check
az network lb probe create \
  --lb-name myLB \
  --name probe \
  --protocol tcp \
  --port 8080

# ✓ CORRECT - Application-specific health check
az network lb probe create \
  --lb-name myLB \
  --name probe \
  --protocol http \
  --port 8080 \
  --path /api/health \
  --interval 15 \
  --threshold 2
```

**Health Check Endpoint Example** (Node.js):
```javascript
app.get('/api/health', async (req, res) => {
  try {
    // Check database connectivity
    await db.query('SELECT 1');
    
    // Check cache connectivity
    await cache.ping();
    
    // Check disk space
    const diskSpace = await checkDiskSpace();
    
    if (diskSpace < 1000000000) { // 1GB
      return res.status(503).json({ status: 'degraded' });
    }
    
    res.status(200).json({ 
      status: 'healthy',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});
```

#### 1.3 Distribute Across Availability Zones

```bash
# ✓ CORRECT - Create zone-redundant public IP
az network public-ip create \
  --resource-group $RG \
  --name myPublicIP \
  --sku Standard \
  --zone 1 2 3  # Zone-redundant

# Create zone-redundant frontend
az network lb create \
  --resource-group $RG \
  --name myLB \
  --sku Standard \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontend \
  --backend-pool-name myBackend
```

**Zone Distribution Architecture**:
```
Public IP: Zone-redundant (auto-failover across zones)
    ↓
├─ Zone 1: VM1, VM2 (10.0.0.4, 10.0.0.5)
├─ Zone 2: VM3, VM4 (10.0.0.6, 10.0.0.7)
└─ Zone 3: VM5, VM6 (10.0.0.8, 10.0.0.9)

If entire Zone 1 fails → Traffic routes to Zones 2 & 3
```

#### 1.4 Configure Explicit Outbound Rules

```bash
# ✗ WRONG - Implicit SNAT (unreliable for scale)
az network lb rule create \
  --lb-name myLB \
  --name rule1 \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080

# ✓ CORRECT - Explicit outbound rules
# Step 1: Create public IP for outbound traffic
az network public-ip create \
  --resource-group $RG \
  --name outbound-ip \
  --sku Standard

# Step 2: Create outbound rule
az network lb outbound-rule create \
  --resource-group $RG \
  --lb-name myLB \
  --name outbound-rule \
  --frontend-ip-config myFrontend \
  --backend-pool myBackend \
  --protocol All \
  --outbound-ports 0 \
  --idle-timeout 15 \
  --public-ips outbound-ip
```

**Why Explicit Rules**:
- Better control over outbound connections
- Prevents SNAT exhaustion
- Easier troubleshooting
- Consistent behavior at scale

---

### 2. Performance Best Practices

#### 2.1 Connection Pooling

```python
# ✗ WRONG - New connection per request
import socket

for request in requests:
    sock = socket.socket()
    sock.connect((backend_server, 8080))
    sock.send(request)
    sock.close()

# ✓ CORRECT - Connection pooling
from http.client import HTTPConnection

class ConnectionPool:
    def __init__(self, host, port, max_connections=10):
        self.host = host
        self.port = port
        self.pool = [
            HTTPConnection(host, port) for _ in range(max_connections)
        ]
        self.available = list(self.pool)
    
    def execute(self, method, url, data=None):
        conn = self.available.pop()
        try:
            conn.request(method, url, data)
            return conn.getresponse()
        finally:
            self.available.append(conn)

# Usage
pool = ConnectionPool('backend.example.com', 8080)
response = pool.execute('GET', '/api/data')
```

**Benefits**:
- 10x faster request handling
- Reduced CPU usage
- Better throughput
- Lower latency

#### 2.2 Optimize Idle Timeout

```bash
# Recommendation for different use cases:

# 1. Web applications (HTTP/REST)
az network lb rule create \
  --lb-name myLB \
  --name web-rule \
  --idle-timeout 4  # 4 minutes for most web apps

# 2. Long-polling/Streaming applications
az network lb rule create \
  --lb-name myLB \
  --name streaming-rule \
  --idle-timeout 30  # 30 minutes for long connections

# 3. High-frequency IoT/Trading
az network lb rule create \
  --lb-name myLB \
  --name iot-rule \
  --idle-timeout 4  # 4 minutes (frequent heartbeats)
```

**Timeout Strategy**:
```
Idle Timeout = Application Connection Lifetime + Buffer

Web App:     4 min  (HTTP connections are short-lived)
Streaming:  30 min  (Persistent connections)
IoT:         4 min  (Heartbeat-based)
Gaming:     10 min  (Persistent with periodic heartbeat)
```

#### 2.3 Enable TCP Reset for Cleanup

```bash
# ✓ CORRECT - TCP reset for graceful connection cleanup
az network lb rule create \
  --resource-group $RG \
  --lb-name myLB \
  --name my-rule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 8080 \
  --frontend-ip-name myFrontend \
  --backend-pool-name myBackend \
  --enable-tcp-reset
```

**Benefits**:
- Faster cleanup of stale connections
- Better resource utilization
- Reduced TIME_WAIT state accumulation
- Improved connection throughput

---

### 3. Monitoring & Logging Best Practices

#### 3.1 Enable Diagnostic Logging

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name lb-analytics

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name lb-analytics \
  --query id -o tsv)

# Enable diagnostics for load balancer
az monitor diagnostic-settings create \
  --resource $LB_ID \
  --name lb-diagnostics \
  --logs '[
    {
      "category": "LoadBalancerAlertEvent",
      "enabled": true,
      "retentionPolicy": {"days": 30, "enabled": true}
    },
    {
      "category": "LoadBalancerProbeHealthStatus",
      "enabled": true,
      "retentionPolicy": {"days": 30, "enabled": true}
    }
  ]' \
  --metrics '[
    {
      "category": "AllMetrics",
      "enabled": true,
      "retentionPolicy": {"days": 30, "enabled": true}
    }
  ]' \
  --workspace $WORKSPACE_ID
```

#### 3.2 Key Metrics to Monitor

```kusto
// KQL Queries for monitoring

// 1. Health probe failure rate
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName == "HealthProbeStatus"
| summarize FailureRate = (todouble(sum(Minimum)) / sum(Maximum)) * 100 by bin(TimeGenerated, 5m)
| render timechart

// 2. Data processed per backend
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName in ("BytesIn_Frontend", "BytesOut_Backend")
| summarize TotalBytes = sum(Total) by MetricName, bin(TimeGenerated, 5m)
| render barchart

// 3. Active connections
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName == "ActiveConnectionCount"
| summarize Connections = sum(Average) by bin(TimeGenerated, 1m)
| render timechart

// 4. Failed connections
AzureMetrics
| where ResourceType == "LOADBALANCERS"
| where MetricName in ("FailedSNATConnections", "SYNCount")
| summarize Failures = sum(Total) by MetricName, bin(TimeGenerated, 5m)
```

#### 3.3 Alert Configuration

```bash
# Alert when probe failure rate > 10%
az monitor metrics alert create \
  --name "LB-High-Probe-Failure" \
  --resource-group $RG \
  --scopes $LB_ID \
  --description "Alert when health probe failure rate exceeds 10%" \
  --condition "avg HealthProbeStatus < 0.9" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action email@example.com

# Alert when SNAT port exhaustion
az monitor metrics alert create \
  --name "LB-SNAT-Exhaustion" \
  --resource-group $RG \
  --scopes $LB_ID \
  --description "Alert on SNAT port exhaustion" \
  --condition "total FailedSNATConnections > 100" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1 \
  --action email@example.com
```

---

### 4. Security Best Practices

#### 4.1 Network Security Group Configuration

```bash
# ✓ CORRECT - Restrictive NSG rules
az network nsg rule create \
  --resource-group $RG \
  --nsg-name backend-nsg \
  --name allow-from-lb \
  --priority 100 \
  --source-address-prefixes "AzureLoadBalancer" \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 8080 \
  --access Allow \
  --protocol Tcp

# Deny all other inbound traffic
az network nsg rule create \
  --resource-group $RG \
  --nsg-name backend-nsg \
  --name deny-all-inbound \
  --priority 4096 \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --access Deny \
  --protocol '*'
```

#### 4.2 DDoS Protection

```bash
# Enable Azure DDoS Protection Standard
az network ddos-protection create \
  --resource-group $RG \
  --name lb-ddos-protection

# Apply to public IP
az network public-ip update \
  --resource-group $RG \
  --name myPublicIP \
  --ddos-protection-plan lb-ddos-protection \
  --protection-mode Enabled
```

---

### 5. Cost Optimization Best Practices

#### 5.1 Minimize Rules

```bash
# ✗ WRONG - Separate rules for each application
az network lb rule create --name rule-app1 ...
az network lb rule create --name rule-app2 ...
az network lb rule create --name rule-app3 ...
# Cost: $0.25 × 3 = $0.75/month

# ✓ CORRECT - Combine with variable substitution
az network lb rule create \
  --name rule-all \
  --frontend-port 80-9000  # Port range
  --backend-port 8080
# Cost: $0.25 × 1 = $0.25/month
```

#### 5.2 Use Private Load Balancers When Possible

```bash
# ✗ WRONG - Unnecessary public IP for internal traffic
COST: $0.25/rule + $3/IP = $3.25/month per LB

# ✓ CORRECT - Internal load balancer only
az network lb create \
  --name internal-app-lb \
  --sku Standard \
  --vnet-name myVNet \
  --subnet internal-subnet \
  --private-ip-address 10.0.1.10
# COST: $0.25/rule only = $0.25/month
```

#### 5.3 Consolidate Tiers

```bash
# ✗ WRONG - Multiple LBs
- Web LB ($0.25/rule)
- API LB ($0.25/rule)
- DB LB ($0.25/rule)
Total: $0.75/month + $9/IPs = $9.75/month

# ✓ CORRECT - Single LB with multiple rules
- Single LB ($0.25 × 3 rules = $0.75/month)
- Single Public IP ($3/month)
Total: $3.75/month
```

---

## Part 3: Common Mistakes to Avoid

### ❌ Mistake 1: Not Validating Health Check Endpoint

```bash
# WRONG - Health check endpoint always returns 200
app.get('/health', () => {
  res.status(200).send('OK')
})

# CORRECT - Validate actual service health
app.get('/health', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache(),
    diskSpace: await checkDiskSpace(),
    memory: await checkMemory()
  };

  const isHealthy = Object.values(checks).every(check => check.status === 'ok');
  
  res.status(isHealthy ? 200 : 503).json(checks);
});
```

### ❌ Mistake 2: Too Aggressive Health Check

```bash
# WRONG - Health check times out all requests
# Interval: 5 seconds, Threshold: 1
# After 1 failed check → backend removed
az network lb probe create \
  --interval 5 \
  --threshold 1

# CORRECT - Balanced health check
# Interval: 15 seconds, Threshold: 2
# After 2 consecutive failures (30 seconds) → backend removed
az network lb probe create \
  --interval 15 \
  --threshold 2
```

### ❌ Mistake 3: Ignoring SNAT Port Exhaustion

```bash
# Symptom: "Cannot create new connection" errors

# INCORRECT - Assuming load balancer handles everything
# High volume of outbound connections will exhaust SNAT ports

# CORRECT - Configure explicit outbound rules
az network lb outbound-rule create \
  --lb-name myLB \
  --name outbound-rule \
  --frontend-ip-config myFrontend \
  --backend-pool myBackend \
  --protocol All \
  --outbound-ports 0  # Auto-allocate
  --public-ips outbound-ip1 outbound-ip2  # Multiple IPs for more ports
```

### ❌ Mistake 4: Not Testing Failover

```bash
# WRONG - Never test failover scenarios
# Risk: Unknown behavior during actual failure

# CORRECT - Regular failover testing
#!/bin/bash

# Simulate backend failure
stop_backend_1() {
  ssh backend1 "sudo systemctl stop app"
  sleep 30
  ssh backend1 "sudo systemctl start app"
}

# Test failover
test_failover() {
  echo "Initiating failover test..."
  stop_backend_1 &
  
  # Monitor traffic during failure
  for i in {1..10}; do
    curl -s http://lb-ip/health
    echo "Health check $i"
    sleep 3
  done
}

test_failover
```

### ❌ Mistake 5: Misunderstanding Session Persistence

```bash
# WRONG - Assuming SourceIP load distribution solves session issues
az network lb rule create \
  --load-distribution SourceIP

# Problem: User with changing IP (mobile, proxy) still loses session

# CORRECT - Design stateless architecture
class SessionManager:
    def __init__(self):
        self.redis = Redis()  # Distributed session store
    
    def store_session(self, session_id, data):
        self.redis.set(f"session:{session_id}", json.dumps(data))
    
    def get_session(self, session_id):
        return json.loads(self.redis.get(f"session:{session_id}"))

# Now any backend can retrieve the session
```

---

## Summary of Best Practices

| Practice | Impact | Difficulty |
|----------|--------|-----------|
| Use Standard SKU | 99.99% SLA | Easy |
| Proper health checks | Prevent cascading failures | Medium |
| Zone redundancy | Resilience to zone failure | Medium |
| Explicit outbound rules | Prevent connection exhaustion | Hard |
| Connection pooling | 10x throughput improvement | Medium |
| Comprehensive monitoring | Quick issue detection | Medium |
| NSG configuration | Enhanced security | Easy |
| Load testing | Confidence in failover | Hard |

