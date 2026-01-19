# Phase 5 Test Cases: Domains & HTTPS

## 🧪 Test Case 1: SSL Validation
**Objective:** Verify the ACM Certificate is valid and trusted.
**Steps:**
1.  Open Chrome/Browser.
2.  Navigate to `https://www.devcloudproject.com`.
3.  Click the Lock Icon in the address bar.
4.  View Certificate.
**Expected Result:**
*   Issued By: Amazon RSA ...
*   Status: Valid.

## 🧪 Test Case 2: HTTP to HTTPS Redirect
**Objective:** Ensure plain HTTP requests are forced to HTTPS.
**Steps:**
1.  Type `http://www.devcloudproject.com` (Note: NO 's').
2.  Press Enter.
**Expected Result:**
*   Browser automatically redirects to `https://...`.

## 🧪 Test Case 3: Integration Check
**Objective:** Verify application works under new domain.
**Steps:**
1.  Login to the Frontend.
2.  Add an item to Cart.
3.  Checkout.
**Expected Result:**
*   No CORS errors in console.
*   Backend API calls go to `https://api.devcloudproject.com`.

## 🧪 Test Case 4: Grafana Access
**Objective:** Verify Monitoring Dashboard access.
**Steps:**
1.  Navigate to `https://grafana.devcloudproject.com`.
**Expected Result:**
*   Grafana Login Page loads.
*   Secure connection confirmed.
