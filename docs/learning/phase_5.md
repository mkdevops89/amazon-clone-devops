# Phase 5: Kubernetes Manifests (Raw K8s)

**Goal**: Understand exactly *how* Kubernetes works underneath the Helm Magic.
**Role**: Kubernetes Administrator.

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running (EKS or Minikube).
*   **Kubectl**: Configured to talk to the cluster.

## 📝 Concepts
Helm generates these files for you. But to debug, you must read "Raw YAML".
*   **Deployment**: Manages Pods (ReplicaSets). Handles rolling updates.
*   **Service**: A stable IP address (DNS) for the Pods.
*   **Secret**: Encrypted passwords (base64 encoded).

## 📝 Step-by-Step Runbook

### 1. Create a Deployment (Backend)
Look at `ops/k8s/backend-deployment.yaml`.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: michael/amazon-backend:latest
        ports:
        - containerPort: 8080
```
This implies: "Maintain 2 copies of the backend at all times."

### 2. Apply it
```bash
kubectl apply -f ops/k8s/backend-deployment.yaml
# Expected: deployment.apps/backend created
```

### 3. Verify Pods
```bash
kubectl get pods
# You will see 2 pods with random names like "backend-6b4f8b-xyz"
```

### 4. Create a Service
Pods die and get new IPs. A Service gives them a static name.
Look at `ops/k8s/backend-service.yaml`.
```bash
kubectl apply -f ops/k8s/backend-service.yaml
# Expected: service/backend created
```

### 5. Validate DNS
Start a temporary pod to test internal DNS.
```bash
kubectl run -it --rm debug --image=busybox -- sh
# Inside the pod:
nslookup backend
# Expected: Address: 10.x.x.x (ClusterIP)
exit
```

### 6. Cleanup
```bash
kubectl delete -f ops/k8s/backend-deployment.yaml
kubectl delete -f ops/k8s/backend-service.yaml
```

## 🚀 Troubleshooting
*   **"ImagePullBackOff"**: Kubernetes can't download your image.
    *   *Solution*: Did you push it to Docker Hub? (`docker push ...`).
    *   *Solution*: Or use `image: nginx` just to test.
*   **"Pending"**: No nodes have enough CPU/RAM to fit the pod.
