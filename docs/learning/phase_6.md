# Phase 6: Code Quality (SonarQube)

**Goal**: Automatically reject code that sucks.
**Role**: Quality Assurance (QA) Engineer.

## 🛠 Prerequisites
*   **SonarQube**: Running (`docker-compose up -d`).
*   **Maven**: Installed.

## 📝 Step-by-Step Runbook

### 1. Start SonarQube
Ensure the container is healthy.
```bash
docker ps | grep sonar
# Access UI: http://localhost:9000
# Login: admin / admin (Change password on first login)
```

### 2. Create a Token
1.  Go to **My Account** -> **Security**.
2.  Generate Token: Name `local-analysis`.
3.  **Copy this token**.

### 3. Run Analysis (Local)
Before pushing to Git, scan it locally.
```bash
cd backend
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=amazon-backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<YOUR_TOKEN>
```

### 4. View Results
1.  Go back to `http://localhost:9000`.
2.  Click on `amazon-backend`.
3.  Check:
    *   **Bugs**: Code that will crash.
    *   **Vulnerabilities**: Security holes.
    *   **Duplications**: Copy-pasted code.

### 5. Simulate a Failure (Quality Gate)
1.  In SonarQube, go to **Quality Gates**.
2.  Create a strict gate: "Coverage < 80% = FAIL".
3.  Assign it to `amazon-backend`.
4.  Run the Maven command again.
5.  **Result**: The build should FAIL in your terminal. This is how we protect Main Branch.

## 🚀 Troubleshooting
*   **"Fail to request"**: SonarQube is not up. Check `docker logs sonarqube`. It is heavy (needs 2GB RAM).
*   **"Not authorized"**: Your token is wrong. Re-generate it.
