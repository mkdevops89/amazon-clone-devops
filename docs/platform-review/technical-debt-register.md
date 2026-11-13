# Technical debt and verification backlog

This is a repository-level review list, not a report from a live AWS account. Items below are based on files in the current `main` branch and should be rechecked before execution.

## Confirmed repository issues

| Priority | Finding | Evidence | Follow-up |
|---|---|---|---|
| High | Main-branch GitHub Actions run is failing | The latest visible `Amazon Clone CI/CD` run failed in the backend and frontend build jobs. | Inspect the failed steps and obtain a clean run before describing CI as passing. The frontend Node version was adjusted on the portfolio cleanup branch; it has not been run on GitHub yet. |
| High | Terraform generates a bastion private key | `ops/terraform/modules/eks/bastion.tf` uses `tls_private_key` and writes a local key file. Private-key material is also stored in Terraform state. | Prefer managed access such as SSM Session Manager or provision from an externally managed public key. Protect state and local files until changed. |
| Medium | Mutable image references remain | Some platform manifests and CI agent definitions use tags such as `latest` or `stable`. | Pin tool and workload images to reviewed versions or digests. |
| Medium | Multiple CI/CD paths remain | Jenkins and three GitHub Actions workflows coexist; some GitHub workflows trigger only from phase branches. | Identify which pipeline is the current supported path and disable or label obsolete triggers. |
| Medium | Teardown and security documents contain unverified claims | See the platform review and security documents. | Use the revised documents as review notes; validate all account-specific procedures before execution. |

## Review boundaries

- No AWS account inventory, billing report, Terraform plan, or cluster query was used for this list.
- A path in the repository establishes that configuration exists, not that it is installed or active.
- No claim is made that old scripts, resources, DNS records, storage volumes, or cloud costs remain in an account.
- The GitHub Actions log summary did not expose step-level details during the review.

## Suggested order

1. Review GitHub Actions failures and choose the supported build/deployment path.
2. Supply and verify the restricted administrator CIDR; replace Terraform-generated SSH key material with a managed access method or externally managed public key.
3. Reconcile README and runbook statements with the selected current architecture.
4. Audit cloud resources and actual costs in AWS before making cleanup decisions.
