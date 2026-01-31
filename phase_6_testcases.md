# Phase 6: Test Cases & Validation Criteria 🛡️

This document outlines the tests to verify the integrity of the CI/CD pipeline and DevSecOps controls.

---

## 🟦 Phase 6a: GitHub Actions Validation

### ✅ TC-6A-01: Secret Detection (TruffleHog)
**Scenario:** Verify that committing secret keys breaks the build.
1.  **Action:** Create a .txt file name it `secrets.txt` with content `aws secret key and value`.
2.  **Action:** Commit and push to `phase-6a-githubactions`.
3.  **Expected Result:** The GitHub Action `DevSecOps CI` fails at the "TruffleHog" step.
4.  **Recovery:** Remove the file, squash commits (or remove from history), and push again. The build should pass.

### ✅ TC-6A-02: Dependency Scanning (Snyk)
**Scenario:** Verify vulnerability reporting for libraries.
1.  **Action:** Ensure `frontend/package.json` or `backend/pom.xml` are present.
2.  **Action:** Trigger the workflow.
3.  **Expected Result:** "Snyk Monitor" step runs successfully (may warn if vulnerabilities found, but pipeline continues if configured to warn-only).
4.  **Verification:** Check the Github Actions logs for "Vulnerabilities found".

### ✅ TC-6A-03: Code Quality (SonarCloud)
**Scenario:** Verify code analysis integration.
1.  **Action:** Trigger the workflow.
2.  **Expected Result:** "SonarCloud Scan" step completes.
3.  **Verification:** Log in to SonarCloud.io and verify the project dashboard shows "Passed" or specific code smells.

### ✅ TC-6A-04: Deployment & DAST (ZAP)
**Scenario:** Verify successful deployment and runtime scanning.
1.  **Action:** Go to Actions -> "Deploy App to EKS" -> Run Workflow.
2.  **Expected Result:**
    *   Docker Image built and pushed to ECR.
    *   `deploy_k8s.sh` script executes successfully.
    *   **OWASP ZAP** step runs and generates a report in the logs (checking for XSS, Headers, etc.).
3.  **Verification:** Visit `https://www.devcloudproject.com` and ensure the site is live.

---

## 🟧 Phase 6b: Jenkins Validation (Future)
*   **TC-6B-01:** Build Trigger via Webhook.
*   **TC-6B-02:** Artifact Push to Nexus.
