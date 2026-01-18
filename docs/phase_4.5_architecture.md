# Phase 4.5 Architecture: Observability Stack

This diagram illustrates how the `kube-prometheus-stack` integrates with our EKS application.

```mermaid
graph TD
    subgraph "Amazon EKS Cluster"
        subgraph "Namespace: default"
            BackendPod["Backend Pod (Spring Boot)"]
            FrontendPod["Frontend Pod (Next.js)"]
        end

        subgraph "Namespace: monitoring"
            Prometheus["Prometheus Server (TSDB)"]
            Grafana["Grafana (Visualization)"]
            AlertManager["AlertManager"]
            NodeExporter["Node Exporter (DaemonSet)"]
        end
    end

    User["DevOps Engineer"] -->|View Dashboards| Grafana
    Grafana -->|Query (PromQL)| Prometheus

    Prometheus --"Scrape (Pull)"--> BackendPod
    BackendPod --"Expose /actuator/prometheus"--> Prometheus

    Prometheus --"Scrape Nodes"--> NodeExporter
    Prometheus --"Fire Alerts"--> AlertManager

    style User fill:#f9f,stroke:#333
    style Prometheus fill:#ff9,stroke:#333
    style Grafana fill:#9ff,stroke:#333
    style BackendPod fill:#9f9,stroke:#333
```

## Data Flow
1.  **Metric Generation**: The Spring Boot Backend calculates its own metrics (CPU, Memory, Request Count) using the `Micrometer` library.
2.  **Exposition**: These metrics are published at `http://<pod-ip>:8080/actuator/prometheus` in a format Prometheus understands.
3.  **Collection (Scraping)**: The Prometheus Server wakes up every 15 seconds (default interval), connects to the Backend Pod, and downloads the current metric values.
4.  **Visualization**: The Engineer logs into Grafana, which sends PromQL queries (e.g., `rate(http_requests_total[5m])`) to Prometheus to draw graphs.
