# Phase 0: Network Configuration Runbook (AWS Console)

**Objective:** Manually create the VPC, Subnets, and Gateways to support a 3-Tier Architecture.
**Region:** `us-east-1` (N. Virginia)

## 📋 Copy-Paste Values

### 1. VPC
| Setting | Value |
| :--- | :--- |
| **Name tag** | `amazon-vpc-manual` |
| **IPv4 CIDR block** | `10.0.0.0/16` |
| **Tenancy** | Default |

### 2. Subnets
Create these 4 subnets inside `amazon-vpc-manual`.

| Name | AZ | IPv4 CIDR | Type | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `public-subnet-1` | `us-east-1a` | `10.0.1.0/24` | Public | Load Balancer |
| `public-subnet-2` | `us-east-1b` | `10.0.2.0/24` | Public | Load Balancer |
| `private-subnet-1` | `us-east-1a` | `10.0.3.0/24` | Private | App & Data |
| `private-subnet-2` | `us-east-1b` | `10.0.4.0/24` | Private | App & Data |

### 3. Internet Gateway (IGW)
| Setting | Value |
| :--- | :--- |
| **Name tag** | `amazon-igw-manual` |
| **Action** | **Attach to VPC** -> `amazon-vpc-manual` |

### 4. NAT Gateway
| Setting | Value |
| :--- | :--- |
| **Name tag** | `amazon-nat-manual` |
| **Subnet** | `public-subnet-1` (Important: Must be Public) |
| **Elastic IP** | Allocate Elastic IP |

### 5. Route Tables (RT)
You need **Two** Route Tables.

#### Route Table A: Public
| Setting | Value |
| :--- | :--- |
| **Name tag** | `amazon-rt-public` |
| **Routes** | `0.0.0.0/0` -> Target: `amazon-igw-manual` (Internet Gateway) |
| **Associations** | Select `public-subnet-1` AND `public-subnet-2` |

#### Route Table B: Private
| Setting | Value |
| :--- | :--- |
| **Name tag** | `amazon-rt-private` |
| **Routes** | `0.0.0.0/0` -> Target: `amazon-nat-manual` (NAT Gateway) |
| **Associations** | Select `private-subnet-1` AND `private-subnet-2` |

---
**Checkpoint:**
Once done, your Private Subnets have internet access (for updates) via NAT, but no one can enter them directly. Public Subnets accept traffic from the IGW.
