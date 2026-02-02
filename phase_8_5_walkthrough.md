# Phase 8.5: Advanced Observability Walkthrough

We have defined the "Eyes" of our system. Now let's turn them on.

## 1. The Dashboards
I have created 3 JSON dashboard definitions in `ops/k8s/monitoring/dashboards/`:

1.  **FinOps & Efficiency (`finops.json`)**:
    *   **Goal**: Visualize the $ Savings from Spot Instances.
    *   **Panels**: Spot Count vs On-Demand Count, Estimated Monthly Bill.
2.  **Node Health (`nodes.json`)**:
    *   **Goal**: Visualize the Stability of your Cluster.
    *   **Panels**: Memory Pressure, Disk Pressure.
3.  **App Golden Signals (`apps.json`)**:
    *   **Goal**: Visualize Application Performance.
    *   **Panels**: Latency, Error Rate (5xx), Throughput.

## 2. How to Import (Manual)
Since you already have Grafana running at `grafana.devcloudproject.com`, the fastest way to see these is via the UI:

1.  **Open Grafana**: Log in to your instance.
2.  **Go to Dashboards**: Click the (+) icon -> "Import".
3.  **Copy JSON**:
    *   Open `ops/k8s/monitoring/dashboards/finops.json` in VS Code.
    *   Copy the entire content.
    *   Paste it into the "Import via panel json" box in Grafana.
    *   Click **Load** -> **Import**.
4.  **Repeat**: Do the same for `nodes.json` and `apps.json`.

## 3. Verify Application Scraper
To make `apps.json` work, Prometheus must be scraping your backend.
Apply the monitor configuration:
```bash
kubectl apply -f ops/k8s/monitoring/backend-monitor.yaml
```

## 4. Push Your Work
Save these assets to your new branch:
```bash
git add ops/k8s/monitoring/dashboards/
git commit -m "feat(obs): add finops, node, and app health dashboards"
git push -u origin phase-8.5-advancedobservability
```
