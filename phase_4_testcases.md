# Phase 4 Test Cases: Kubernetes Deployment

Run these commands to verify your deployment at each stage.

## 1. ECR Verification (Post-Terraform)

**Objective:** Verify that ECR repositories are created and images are pushed successfully.

### 1.1 Check Repositories Exist
```bash
aws ecr describe-repositories --repository-names amazon-backend amazon-frontend --region us-east-1
# EXPECTED: JSON output with "repositoryArn", "repositoryUri" for both.
```

### 1.2 Verify Docker Images Pushed
```bash
# List images in backend repo
aws ecr list-images --repository-name amazon-backend --region us-east-1

# List images in frontend repo
aws ecr list-images --repository-name amazon-frontend --region us-east-1
# EXPECTED: "imageTag": "latest" (or specific tag) should be present in both.
```

---

## 2. EKS Cluster Health

**Objective:** Ensure the platform is ready for workloads.

### 2.1 Node Status
```bash
kubectl get nodes
# EXPECTED: All nodes should be in 'Ready' status.
```

### 2.2 Core Components
```bash
kubectl get pods -n kube-system
# EXPECTED: `coredns`, `kube-proxy`, `aws-node` pods should be 'Running'.
```

---

## 3. Application Deployment (Workloads)

**Objective:** Verify that Pods are scheduled and running without errors.

### 3.1 Backend Status
```bash
kubectl get deployment amazon-backend
kubectl get pods -l app=amazon-backend
# EXPECTED: Status 'Running', Ready 1/1.
```

### 3.2 Secrets Verification
```bash
kubectl get secret db-secrets -o jsonpath='{.data.db_password}' | base64 --decode
# EXPECTED: Should print your actual database password (not "placeholder").
```

### 3.3 Frontend Status
```bash
kubectl get deployment amazon-frontend
kubectl get pods -l app=amazon-frontend
# EXPECTED: Status 'Running', Ready 1/1.
```

### 3.3 Log Analysis (Startup Check)
```bash
# Check Backend Logs for DB Connection
kubectl logs -l app=amazon-backend
# EXPECTED: "Connected to MySQL", "Hibernate initialized", or similar success messages.
# FAILURE INDICATOR: "Connection refused", "Access denied", "UnknownHostException".

# Check Frontend Logs
kubectl logs -l app=amazon-frontend
# EXPECTED: "Ready on http://localhost:3000" or similar Next.js startup message.
```

---

## 4. Networking & Connectivity

**Objective:** Verify internal and external communication.

### 4.1 Service Discovery
```bash
kubectl get svc
# EXPECTED:
# amazon-backend   ClusterIP      <internal-ip>   8080/TCP
# amazon-frontend  LoadBalancer   <external-ip>   80/TCP
```

### 4.2 Database Connectivity (From Pod)
*This verifies network rules/security groups are correct.*
```bash
# Spawns a temporary shell inside the cluster
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash

# Inside the shell:
nc -zv <RDS_ENDPOINT> 3306
# EXPECTED: "Connection to ... 3306 port [tcp/mysql] succeeded!"

nc -zv <REDIS_ENDPOINT> 6379
# EXPECTED: "Connection to ... 6379 port [tcp/redis] succeeded!"
```

### 4.3 Public Access (Frontend)
```bash
# Get the External IP/DNS
EXTERNAL_IP=$(kubectl get svc amazon-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "http://$EXTERNAL_IP"

# Test with curl
curl -I http://$EXTERNAL_IP
# EXPECTED: HTTP/1.1 200 OK
```

### 4.4 End-to-End API Test (Through Frontend)
*Access the site in browser or use curl:*
```bash
curl http://$EXTERNAL_IP/api/health
# (Assuming your frontend proxies /api to backend, OR access backend LB directly if exposed)
```
