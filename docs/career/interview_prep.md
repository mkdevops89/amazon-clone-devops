# DevOps Interview Prep: Amazon-Like Application

This project is a "Tier 1" portfolio piece because it demonstrates **Full Lifecycle DevOps**. Use these talking points to explain the project during interviews.

## 🌟 The "Elevator Pitch"
> "I built a full-stack e-commerce platform using a Microservices architecture (Spring Boot & Next.js). I didn't just write the code; I architected the entire infrastructure. I used Terraform to provision resources across AWS, Azure, and GCP, and built a resilient Kubernetes deployment strategy with Helm. I also implemented a complete CI/CD pipeline using Jenkins and GitLab to automate everything from testing to artifact management in Nexus."

## 🔑 Key Concepts to Highlight

### 1. Hybrid/Multi-Cloud Infrastructure (Terraform)
*   **What you did:** You didn't lock yourself into one vendor. You have Terraform modules for AWS (EKS), Azure (AKS), and GCP (GKE).
*   **Why it matters:** Companies love "Cloud Agnostic" skills. It shows you understand the abstractions of infrastructure-as-code (IaC).

### 2. Container Orchestration (Kubernetes & Helm)
*   **What you did:** You didn't just run `docker run`. You created **Helm Charts**.
*   **Key Detail:** "I used Helm to template my manifests, allowing me to easily deploy different environments (staging vs. prod) by just changing a `values.yaml` file."

### 3. The "Stateful" Challenge
*   **What you did:** You orchestrated stateful services (MySQL, Redis, RabbitMQ).
*   **Interview Win:** "Handling stateless apps (frontend) is easy. The real challenge was ensuring the Backend could reliably connect to MySQL and Redis across container restarts. I used Docker Compose health checks and K8s environment variable injection to solve this dependency ordering."

### 4. CI/CD Maturity (Jenkins + Nexus + SonarQube)
*   **What you did:** You implemented a "Quality Gate".
*   **The Workflow:** Code Commit -> Jenkins Build -> Unit Tests -> **SonarQube Analysis** (Quality Gate) -> Push Artifact to **Nexus** -> Deploy.
*   **Why it matters:** This isn't just "deploying"; it's "safe software supply chain management."

## ❓ Potential Interview Questions

**Q: Why did you use RabbitMQ?**
*   **A:** "To decouple the Checkout process. When a user creates an order, we don't want the UI to hang waiting for inventory/shipping services. We push a message to a queue for asynchronous processing, which is critical for scalability in e-commerce."

**Q: How do you handle secrets?**
*   **A:** "Currently, they are in environment variables/TF vars for the demo. In a production environment, I would integrate HashiCorp Vault or AWS Secrets Manager to inject them into the containers at runtime." (This shows you know the "Next Level").

**Q: How do you monitor it?**
*   **A:** "I integrated the Datadog Agent as a sidecar/daemonset. This gives me immediate visibility into container CPU/Memory usage and application logs without SSH-ing into servers."

### 5. Advanced DevOps (Terragrunt & Service Mesh)
*   **Terragrunt:** "I refactored the monolith to use Terragrunt for DRY infrastructure. This allowed me to deploy to Dev, Stage, and Prod using identical modules."
*   **Service Mesh:** "I implemented Istio to gain traffic control. This lets me do Canary Deployments (90% traffic to v1, 10% to v2) and gives me instant observability of 'Golden Signals'."
*   **Security:** "I moved from basic CI scans to a full Snyk + OWASP ZAP pipeline, ensuring I'm catching both dependencies and runtime vulnerabilities."
