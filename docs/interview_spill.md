# The "Amazon-Like" Microservices Project: Interview Narrative (The Spill)

> **Context:** This document is your script. It is the "Spill" you give when an interviewer asks, "Tell me about your most complex project" or "Walk me through your portfolio." It treats the project as a fully completed, production-grade implementation.

---

## 1. The Opening Hook (30 Seconds)
**"The Project that Changed How I Engineer"**

"The most significant project in my portfolio is a full-stack, cloud-native E-commerce platform that mimics Amazon's core functionality. I built this to master the transition from legacy virtualization to modern container orchestration. 

It’s not just a web app; it’s a diverse implementation of **DevOps best practices**. I architected it using a **Microservices pattern** (Spring Boot & Next.js), containerized it with **Docker**, orchestrated it with **Kubernetes**, and automated the entire lifecycle with a heterogeneous **CI/CD pipeline** (Jenkins & GitLab). 

I also focused heavily on **Infrastructure as Code**, provisioning resources across **AWS, Azure, and GCP** using Terraform and Terragrunt to simulate a true multi-cloud disaster recovery strategy."

---

## 2. Architecture Deep Dive (Whiteboard Friendly)

If they ask: *"How is it built?"*

### **The Application Layer (Microservices)**
*   **Frontend:** Next.js (React) for Server-Side Rendering (SSR) and SEO.
*   **Backend:** Spring Boot (Java) exposing RESTful APIs.
*   **Authentication:** Stateless JWT (JSON Web Tokens) with Spring Security.

### **The Data Layer (Polyglot Persistence)**
*   **MySQL:** For transactional data (Users, Products, Orders).
*   **MongoDB:** For unstructured product catalogs/reviews (Schemaless).
*   **Redis:** For caching user sessions and "Shopping Cart" data (Speed).
*   **RabbitMQ:** For asynchronous order processing (Decoupling services).
*   **Elasticsearch (ELK):** For high-speed product search and log aggregation.

---

## 3. The "STAR" Stories (Technical Challenges)

Use these when asked: *"Tell me about a time you faced a difficult technical challenge."*

### **Story 1: The "Works on My Machine" Nightmare (Vagrant vs. Docker)**
*   **Situation:** In the early phase, I set up the environment using Vagrant VMs. It worked on my Intel machine but failed catastrophically on my Apple Silicon (M1/M2) peers' machines due to VirtualBox architecture incompatibilities.
*   **Task:** I needed a development environment that was agnostic of the underlying hardware (OS/Chip).
*   **Action:** I migrated the entire local stack to **Docker Compose**. I wrote multi-stage Dockerfiles for the Java and Node apps to keep images light (using Alpine Linux). I used `docker-compose.yml` to define service dependencies (`depends_on`) and health checks.
*   **Result:** Onboarding time dropped from 2 hours (debugging VMs) to 5 minutes (`docker-compose up`). This taught me the real value of container isolation.

### **Story 2: The "Blind Spot" (Observability & Monitoring)**
*   **Situation:** During load testing, the checkout service would randomly time out, but the system logs showed no errors. I was flying blind.
*   **Task:** I needed to see "inside" the containers to understand resource usage and latency.
*   **Action:** I implemented a full **Observability Stack**:
    *   **Prometheus:** To scrape metrics (CPU, Memory, JVM Heap) from the pods.
    *   **Grafana:** To visualize these metrics on a dashboard.
    *   **ELK Stack (Elasticsearch, Logstash, Kibana):** To aggregate logs from all microservices into one searchable interface.
*   **Result:** The Grafana dashboard revealed that the JVM memory was spiking during checkout. I tuned the `Xmx` (Heap Size) settings in the Dockerfile, and the timeouts disappeared.

### **Story 3: The "Insecure Code" Fix (DevSecOps)**
*   **Situation:** I realized that we were waiting until *after* deployment to check for vulnerabilities. If a bad library made it to Prod, we were exposed.
*   **Task:** I needed to "Shift Left"—moving security checks earlier in the pipeline.
*   **Action:** I integrated **Trivy** and **SonarQube** into the Jenkins pipeline:
    *   **Trivy (Filesystem Mode):** Scans the repo for secret keys *before* the build.
    *   **SonarQube:** Runs static analysis (SAST) to find bugs and code smells.
    *   **Trivy (Image Mode):** Scans the final Docker image for CVEs *before* pushing to Nexus.
*   **Result:** The pipeline now automatically "fails the build" if a Critical vulnerability is found. I successfully blocked a deployment that included a vulnerable version of `log4j`.

### **Story 4: Fixing "Configuration Drift" with GitOps**
*   **Situation:** I found myself manually applying `kubectl apply -f` changes to the cluster. This led to "Shadow IT" where the live cluster config didn't match the Git repo.
*   **Task:** I needed a single source of truth for the cluster state.
*   **Action:** I implemented **ArgoCD** for continuous deployment (GitOps). I set up an Argo Application that watched my `helm-charts` repository.
*   **Result:** Now, to deploy a change, I just commit code. ArgoCD automatically syncs the cluster. If someone manually hacks the cluster, ArgoCD detects the "Out of Sync" state and self-heals it back to the Git state.

### Story 5: Battle Scars (Real Bugs I Fixed in Prod)
*   **The "Phantom Variable" (Next.js Build vs. Runtime):**
    *   *Situation:* After deploying to EC2, the Frontend kept trying to connect to `localhost` instead of the server IP, even though I set the environment variable.
    *   *Root Cause:* I learned that Next.js 'Client Components' bake `NEXT_PUBLIC_` variables in at **Build Time**, not Runtime. My Dockerfile was missing the `ARG` instruction, so the build process ignored my environment variable.
    *   *Fix:* I updated the `Dockerfile` to accept build `ARG`s and passed them via `docker-compose.yml`.

*   **The "Legacy Drift" (Docker V1 vs V2):**
    *   *Situation:* My deployment script failed on EC2 with an obscure `KeyError: 'ContainerConfig'`.
    *   *Root Cause:* The server had an ancient version of Docker Compose (V1) installed by default, which lacked features my V2 syntax required.
    *   *Fix:* I wrote a bash automation script to remove the old version and enforce the installation of the official Docker Compose V2 plugin from the Docker repo.

*   **The "Invisible Data" (Code vs. Data Mismatch):**
    *   *Situation:* The API was returning data, the images existed on the server, but the UI showed placeholders.
    *   *Root Cause:* The frontend component was hardcoded to display a "placeholder div" and didn't actually have an `<img>` tag mapped to the data prop.
    *   *Fix:* I refactored the component to correctly render the image using the data from the API.

---

## 4. The DevOps Toolchain (Why I Chose What I Chose)

*   **Why Terraform?** "Cloud Agnosticism. I didn't want to learn CloudFormation (AWS only) or ARM (Azure only). HCL lets me manage all three."
*   **Why Jenkins?** "Extensibility. I needed complex Groovy pipelines to handle the 'Build -> Test -> Scan -> Push' workflow that simpler tools struggled with."
*   **Why Istio (Service Mesh)?** "Ideally for Traffic Splitting (Canary Deploys) and mTLS (Security). It allowed me to secure service-to-service communication without rewriting application code."

---

## 5. Security & DevSecOps Strategy
*"Security isn't an afterthought; it's pipeline-native."*
*   **Static Application Security Testing (SAST):** SonarQube.
*   **Software Composition Analysis (SCA):** OWASP Dependency Check.
*   **Container Security:** Trivy (Scanning for CVEs in Alpine/Debian base images).
*   **Secrets Management:** HashiCorp Vault (No hardcoded passwords in Git!).

## 6. Future Roadmap (Showing Seniority)

If asked: *"What would you improve?"*

"If I had more time, I would focus on **Distributed Tracing** with Jaeger. Right now, if a request fails between the Frontend and Backend, it's a black box. Tracing would let me see exactly which microservice caused the latency or error."
