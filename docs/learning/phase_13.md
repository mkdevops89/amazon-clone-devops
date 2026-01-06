# Phase 13: Service Mesh (Istio)

**Goal**: Advanced Traffic Control (Traffic Splitting, Encrypted mTLS, Circuit Breaking).
**Role**: Network Architect / SRE.

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running.
*   **Istio CLI**: `brew install istioctl`.

## 📝 Concept
Kubernetes Services (DNS) use simple "Round Robin".
Istio injects a fast proxy (Envoy) into every pod. Now you can say "Send 1% of traffic to version 2".

## 📝 Step-by-Step Runbook

### 1. Install Istio
```bash
istioctl install --set profile=demo -y
# "Demo" profile includes Egress, Ingress, and Control Plane.
```

### 2. Enable Injection
Tell Istio to watch the "default" namespace and inject sidecars automatically.
```bash
kubectl label namespace default istio-injection=enabled
# Verify
kubectl get namespace -L istio-injection
# Expected: default   enabled
```

### 3. Re-Deploy Apps
Pods only get the sidecar when they start. Kill the old ones.
```bash
kubectl rollout restart deployment backend
# Verify:
kubectl get pods
# Expected: READY 2/2 (It was 1/1 before. Now it's App + Proxy).
```

### 4. Canary Deployment (The Cool Part)
Scenario: You have `v1` (Stable) and `v2` (Beta).

1.  **Define VirtualService (Route Rules)**
    Create `ops/istio/canary.yaml`:
    ```yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: backend-route
    spec:
      hosts:
      - backend
      http:
      - route:
        - destination:
            host: backend
            subset: v1
          weight: 90
        - destination:
            host: backend
            subset: v2
          weight: 10
    ```
2.  **Apply**:
    ```bash
    kubectl apply -f ops/istio/canary.yaml
    ```
3.  **Test**: Curl your app 100 times. You will see 90 responses from v1 and 10 from v2.

### 5. mTLS (Encryption)
It is on by default in PERMISSIVE mode.
To force it (STRICT):
```bash
kubectl apply -f ops/istio/mtls-strict.yaml
```
Now, if you try to `curl` the pod IP from outside the mesh (e.g., node shell), it will fail. Secure!

## 🚀 Troubleshooting
*   **"Connection Refused"**: The Sidecar (`istio-proxy`) isn't ready yet.
*   **"503 Service Unavailable"**: You created a VirtualService but no matching DestinationRule (subsets).
