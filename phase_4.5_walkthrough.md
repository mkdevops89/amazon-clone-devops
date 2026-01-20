# Phase 4.5 Walkthrough: Observability "Eyes on Glass"

## Goal
Enable full stack monitoring for the Amazon Clone using the industry-standard "Kube Prometheus Stack". By the end of this guide, you will see real-time graphs of your Java Backend's memory usage and request latency.

## Prerequisites
- [x] EKS Cluster Running (Phase 4)
- [x] Backend deployed (Phase 4)
- [ ] **Helm Installed**:
  - Mac: `brew install helm`
  - Linux: `curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`

## Setup: Where am I?
For this entire walkthrough, you should be in the **root directory** of your project. This ensures that when we reference files like `ops/k8s/...`, the command line successfully finds them.

1.  Open your terminal.
2.  Navigate to the project root:
    ```bash
    cd /Users/michael/Documents/amazonlikeapp
    # Verify you are in the right place
    ls -F
    # You should see: backend/ frontend/ ops/ ...
    ```

## Step 1: Install Prometheus & Grafana (The Stack)
We will use **Helm** (The Kubernetes Package Manager) to install the entire monitoring stack in one go. Think of this like `npm install` but for your cluster.

1.  **Add the Repo:**
    Tell Helm where to find the Prometheus software.

1.  **Add the Repo:**
    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    ```
2.  **Create Monitoring Namespace:**
    ```bash
    kubectl create namespace monitoring
    ```
3.  **Install with Custom Values:**
    Use the config we just created (`ops/k8s/monitoring/prometheus-values.yaml`).
    ```bash
    helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
      -n monitoring \
      -f ops/k8s/monitoring/prometheus-values.yaml
    ```

## Step 2: Verify Instrumentation (The App)
We modified the Backend to speak "Prometheus". Let's verify it locally or in cluster.

1.  **Check Pods:**
    ```bash
    kubectl get pods -n monitoring
    # You should see: alertmanager, grafana, prometheus, operator
    ```

2.  **Port Forward the Backend (Quick Check):**
    ```bash
    # Find backend pod name
    kubectl get pods
    kubectl port-forward <backend-pod-name> 8080:8080
    ```
3.  **Visit Endpoint:**
    Open browser to: `http://localhost:8080/actuator/prometheus`
    *   **Success:** You see a wall of text starting with `# HELP jvm_memory_used_bytes...`
    *   **Fail:** You see 404.
        > **⚠️ Important:** If you need to rebuild/redeploy the application (e.g. to enable Prometheus metrics), you MUST use `./ops/scripts/deploy_k8s.sh` instead of `kubectl apply` directly. The manifests now use environment variables (`${AWS_ACCOUNT_ID}`) which the script handles for you.

## Step 3: Access Grafana (The Dashboard)
Now let's see the pretty graphs.

1.  **Get Admin Password (if not set in values):**
    ```bash
    kubectl get secret -n monitoring kube-prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
    # OR use "password1234" if you used our values file.
    ```
2.  **Port Forward Grafana:**
    ```bash
    kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring
    ```
3.  **Login:**
    *   URL: `http://localhost:3000`
    *   User: `admin`
    *   Pass: `password1234` (or the decoded secret)

## Step 4: Import Spring Boot Dashboard
1.  In Grafana Sidebar, go **Dashboards -> New -> Import**.
2.  Enter Dashboard ID: **4701** (Standard JVM Dashboard).
3.  Click **Load**.
4.  Select "Prometheus" as the Data Source.
5.  Click **Import**.

## Step 5: "Eyes on Glass"
*   You should see live graphs ofHeap Memory, CPU, and Uptime.
*   Refresh your Frontend (LoadBalancer URL) a few times.
*   Watch the "HTTP Requests" graph jump!

## Troubleshooting
*   **"No Data" in Grafana?**
    *   Check Prometheus Targets: `kubectl port-forward svc/kube-prom-stack-prometheus-operated 9090:9090 -n monitoring`.
    *   Visit `localhost:9090/targets`. Is your Backend listed?
    *   If not, we may need a `ServiceMonitor` (Advanced Phase 5 topic, but usually Service Discovery picks it up via annotations).

## Cleanup (Save Money)
Monitoring uses resources!
```bash
helm uninstall kube-prom-stack -n monitoring
kubectl delete namespace monitoring
```
