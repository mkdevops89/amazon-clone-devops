# Phase 4: Kubernetes Deployment Walkthrough

**Objective:** Deploy the Amazon Clone microservices (Frontend & Backend) onto the EKS Cluster created in Phase 3.

## STEP 1: PREPARATION
- [ ] Ensure `aws` CLI and `kubectl` are configured.
- [ ] Verify you are on branch `phase-4-k8s`.

## STEP 2: CONTAINER REGISTRY (ECR)
- [ ] Create ECR Repositories for:
    - `amazon-backend`
    - `amazon-frontend`
- [ ] Authenticate Docker with ECR.

## STEP 3: BUILD & PUSH
- [ ] Build Backend Image:
    ```bash
    docker build -t amazon-backend ./backend
    ```
- [ ] Push to ECR.
- [ ] Build Frontend Image:
    ```bash
    docker build -t amazon-frontend ./frontend
    ```
- [ ] Push to ECR.

## STEP 4: KUBERNETES MANIFESTS
- [ ] Define Deployment and Service YAMLs in `ops/k8s/`.
- [ ] Create `secrets.yaml` for DB Credentials (RDS/Redis endpoints from Terraform).

## STEP 5: DEPLOY
- [ ] `kubectl apply -f ops/k8s/secrets.yaml`
- [ ] `kubectl apply -f ops/k8s/backend.yaml`
- [ ] `kubectl apply -f ops/k8s/frontend.yaml`

## STEP 6: VERIFICATION
- [ ] `kubectl get pods` (All Running?)
- [ ] `kubectl get svc` (LoadBalancer exposed?)
- [ ] Access the application via External IP.
