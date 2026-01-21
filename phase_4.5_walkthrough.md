# Phase 4.5: Observability "Eyes on Glass" 🔭

This phase enables full-stack monitoring using the industry-standard **Kube Prometheus Stack**. You will visualize your Java Backend's memory usage and request latency in real-time.

---

## 🛠️ Prerequisites
1.  **EKS Cluster Running** (from Phase 4).
2.  **Backend deployed** (from Phase 4).
3.  **Helm Installed**:
    *   **Mac:** `brew install helm`
    *   **Linux:** `curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`

---

## 📍 Setup: Environment
Ensure you are in the project root directory so commands reference the correct paths.

1.  **Navigate to Project Root:**
    ```bash
    cd /Users/michael/Documents/amazonlikeapp
    # Verify: ls -F should show backend/ frontend/ ops/
    ```

---

## 📊 Step 1: Install Prometheus & Grafana
Use **Helm** (Kubernetes Package Manager) to install the monitoring stack.

1.  **Add Prometheus Repo:**
    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    ```
2.  **Create Namespace:**
    ```bash
    kubectl create namespace monitoring
    ```
3.  **Install Stack:**
    Deploy using the custom configuration file:
    ```bash
    helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
      -n monitoring \
      -f ops/k8s/monitoring/prometheus-values.yaml
    ```

---

## 🔍 Step 2: Verify Instrumentation

(Steps 1-3 remain the same)

---

## 📈 Step 3: Access Grafana Dashboard
Access the visual dashboard to view the metrics.

1.  **Get Admin Password:**
    Since we didn't set a password, Helm generated a secure one. Let's retrieve it:
    ```bash
    kubectl get secret -n monitoring kube-prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
    ```

2.  **Port Forward Grafana:**
    ```bash
    kubectl port-forward svc/kube-prom-stack-grafana 3000:80 -n monitoring
    ```

3.  **Login:**
    *   **URL:** `http://localhost:3000`
    *   **User:** `admin`
    *   **Password:** (The one you just retrieved)

---

## 🖥️ Step 4: Import Spring Boot Dashboard
1.  In Grafana, go to **Dashboards -> New -> Import**.
2.  Enter Dashboard ID: **4701** (Standard JVM Dashboard).
3.  Click **Load**.
4.  Select **"Prometheus"** as the Data Source.
5.  Click **Import**.

---

## 👁️ Step 5: "Eyes on Glass"
1.  Observe the live graphs for Heap Memory, CPU, and Uptime.
2.  Refresh your **Frontend Application** (the LoadBalancer URL) multiple times.
3.  Watch the "HTTP Requests" graph spike in Grafana!

---

## ❓ Troubleshooting
*   **"No Data" in Grafana?**
    1.  Port-forward Prometheus: `kubectl port-forward svc/kube-prom-stack-prometheus-operated 9090:9090 -n monitoring`.
    2.  Check Targets at `http://localhost:9090/targets`. Is `amazon-backend` listed?
    3.  If not, checking the `Service` labels in `ops/k8s/backend.yaml`.

---

## 🧹 Cleanup
To saves resources:
```bash
helm uninstall kube-prom-stack -n monitoring
kubectl delete namespace monitoring
```
