# DevSecOps Incident Response Playbook

## 1. Pipeline Blocking Events (Jenkins Trivy Gate)
If the Jenkins `Compliance: STIG Gate` or `Security: Image Scan` aborts an ArgoCD deployment synchronization:
1. **Locate the Block:** Access the active Jenkins console output and identify the specific CVE or misconfiguration parameter (e.g., `runAsNonRoot: false`).
2. **Consult the SLA:** Refer to `docs/security/remediation-sla.md`. If the vulnerability is `CRITICAL`, it is forcefully bound to a 48-hour remediation cycle. 
3. **Remediation Action:** The developer must structurally modify the `Dockerfile` backend layer or the `ops/k8s/` configuration manifest securely on a feature branch.
4. **Exception Path:** If functionally unpatchable (e.g., zero-day vendor wait time), engineers must forcefully escalate to the ISSO to author a `security-exception-process.md` ticket and inject the target CVE into the codebase `.trivyignore`.

## 2. Cluster Blocking Events (Kyverno Webhook)
If ArgoCD dynamically reports an `OutOfSync` failure state because the Kubernetes API natively rejected a Pod manifest:
1. **Pull the Native Audit Logs:** `kubectl get events -n <namespace> | grep -i kyverno`
2. **Identify the Violating Resource:** Locate the Kyverno constraint evaluation (e.g., `Root filesystem must be read-only`).
3. **Mechanical Remediation:** The platform engineer must physically insert `readOnlyRootFilesystem: true` within the `securityContext` array of the respective upstream Helm chart.

## 3. Formal Breach Response
If TruffleHog (Secrets Scan) triggers an immediate pipeline halt due to an exposed AWS or asymmetric IAM key detected in the commit history:
1. **Immediate Disruption:** The compromised payload string must be entirely invalidated natively within AWS IAM or the explicit third-party console.
2. **Key Rotation:** Generate a secure new asymmetric key and selectively update the Jenkins Credentials framework or the AWS Secrets Manager.
3. **Forensic Archival:** Request an auditor forcibly pull the pipeline execution artifacts from the immutable `amazon-clone-security-evidence` S3 bucket to provide mathematical proof of the interception timeline.
