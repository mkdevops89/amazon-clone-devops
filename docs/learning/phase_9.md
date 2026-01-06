# Phase 9: Observability (Monitoring Stack)

**Goal**: "See" inside the cluster using Prometheus (Metrics) and Grafana (Dashboards).
**Role**: SRE (Site Reliability Engineer).

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running.
*   **Helm**: Installed.

## 📝 Step-by-Step Runbook

### 1. Install the Stack (Kube-Prometheus-Stack)
We use the community standard "Operator" which installs Prometheus, Grafana, NodeExporter, and AlertManager all at once.
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```

### 2. Verify Components
It installs *a lot* of pods. Wait for them to be `Running`.
```bash
kubectl get pods -n monitoring
# Look for:
# - monitoring-grafana
# - monitoring-kube-prometheus-st-prometheus
# - monitoring-prometheus-node-exporter
```

### 3. Access Grafana
Port-forward to see the UI.
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```
*   **URL**: `http://localhost:3000`
*   **User**: `admin`
*   **Password**: `prom-operator` (default) or check the secret if that fails.

### 4. Import a Dashboard
Grafana is empty by default. Let's add a "Spring Boot" dashboard.
1.  Go to **Dashboards** -> **New** -> **Import**.
2.  Enter ID: `12900` (JVM Micrometer) or `19004`.
3.  Click **Load**.
4.  Select Source: `Prometheus`.
5.  Click **Import**.

### 5. Generate Metrics
The dashboard might look flat. Send some traffic!
```bash
# In a separate terminal
while true; do curl http://localhost:8080/api/products; sleep 0.5; done
```
*   Go back to Grafana.
*   Change time range to "Last 5 minutes".
*   Witness the "Requests/Sec" line go up. 📈

## 🚀 Troubleshooting
*   **"No Data"**: Your Spring Boot app might not be scraping. Check if the Pod has annotations:
    ```yaml
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8080"
    ```
*   **"CrashLoopBackOff"**: If Prometheus runs out of RAM, increase the resource limits in Helm values.

## 🚀 Next Level
Prometheus tells you **"traffic is high"**. But why?
Go to **[Phase 12: Centralized Logging (ELK)](./phase_12.md)** to search the logs and find the specific error message.
