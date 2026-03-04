# 📦 Amazon-Like E-Commerce Platform (Phase 10: Features & Fixes)

## 🚀 Phase 10 Overview
This branch (`phase-10-features`) represents the **Application Polish & Core Infrastructure Finalization** milestone. 

After investing heavily in DevOps infrastructure, CI/CD pipelines, FinOps, and Observability, we dedicate this phase to resolving core application bugs, modernizing the user interface, improving frontend/backend synchronization, and securing our Kubernetes API routing.

Additionally, we mature the Terraform codebase by migrating from local state files to a secure **Remote State Backend** hosted in an S3 bucket with DynamoDB state-locking.

### 🛠️ Key Features & Bug Fixes
1. **Frontend Optimization (Cart Synchronization)**
   * **The Problem**: The React Navbar cart count was relying on cached `localStorage` data, creating synchronization issues between browser tabs and the backend database.
   * **The Fix**: The Navbar now actively fetches the authoritative cart count directly from the Spring Boot API, ensuring perfect consistency for the user.
2. **UI Modernization**
   * **The Process**: The frontend application received a visual facelift, cleaning up the product displays, typography, and button states to feel more like a premium e-commerce experience.
3. **Ingress configuration & API Security**
   * **The Problem**: Users were experiencing "No products found" and "Add to Cart" blocking errors.
   * **The Fix**: The Kubernetes NGINX Ingress Controller configuration was corrected to allow public traffic to safely reach the `/products/**` endpoints by properly handling prefix stripping and path routing.
4. **Terraform Best Practices (Remote State)**
   * **The Process**: The `main.tf` configuration was updated to use a remote `s3` backend. This safely stores the infrastructure state in AWS, enables team collaboration via DynamoDB locking, and prevents accidental drift or state corruption.
5. **Hybrid Node Resizing**
   * **The Process**: The EKS managed node groups were resized and the EKS module was strictly pinned to version `20.33.1` to prevent Terraform drift detection issues observed during CI/CD pipeline runs. Jenkins and SonarQube CPU requests were also downsized to guarantee scheduling.

## 📂 Project Structure
```text
.
├── backend/                       # ✅ Spring Boot App (API Bug Fixes applied)
├── frontend/                      # ✅ React App (Cart Sync & UI Modernization applied)
└── ops/
    ├── k8s/                       # Kubernetes App Manifests (Ingress routing fixed)
    ├── scripts/
    │   └── setup_tf_state.sh      # 🪣 Script to bootstrap S3 backend & DynamoDB locking
    └── terraform/
        └── aws/main.tf            # 🏗️ IaC updated to use S3 Remote State
```

---
*Created as the Application Polish and Bug Fix iteration for a DevOps Reference Architecture journey.*
