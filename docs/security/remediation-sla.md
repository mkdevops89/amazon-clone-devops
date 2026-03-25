# Vulnerability Remediation Service Level Agreements (SLA)

## 1. Mandated Timelines
Any infrastructural vulnerability or CVE discovered during the native DevSecOps execution cadence must be systematically triaged and patched according to the following rigid Federal SLA timelines:

*   **CRITICAL (CVSS 9.0 - 10.0):** Must be definitively patched and pushed to the repository within **48 hours**. Jenkins is structurally configured to immediately abort the CI delivery workflow to reject Production injection.
*   **HIGH (CVSS 7.0 - 8.9):** Must be mechanically patched within **7 days**. Deployment to Production is explicitly halted unless an exception is successfully authorized.
*   **MEDIUM (CVSS 4.0 - 6.9):** Must be addressed within **30 days**. Code fragments are actively permitted to deploy, but are definitively tracked inside the Technical Debt registry mechanism.
*   **LOW (CVSS 0.1 - 3.9):** Monitored and addressed dynamically during heavily scheduled Quarterly operational maintenance windows.
