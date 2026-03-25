# Kyverno Policy Management & Exceptions

## 1. Overview
Kyverno natively functions as an advanced Admission Webhook deeply embedded within the EKS cluster. It strictly enforces DISA STIG baselines by mechanically intercepting and objectively either validating, mutating, or destroying incoming Kubernetes API execution requests.

## 2. Interacting with Active Policies
To display all active ClusterPolicies prioritizing the automated DevSecOps architectures:
```bash
kubectl get clusterpolicies
```

To extract the localized federal compliance reports (physically identifying which discrete pods are failing background validations):
```bash
kubectl get clusterpolicyreports
```

## 3. Authoring Temporary Namespace Exceptions
If an upstream vendor dependency explicitly requires root escalation (violently preventing it from deploying properly under our `disallow-root-user` rule), operators must formally inject a discrete namespace exception rather than mechanically deleting the overarching ClusterPolicy.

1. Intercept the strict API policy object:
   ```bash
   kubectl edit clusterpolicy disallow-root-user
   ```
2. Traverse vertically to the `exclude` block nested under `rules`:
   ```yaml
   exclude:
     any:
     - resources:
         namespaces:
         - vendor-system # Dynamically inject the target namespace here
   ```
3. Save and overwrite. The Kyverno daemonset backend will automatically reload the strict definitions internally within 5 seconds flawlessly without requiring an EKS cluster reboot.
