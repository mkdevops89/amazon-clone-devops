# 📡 SRE Runbook: Redpanda (Kafka) Operations

## 1. Overview
Redpanda serves as the high-throughput Message Streaming backbone (Event-Driven Architecture) for the platform, substituting traditional Kafka due to its lighter memory footprint natively within Kubernetes.

## 2. Cluster Health Checks
To verify the health of the Redpanda brokers:
```bash
kubectl -n devsecops get pods -l app.kubernetes.io/name=redpanda
```
All 3 StatefulSet replicas must be in a `Running` state to maintain geographic quorum.

## 3. Managing Topics
We use declarative Kubernetes manifests to enforce GitOps over topic schemas.
*   **Target File:** `ops/kafka/k8s/topics.yaml`
*   **Update Procedure:** Only mutate the `topics.yaml` file remotely and allow ArgoCD to securely synchronize the changes (or apply manually: `kubectl apply -f ops/kafka/k8s/topics.yaml`).

## 4. Troubleshooting Consumer Lag
If backend services fail to process events (e.g., Audit Logs):
1. **Check Redpanda Dashboard in Grafana:** Monitor the "Consumer Group Lag" graphs to identify backpressure.
2. **Check App Logs:** `kubectl logs -l app=amazon-backend -n devsecops --tail=100` to find stack traces causing event consumption failure.

## 5. Disk Pressure Mitigation
Redpanda utilizes persistent EBS volumes (`gp3`). If a Prometheus alert (`DiskUsageOver80%`) fires:
1. Aggressively decrease the `retention.ms` setting on high-volume topics in `topics.yaml`.
2. Delete archaic segments manually (Not recommended in production without cluster snapshots).
