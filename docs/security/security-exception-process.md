# Security Exception Processing

## 1. Exception Scope
Not all vulnerabilities can be algorithmically patched in real-time (e.g., zero-day exploits actively awaiting explicit upstream vendor container fixes or architectural shifts causing massive breaking changes). In these restricted scenarios, a formal Security Exception must be physically authored and approved to allow the Jenkins pipeline logic to bypass the `CRITICAL` gateway matrix.

## 2. Required Documentation
Engineers requesting a mandatory SLA override must permanently file a JIRA ticket containing:
1. **The Target CVE Identifier** (e.g., CVE-2026-61234).
2. **Business Justification** detailing comprehensively why the patch cannot theoretically be synchronized immediately.
3. **Compensating Controls:** Mathematical evidence of Web Application Firewall (WAF) blocks, Kyverno Native API policies, or strict EKS Security Groups actively isolating and mitigating the network attack scope.
4. **Expiration Date:** Standard exceptions structurally expire at a maximum of 90 days. Post-execution, the pipeline will dynamically revert to a highly-restrictive blocking posture.

## 3. Override Execution
Upon successful manual authorization by the Information Systems Security Officer (ISSO) and the Platform Engineering Lead, the DevSecOps team will manually compile the explicit CVE string into the tracking `.trivyignore` baseline construct in Git to safely unblock the automated pipeline delivery matrices.
