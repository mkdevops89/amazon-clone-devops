# Phase 12: Centralized Logging (ELK Stack)

**Goal**: Stop running `kubectl logs`. Aggregate all logs into one searchable dashboard.
**Role**: DevOps Engineer.

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running (~4GB RAM free, ELK is heavy!).
*   **Helm**: Installed.

## 📝 Concept
1.  **Elasticsearch**: The Database (Indexing Engine). Stores logs.
2.  **Logstash** (or Fluentd/Filebeat): The Collector. Reads `/var/log/*` from every node.
3.  **Kibana**: The UI. Visualizes logs.

## 📝 Step-by-Step Runbook

### 1. Install the Stack (ECK Operator)
The Elastic Cloud on Kubernetes (ECK) operator makes this easy.
```bash
# 1. Install CRDs
kubectl create -f https://download.elastic.co/downloads/eck/2.10.0/crds.yaml

# 2. Install Operator
kubectl apply -f https://download.elastic.co/downloads/eck/2.10.0/operator.yaml --validate=false
```

### 2. Create the Cluster
We define Elasticsearch and Kibana as Kubernetes resources.
Create `ops/k8s/elk.yaml`:
```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 8.11.0
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
---
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: quickstart
spec:
  version: 8.11.0
  count: 1
  elasticsearchRef:
    name: quickstart
```
Apply it:
```bash
kubectl apply -f ops/k8s/elk.yaml
```

### 3. Verification
Wait (takes ~5 minutes).
```bash
kubectl get elasticsearch
# Expected: HEALTH=green, PHASE=Ready
kubectl get kibana
# Expected: HEALTH=green
```

### 4. Access Kibana
1.  **Get Password**:
    ```bash
    kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
    ```
2.  **Port Forward**:
    ```bash
    kubectl port-forward service/quickstart-kb-http 5601
    ```
3.  **Login**: `https://localhost:5601` (User: `elastic`).

### 5. Send Logs
ELK automatically scrapes stdout. Run your app and reload the page.
1.  In Kibana, go to **Discover**.
2.  Create a "Data View" for `logs-*`.
3.  Search for `"NullPointerException"`.

## 🚀 Troubleshooting
*   **"OOMKilled"**: Node ran out of RAM. Elasticsearch needs at least 2GB Java Heap.
*   **"Pending"**: You don't have enough nodes. EKS needs `t3.medium` minimum for ELK.
