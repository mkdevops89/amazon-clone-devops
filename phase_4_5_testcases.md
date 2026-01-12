# Phase 4.5 Test Cases: Domain & SSL Verification

**Objective:** Verify that the Domain and SSL Certificate are correctly configured in AWS.

## 🧪 Test Case 1: Validate Name Server Propagation
**Objective:** Confirm that the internet sees your AWS Name Servers.
**Command:**
```bash
dig NS devcloudproject.com +short
```
**Expected Output:**
Should return 4 AWS servers (e.g., `ns-xx.awsdns-xx.com`).
*Note: If it returns nothing or old servers, wait 10-30 minutes.*

## 🧪 Test Case 2: Validate SSL Certificate Status
**Objective:** Confirm AWS ACM has issued the certificate.
**Command:**
```bash
aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='devcloudproject.com']"
```
**Expected Output:**
```json
[
    {
        "CertificateArn": "arn:aws:acm:us-east-1:...",
        "DomainName": "devcloudproject.com",
        "Status": "ISSUED"  <-- THIS IS KEY
    }
]
```
*   **PENDING_VALIDATION:** DNS not propagated yet. Wait.
*   **ISSUED:** Success! We can proceed to Part 2 (K8s Integration).

## 🧪 Test Case 3: AWS Console Verification
1.  Go to **Route53 Console** -> **Hosted Zones**.
    *   Verify `devcloudproject.com` exists.
    *   Verify it has a `CNAME` record for `_acm-validation`.
2.  Go to **Certificate Manager (ACM)**.
    *   Verify the certificate status is **Issued**.
