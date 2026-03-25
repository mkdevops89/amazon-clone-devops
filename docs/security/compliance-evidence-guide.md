# Compliance Evidence Retention Guide

## 1. WORM Storage Architecture
All DevSecOps vulnerability metrics (DAST, SAST, SCA, and SBOMs) are algorithmically archived immediately preceding a live deployment.

The Jenkins Delivery Pipeline dynamically executes a recursive `aws s3 cp` array targeting the `amazon-clone-security-evidence` S3 bucket. Modifying standard operations, this particular bucket leverages an intrinsic **Write Once, Read Many (WORM)** Object Lock architecture, ensuring forensic log data cannot be tampered with, altered, or manually purged by any infrastructure administrator for a minimum trailing retention lifecycle of 365 days.

## 2. Artifact Retrieval Process
Auditors requesting immutable evidence artifacts can explicitly query the S3 bucket utilizing the isolated Jenkins build integer:
```bash
aws s3 ls s3://amazon-clone-security-evidence/cybersecurity-reports/Report-${BUILD_NUMBER}/
```
