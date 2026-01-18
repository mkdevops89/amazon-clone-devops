# Phase 4.5 Test Cases: Observability

## Test Setup
*   Cluster is running.
*   Monitoring Namespace exists (`kubectl get ns monitoring`).
*   Backend Pod is running.

## Test Case 1: Actuator Local Verification
**Goal:** Ensure the Java App is actually exposing metrics.
1.  **Command:** `kubectl port-forward <backend-pod> 8080:8080`
2.  **Action:** `curl http://localhost:8080/actuator/prometheus`
3.  **Expected:** A text response containing metrics like `jvm_memory_used_bytes`.
4.  **Auto-Fail:** If you get a 404, the `pom.xml` change was not built into the image.

## Test Case 2: Prometheus Target Status
**Goal:** Ensure Prometheus is scraping the Pod.
1.  **Command:** `kubectl port-forward svc/kube-prom-stack-prometheus-operated -n monitoring 9090:9090`
2.  **Action:** Visit `http://localhost:9090/targets`
3.  **Expected:** The backend target shows State="UP".
4.  **Note:** If it's missing, we need to add a `ServiceMonitor` or annotations.

## Test Case 3: Grafana Dashboard
**Goal:** Visual confirmation.
1.  **Command:** `kubectl port-forward svc/kube-prom-stack-grafana -n monitoring 3000:80`
2.  **Action:** Navigate to the imported JVM Dashboard.
3.  **Expected:** Graphs are populated with data (not "No Data").

## Test Case 4: Alert Manager (Bonus)
**Goal:** Trigger an alert.
1.  **Action:** Kill the backend pod `kubectl delete pod <backend>`.
2.  **Expected:** See "TargetDown" alert firing in Prometheus Alerts tab (`http://localhost:9090/alerts`).
