# Phase 6c Test Cases: SonarQube & GitLab

## 🔍 Test Case 1: SonarQube Infrastructure
*   **Action:** Run `kubectl get pods -n devsecops -l app=sonarqube`
*   **Expected:** Pod status is `Running` (1/1).
*   **Action:** Visit `https://sonarqube.devcloudproject.com`
*   **Expected:** Login page loads successfully.
*   **Action:** Check Storage `kubectl get pvc -n devsecops sonarqube-pvc`
*   **Expected:** Status is `Bound`.

## 🦊 Test Case 2: GitLab Runner Connectivity
*   **Action:** Run `kubectl get pods -n devsecops -l app=gitlab-runner`
*   **Expected:** Pod status is `Running`.
*   **Action:** Check logs `kubectl logs -n devsecops -l app=gitlab-runner`
*   **Expected:** Message "Runner registered successfully" or "Configuration loaded".

## 🧪 Test Case 3: Pipeline Execution
*   **Action:** Push a commit to `phase-6c-gitlab`.
*   **Expected:** GitLab Pipeline starts automatically.
*   **Action:** Check the `sast` job in GitLab.
*   **Expected:** Job succeeds, logs show "ANALYSIS SUCCESSFUL".

## 🛡️ Test Case 4: Quality Gate
*   **Action:** Check SonarQube Dashboard.
*   **Expected:** Project `amazon-clone-backend` appears with stats (Lines of Code, Bugs, Vulnerabilities).
