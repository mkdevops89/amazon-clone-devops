# 🛠️ SRE Runbook: Platform Maintenance Mode

## 1. Overview
This runbook details the procedures for placing the Amazon Clone platform into "Maintenance Mode." It ensures traffic is cleanly severed from the application logic while keeping the monitoring stack (Grafana) online to observe infrastructure health during the maintenance window.

## 2. Prerequisites
- `kubectl` configured with EKS cluster access.
- Execution privileges to run the `enter-maintenance.sh` script.

## 3. Entering Maintenance Mode
We automate this process to execute safe GitOps overrides.
1. Execute the maintenance script:
   ```bash
   ./ops/scripts/maintenance/enter-maintenance.sh
   ```
2. **What this script does:**
   - **(CRITICAL):** Patches the ArgoCD `amazon-app` Custom Resource Definition to temporarily disable `selfHeal` and `automated` sync. If we do not do this step, ArgoCD will instantly fight our manual maintenance operations and scale the pods right back up.
   - Scales the `amazon-frontend` deployment replicas down to `0`.
   - Scales the `amazon-backend` deployment replicas down to `0`.
   - Pre-emptively severs the AWS Load Balancer Controller Ingress logic for core applications to prevent routing anomalies.

## 4. Validating Maintenance State
- Verify pods scaled down: `kubectl get pods -n devsecops | grep amazon` (Should return nothing).
- Test traffic flow: Web requests to application paths should cleanly fail or return a 503 Service Unavailable directly at the edge layer.
- Ensure that `https://grafana.devcloudproject.com` remains fully accessible to monitor database patches.

## 5. Exiting Maintenance Mode & Rollback
Once database migrations or infrastructure patches are entirely complete, we relinquish manual control back to ArgoCD.
1. Execute the rollback script:
   ```bash
   ./ops/scripts/maintenance/exit-maintenance.sh
   ```
2. **What this script does:**
   - Reactivates the ArgoCD `selfHeal` policy. ArgoCD will instantly notice the cluster is missing its deployment pods, read the source of truth from Git, and aggressively scale the environment back up to full capacity automatically.
3. Verify application health via the `/actuator/health` endpoint and Grafana dashboards.
