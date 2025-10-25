# Azure Load Balancer - Complete Theory Guide

## 1. Overview of Azure Load Balancer

Azure Load Balancer is a Layer 4 (Transport Layer) load balancing service that distributes incoming network traffic across multiple backend resources (VMs, containers, etc.) to ensure high availability, scalability, and reliability.

### Key Characteristics
- **OSI Layer**: Layer 4 (Transport Layer - TCP/UDP)
- **Protocol Support**: TCP, UDP
- **High Availability**: Supports up to 1 million concurrent connections
- **Ultra Performance**: Handles up to 8 million packets per second
- **Zero-trust capable**: Supports integration with Azure DDoS Protection

---

## 2. Types of Azure Load Balancers

### 2.1 Public Load Balancer
**Purpose**: Distributes inbound traffic from the internet to backend resources

**Characteristics**:
- Maps public IP addresses and port numbers
- Translates private IP and port numbers of VMs
- Supports NAT and load balancing rules
- Ideal for public-facing applications

**Use Cases**:
- Web applications exposed to the internet
- API endpoints
- VPN gateways
- Gaming services

### 2.2 Internal Load Balancer (Private)
**Purpose**: Distributes traffic only from internal networks (private subnet)

**Characteristics**:
- Uses only private IP addresses
- No public IP exposure
- Restricted to internal network communication
- Supports internal network routing

**Use Cases**:
- Multi-tier application architectures
- Database servers (load balancing across multiple DB instances)
- Backend service distribution
- Internal microservices communication

### 2.3 Gateway Load Balancer
**Purpose**: Enables scalable deployment of Network Virtual Appliances (NVAs)

**Characteristics**:
- Layer 4 transparent proxy
- Allows insertion of NVAs in traffic path
- High availability and scalability for security appliances
- Supports transparent mode

**Use Cases**:
- Firewall scaling
- IDS/IPS systems
- Deep packet inspection
- Network security appliances

---

## 3. Important Components of Azure Load Balancer

### 3.1 Frontend IP Configuration
- **Definition**: Public or private IP address that receives incoming traffic
- **Types**: 
  - Public IP (for Public LB)
  - Private IP (for Internal LB)
- **Quantity**: Up to 10 frontend IPs per load balancer

### 3.2 Backend Pool
- **Definition**: Collection of virtual machines or instances that receive load-balanced traffic
- **Capacity**: Up to 1000 backend resources
- **Member Types**:
  - Virtual Machine NIC
  - Virtual Machine Scale Set (VMSS)
  - IP-based members

### 3.3 Health Probe
- **Purpose**: Determines the health status of backend resources
- **Types**:
  - HTTP/HTTPS probe (most common)
  - TCP probe
  - Guest agent probe (legacy, not recommended)
- **Responsibility**: Decides whether to send traffic to a backend resource

### 3.4 Load Balancing Rule
- **Purpose**: Maps frontend configuration to backend pool
- **Components**:
  - Frontend IP and port
  - Backend IP and port
  - Protocol (TCP/UDP)
  - Session persistence (optional)
  - Idle timeout
  - Floating IP (optional)

### 3.5 NAT Rules (For Public LB)
- **Inbound NAT Rule**: Maps specific frontend IP/port to backend resource
- **Outbound NAT Rule**: Handles outbound traffic from backend to external networks
- **Purpose**: Direct access to individual backend resources and source NAT

### 3.6 Outbound Rules
- **Purpose**: Controls outbound connectivity from backend resources
- **Features**:
  - Explicit outbound connectivity
  - Supports connection pooling
  - Multiple public IPs for redundancy

---

## 4. How Health Checks Work

### 4.1 Health Probe Mechanism

```
┌─────────────────┐
│  Load Balancer  │
└────────┬────────┘
         │
    ┌────┴─────┬──────────┬──────────┐
    │           │          │          │
┌───▼──┐   ┌───▼──┐  ┌───▼──┐  ┌───▼──┐
│ VM 1 │   │ VM 2 │  │ VM 3 │  │ VM 4 │
│Healthy   │Healthy   │ DOWN │  │Healthy
└────┬─────┴────┬─────┴──────┴──────┬─┘
     │          │                   │
     └──────────┼───────────────────┘
         Traffic Distribution
         (VM3 excluded)
```

### 4.2 Probe Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| **Protocol** | HTTP, HTTPS, TCP, Guest Agent | HTTP |
| **Port** | Destination port | Varies |
| **Path** (HTTP/S) | URI path for HTTP probes | "/" |
| **Interval** | Time between probe attempts | 15 seconds |
| **Unhealthy Threshold** | Failed attempts before marking unhealthy | 2 |
| **Healthy Threshold** | Successful attempts before marking healthy | 2 |

### 4.3 Health Probe Decision Logic

```
Health Probe Flow:
1. Send probe request to backend resource
   ↓
2. Check response within timeout (4 seconds)
   ├─ Response received
   │  ├─ HTTP: Status code 200 OK → Count as success
   │  └─ TCP: Connection established → Count as success
   └─ No response → Count as failure
   ↓
3. Track consecutive results
   ├─ X consecutive successes → Mark as HEALTHY
   └─ Y consecutive failures → Mark as UNHEALTHY
   ↓
4. Make routing decision
   ├─ HEALTHY → Route traffic
   └─ UNHEALTHY → Exclude from traffic
```

### 4.4 Probe Response Codes (HTTP/HTTPS)

| Status Code | Interpretation | Result |
|-------------|----------------|--------|
| 200 | OK - Healthy | ✓ Healthy |
| 201-299 | Success variants | ✓ Healthy |
| 301-399 | Redirects | ✗ Unhealthy |
| 400-599 | Client/Server errors | ✗ Unhealthy |
| Timeout | No response in 4 seconds | ✗ Unhealthy |

---

## 5. Load Balancer SKUs

### 5.1 Basic SKU
- **Cost**: Lowest
- **Capacity**: Up to 100 backend resources
- **Availability Zones**: Not supported
- **SLA**: No guaranteed SLA
- **Use Case**: Development, testing, small workloads

### 5.2 Standard SKU
- **Cost**: Medium
- **Capacity**: Up to 1000 backend resources
- **Availability Zones**: Supported (zone-redundant)
- **SLA**: 99.99% uptime SLA
- **Features**:
  - Outbound rules
  - Diagnostics and logging
  - Support for Network Security Groups
- **Use Case**: Production workloads

### 5.3 Gateway SKU
- **Cost**: Higher
- **Capacity**: Up to 1000 backend resources
- **Purpose**: NVA scaling
- **Features**:
  - Transparent proxy mode
  - Connection draining
  - Floating IP

---

## 6. Configuration Hierarchy

```
Azure Load Balancer
├── Frontend IP Configuration
│   ├── Public IP or Private IP
│   └── Port (1-65535)
├── Backend Pool
│   ├── VM 1
│   ├── VM 2
│   ├── VM 3
│   └── VM 4
├── Health Probes
│   ├── Probe 1 (HTTP)
│   └── Probe 2 (TCP)
├── Load Balancing Rules
│   ├── Rule 1 (mapping Frontend → Backend)
│   └── Rule 2 (mapping Frontend → Backend)
└── NAT Rules / Outbound Rules (if Public LB)
```

---

## 7. Traffic Flow in Load Balancer

### 7.1 Inbound Traffic Flow
```
Internet/External Request
        ↓
Frontend IP:Port (Public LB)
        ↓
Load Balancing Rule
        ↓
Health Check (Is backend healthy?)
        ├─ YES → Select backend resource
        │        ↓
        │     Backend Pool Member
        │        ↓
        │     Application Response
        │        ↓
        └─→ NAT (translate to Frontend IP)
        ↓
Response to Client
```

### 7.2 Outbound Traffic Flow
```
Backend Resource sends traffic
        ↓
Outbound Rule checks
        ↓
SNAT (Source NAT)
├─ Map backend private IP to frontend public IP
└─ Translate source port
        ↓
External destination receives traffic
from LB public IP
```

---

## 8. Session Persistence (Sticky Sessions)

### 8.1 Disabled (Default)
- **Hash**: Source IP + Destination IP + Protocol
- **Behavior**: Each connection may go to different backend
- **Use Case**: Stateless applications

### 8.2 Client IP (2-tuple)
- **Hash**: Source IP + Destination IP
- **Behavior**: Same client → Same backend
- **Use Case**: Simple stateful applications

### 8.3 Client IP and Protocol (3-tuple)
- **Hash**: Source IP + Destination IP + Protocol
- **Behavior**: Same client + protocol → Same backend
- **Use Case**: Complex stateful applications with multiple protocols

---

## 9. Pricing Model

### 9.1 Cost Components

| Component | Pricing |
|-----------|---------|
| **Rule (Inbound/Outbound)** | $0.25 per rule/month (Standard SKU) |
| **Data Processing** | $0.006 per GB (first 100 TB/month) |
| **Public IP Address** | $3 per month (if not used) |
| **Load Balancer Instance** | Free (Standard SKU) or per-request (Basic) |

### 9.2 Cost Optimization Tips
- Use Standard SKU with outbound rules (better control)
- Consolidate rules to reduce rule count
- Use private load balancers when possible (no public IP cost)
- Monitor data processing to optimize architecture

---

## 10. Limitations of Azure Load Balancer

| Limitation | Details |
|-----------|---------|
| **Max Backend Resources** | 1000 (VMSS supports more) |
| **Max Frontend IPs** | 10 per LB |
| **Max Rules** | 150 rules per LB |
| **Max Health Probes** | 250 probes per LB |
| **Layer 4 Only** | Cannot route based on URL path or hostname |
| **No SSL Termination** | Use Application Gateway for TLS/SSL |
| **No Cookie-based Persistence** | Only IP-based persistence |
| **Regional** | Cannot load balance across regions |
| **No DDoS Protection** | Add separately via Azure DDoS Protection |

---

## 11. Best Practices for Azure Load Balancer

### 11.1 Design Best Practices

1. **Use Standard SKU**
   - Better SLA and features
   - Production-ready
   - Cost justified by reliability

2. **Implement Proper Health Checks**
   - Use HTTP/HTTPS probes (not TCP alone)
   - Monitor actual application health, not just port availability
   - Set appropriate thresholds (default 2/2 is usually good)

3. **Distribute Across Availability Zones**
   - Use zone-redundant frontends
   - Spread backend resources across zones
   - Ensures resilience to zone failures

4. **Use Outbound Rules Explicitly**
   - Don't rely on default outbound NAT
   - Define explicit outbound connectivity
   - Better control and troubleshooting

5. **Proper Logging and Monitoring**
   - Enable NSG flow logs
   - Monitor health probe failures
   - Set up alerts for backend issues

### 11.2 Performance Best Practices

1. **Connection Pooling**
   - Reuse connections when possible
   - Reduces connection setup overhead
   - Improves throughput

2. **Tuning Idle Timeout**
   - TCP idle timeout: 4-30 minutes
   - Depends on application requirement
   - Default 4 minutes is suitable for most cases

3. **Session Persistence**
   - Use session persistence only when needed
   - Can cause uneven load distribution
   - Better to design stateless applications

### 11.3 Security Best Practices

1. **Network Security Groups (NSG)**
   - Apply NSGs to subnets and NICs
   - Restrict backend access to LB traffic only
   - Use service tags for Azure management

2. **Public IP Protection**
   - Use Azure DDoS Protection Standard
   - Monitor suspicious traffic patterns
   - Implement WAF with Application Gateway if needed

3. **Compliance and Auditing**
   - Enable diagnostic logging
   - Use Azure Policy for governance
   - Regular security assessments

### 11.4 Operational Best Practices

1. **Graceful Shutdown**
   - Use connection draining
   - Complete existing connections before shutdown
   - Prevent data loss

2. **Probe Path Configuration**
   - Use dedicated health check endpoint
   - Avoid full application paths
   - Keep response minimal

3. **Regular Testing**
   - Test failover scenarios
   - Simulate backend failures
   - Validate health probe responsiveness

---

## 12. Common Use Cases

### 12.1 Web Application Tier
- Distribute HTTP/HTTPS traffic across multiple web servers
- Ensure high availability
- Support auto-scaling

### 12.2 Database Tier (Internal LB)
- Distribute client connections across multiple databases
- Load balance read replicas
- Ensure database availability

### 12.3 API Gateway Pattern
- Distribute API requests
- Enable microservices routing
- Support multiple backend services

### 12.4 Gaming Services
- Handle massive concurrent connections
- Low-latency requirement
- High throughput demand

### 12.5 IoT Data Ingestion
- Distribute IoT device connections
- High concurrent connection support
- UDP protocol support

---

## 13. Comparison with Other Azure Services

| Feature | Load Balancer | Application Gateway | Traffic Manager |
|---------|---------------|-------------------|-----------------|
| **OSI Layer** | Layer 4 | Layer 7 | Layer 7 (DNS) |
| **Protocol** | TCP/UDP | HTTP/HTTPS | DNS |
| **Routing** | IP/Port | URL/Hostname | Geographic |
| **SSL Termination** | No | Yes | N/A |
| **Regional** | Yes | Yes | Global |
| **Cost** | Low | Medium | Low |
| **Use Case** | Internal/Basic LB | Web apps | Global routing |

---

## 14. Troubleshooting Guide

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| **Traffic not reaching backend** | Health probe failing | Check probe endpoint, firewall, NSG |
| **Uneven traffic distribution** | Session persistence enabled | Verify hash algorithm, disable if not needed |
| **High latency** | Incorrect idle timeout | Adjust timeout value, check network path |
| **Connection refused** | Backend firewall blocking | Allow LB subnet/IP in backend NSG |
| **Intermittent failures** | Health probe threshold too low | Increase unhealthy threshold value |

---

## 15. Migration Path

When migrating to Azure Load Balancer:

1. **From On-premises**: Use Traffic Manager + Load Balancer
2. **From Other Clouds**: Map equivalent concepts, test failover
3. **Scaling Strategy**: Start with smaller SKU, upgrade as needed
4. **Zero-downtime**: Use health probes with graceful shutdown

---

## Summary Table

| Aspect | Details |
|--------|---------|
| **Type** | Layer 4 Load Balancing Service |
| **Best For** | High-throughput, low-latency applications |
| **Scalability** | Up to 1 million concurrent connections |
| **SLA** | 99.99% (Standard SKU) |
| **Regional** | Yes (multi-region via Traffic Manager) |
| **Cost** | Very affordable, predictable |
| **Learning Curve** | Moderate |
| **Production Ready** | Yes |

