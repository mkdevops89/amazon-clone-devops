# Phase 18 Walkthrough: Ultimate Enterprise Observability (The Correlation Engine)

Welcome to Phase 18! This guide provides detailed, step-by-step instructions on how to upgrade your existing baseline infrastructure into a Day-2 SRE Enterprise Correlation Engine. 

By the end of this phase, you will have transformed Grafana from a simple visualization tool into a Single Pane of Glass integrating AWS Billing, GitOps Deployments, and Kubernetes kernel security—all secured behind Amazon Cognito SSO. Furthermore, you will significantly reduce Elasticsearch storage costs using Index Lifecycle Management (ILM) and Ingest Pipelines.

---

## 🏗️ Step 1: Hardening Access with Amazon Cognito (SSO)

We need to eliminate the insecure `admin/admin` default credentials and force all Grafana users to authenticate via your AWS IAM/Cognito environment.

### 1. Provision a Dedicated Cognito App Client for Grafana
Run the following AWS CLI command to generate an App Client with an explicit `ClientSecret` and authorized OAuth callback URLs mapping to Grafana.
*(Make sure to replace `US_EAST_1_YOUR_POOL_ID` with your actual Cognito User Pool ID).*

```bash
aws cognito-idp create-user-pool-client \
    --user-pool-id US_EAST_1_YOUR_POOL_ID \
    --client-name grafana-sso-client \
    --generate-secret \
    --callback-urls "http://localhost:8080/login/generic_oauth" \
    --logout-urls "http://localhost:8080/logout" \
    --supported-identity-providers "COGNITO" \
    --allowed-o-auth-flows "code" "implicit" \
    --allowed-o-auth-scopes "email" "openid" "profile" \
    --allowed-o-auth-flows-user-pool-client
```
Copy the `ClientId` and `ClientSecret` from the JSON response.

### 2. Inject the Client Secret into Kubernetes
Because Grafana correctly considers the Cognito Secret to be sensitive, do not put it in plaintext YAML. Store it inside the cluster as a native Kubernetes Secret.

```bash
kubectl create secret generic grafana-sso-credentials \
  --from-literal=GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=YOUR_COGNITO_CLIENT_SECRET \
  -n monitoring
```

### 3. Configure the Grafana Helm Chart
Update your `prometheus-values.yaml` file to enforce SSO and map Cognito IAM Groups directly to Grafana RBAC roles (e.g., Cognito `Admin` maps to Grafana `Admin`, everyone else becomes a Read-Only `Viewer`).

```yaml
grafana:
  grafana.ini:
    server:
      root_url: http://localhost:8080
    auth:
      disable_login_form: true
      oauth_auto_login: true
    auth.generic_oauth:
      enabled: true
      name: Amazon Cognito
      allow_sign_up: true
      client_id: YOUR_COGNITO_CLIENT_ID
      scopes: openid profile email
      auth_url: https://YOUR_COGNITO_DOMAIN.auth.us-east-1.amazoncognito.com/oauth2/authorize
      token_url: https://YOUR_COGNITO_DOMAIN.auth.us-east-1.amazoncognito.com/oauth2/token
      api_url: https://YOUR_COGNITO_DOMAIN.auth.us-east-1.amazoncognito.com/oauth2/userInfo
      role_attribute_path: contains(cognito:groups[*], 'Admin') && 'Admin' || 'Viewer'
  envFromSecret: grafana-sso-credentials
```

---

## 🔍 Step 2: Correlating Metrics and Logs (ELK)

An SRE needs context. We will wire the Elasticsearch database natively into Grafana so team members can instantly correlate a Prometheus CPU spike with the exact application log from that exact microsecond.

### 1. Define the Additional Data Source
Append the following block to your `prometheus-values.yaml` under the `grafana` configuration, mapping to your internal `logging` namespace:

```yaml
grafana:
  additionalDataSources:
    - name: Elasticsearch
      type: elasticsearch
      access: proxy
      url: http://elasticsearch-master.logging.svc.cluster.local:9200
      database: "logs-*"
      jsonData:
        timeField: "@timestamp"
        esVersion: "8.0.0"
```

### 2. Execute the Helm Upgrade
Push these changes to the Kubernetes environment:

```bash
helm upgrade -n monitoring kube-prom-stack prometheus-community/kube-prometheus-stack -f ops/k8s/monitoring/prometheus-values.yaml
```

---

## 📊 Step 3: Creating the Enterprise Dashboards

Instead of using generic host-CPU monitors, use the provided JSON dashboards explicitly built for Day-2 Operations. We authored three custom dashboards inside `ops/k8s/monitoring/dashboards/`: `finops.json`, `delivery.json`, and `security.json`.

### How to Import the Dashboards into Grafana:
1.  **Port-Forward Grafana:** Ensure you can access the UI:
    ```bash
    kubectl port-forward svc/kube-prom-stack-grafana 8080:80 -n monitoring
    ```
2.  **Open the Browser:** Navigate to `http://localhost:8080`.
3.  **Navigate to Dashboards:** On the left-hand navigation pane, click the **Dashboards** icon (the four squares) and select **Import**.
4.  **Upload JSON:** You can either:
    *   Click **Upload JSON file** and select the `.json` files from `ops/k8s/monitoring/dashboards/`.
    *   Open the `.json` files in a text editor, copy the entire raw JSON text, and paste it into the **Import via panel json** box.
5.  **Click Load:** Ensure the default data source is mapped to your `Prometheus` backend, and click **Import**.

*(Note: In a true immutable GitOps flow, you would configure a Grafana `DashboardProvider` ConfigMap to automatically sync these files, but manual import is ideal for testing and validation).*

---

## 🗄️ Step 4: Advanced Elasticsearch Architecture (ELK Optimization)

By default, Elasticsearch is a flat log dumping ground. Left unchecked, your `logs-*` index will quickly bankrupt the AWS EBS Volume. We must structure it with Ingest Pipelines and Index Lifecycle Management (ILM).

### 1. Authenticate with Elasticsearch
Fetch your Elasticsearch superuser password natively from the cluster:
```bash
kubectl get secret elasticsearch-master-credentials -n logging -o jsonpath='{.data.password}' | base64 -d
```

### 2. Enforce an ILM Auto-Delete Policy
Create a JSON policy telling Elasticsearch to rollover logs into Data Streams and automatically execute hard-deletes after 30 days to save disk capacity.

```bash
kubectl run curl-ilm --image=curlimages/curl --restart=Never -n logging -- curl -k -u elastic:YOUR_PASSWORD -X PUT "https://elasticsearch-master:9200/_ilm/policy/logs-ilm-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": { "rollover": { "max_age": "7d", "max_size": "50gb" } }
      },
      "delete": {
        "min_age": "30d",
        "actions": { "delete": {} }
      }
    }
  }
}'
```

### 3. Create an Ingest Pipeline (Log Cleaner)
Drop noisy debug fields before they are even saved, and inject structured production tags.

```bash
kubectl run curl-ingest --image=curlimages/curl --restart=Never -n logging -- curl -k -u elastic:YOUR_PASSWORD -X PUT "https://elasticsearch-master:9200/_ingest/pipeline/logs-pipeline" -H 'Content-Type: application/json' -d'
{
  "description": "Enterprise Logging Pipeline for DevSecOps",
  "processors": [
    { "set": { "field": "environment", "value": "production" } },
    { "remove": { "field": ["message.debug", "agent.ephemeral_id"], "ignore_missing": true } }
  ]
}'
```

### 4. Create the Final Index Template
Bind the pipeline and the ILM policy together so that *any* new index matching `logs-*` automatically utilizes the advanced SRE logic.

```bash
kubectl run curl-template --image=curlimages/curl --restart=Never -n logging -- curl -k -u elastic:YOUR_PASSWORD -X PUT "https://elasticsearch-master:9200/_index_template/logs-template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["logs-*"],
  "data_stream": { },
  "template": {
    "settings": {
      "index.lifecycle.name": "logs-ilm-policy",
      "index.default_pipeline": "logs-pipeline",
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "kubernetes": {
          "properties": {
            "pod_name": { "type": "keyword" },
            "namespace": { "type": "keyword" }
          }
        },
        "message": { "type": "text" }
      }
    }
  }
}'
```

---

## ✅ Step 5: Live Test Cases (Verification)

To definitively prove your SRE configuration was successful, execute the following 5 live test cases.

### Test Case 1: Amazon Cognito SSO Authentication
1. Navigate to `http://localhost:8080`.
2. **Expected Result:** You should be instantly and forcefully redirected to the Amazon Cognito Hosted UI login screen. The standard Grafana `admin/admin` username/password prompt should no longer exist. Logging in with a registered Cognito user will redirect you back to the dashboards.

### Test Case 2: Enterprise FinOps Visualization
1. Open the **AWS FinOps Dashboard** in Grafana.
2. **Expected Result:** Left panel maps the total AWS daily cost. The right panel explicitly correlates the execution of the `cost-optimizer` Lambda, proving it terminated idle EC2/RDS resources overnight.

### Test Case 3: GitOps Delivery Tracking
1. Open the **Enterprise GitOps Delivery Pipeline** in Grafana.
2. Trigger a benign `git commit` to your repository.
3. **Expected Result:** The *Deployed Git Commit Hash* panel updates in real-time, matching the latest `git log` hash. The *ArgoCD Sync State* transitions briefly to `OutOfSync` before settling back to `Healthy/Synced`.

### Test Case 4: Security NOC (Zero-Trust Blocks)
1. Open the **Enterprise Security NOC** in Grafana.
2. Attempt to deploy a malicious, unsigned pod to the cluster:
   `kubectl run malicious-nginx --image=nginx`
3. **Expected Result:** The terminal returns `admission webhook "mutate.kyverno.svc-fail" denied the request`. Immediately look at the Grafana dashboard—the visual graph will explicitly spike, logging the exact Zero-Trust supply chain block.

### Test Case 5: ELK Ingest Pipeline Validation
1. Use an internal pod to POST a mock pod payload with a noisy `message.debug` string:
   ```bash
   kubectl run curl-test-log --image=curlimages/curl --restart=Never -n logging -- curl -k -u elastic:YOUR_PASSWORD -X POST "https://elasticsearch-master:9200/logs-test-pipeline-1/_doc" -H 'Content-Type: application/json' -d'{"@timestamp": "2026-03-16T10:45:00.000Z","message": "Pipeline active","message.debug": "Useless debug trace 0x123", "kubernetes": {"pod_name": "test"}}'
   ```
2. Retrieve the log natively:
   ```bash
   kubectl run curl-test-read --image=curlimages/curl --restart=Never -n logging -- curl -k -u elastic:YOUR_PASSWORD -X GET "https://elasticsearch-master:9200/logs-test-pipeline-1/_search?q=*"
   ```
3. **Expected Result:** In the JSON output, `message.debug` has been completely stripped out, and an `environment: production` flag has been dynamically injected by the Pipeline.

---
**🎉 Congratulations!** You have successfully constructed and verified the definitive SRE Correlation Engine!
