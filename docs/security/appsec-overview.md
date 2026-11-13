# Application security design notes

This page distinguishes code and configuration present in the repository from controls that have not been validated in a running environment. The project is not an independently audited or certified security platform.

## Application components

- The backend is a Spring Boot service with Spring Security, OAuth2 resource-server support, and JWT utility classes.
- The frontend includes Cognito client configuration and a chat API route.
- Backend configuration references database, Redis, RabbitMQ, and Amazon Bedrock settings through environment variables.
- Kubernetes and Terraform configuration include secret references, ingress, security groups, and workload resources.

These repository facts do not establish that authentication is correctly configured for a deployed environment, that every endpoint has the intended authorization, or that credentials are delivered securely at runtime. Review the current code paths and test behavior before making those claims.

## Security controls in the repository

| Topic | Evidence | Validation boundary |
|---|---|---|
| Authentication | Spring Security/JWT code and Cognito configuration | No end-to-end identity-provider test was reviewed. |
| Secret configuration | External Secrets templates and Kubernetes secret references; backend JWT value now comes from `JWT_SECRET` | The previous JWT signing value remains in Git history and must be rotated where used. The remote secret store was not inspected. |
| Container and IaC scanning | GitHub Actions and Jenkins scanner steps | Main CI currently has a visible failure; scan warning/failure behavior varies by workflow. |
| Admission policies | Kyverno policy files | Runtime policy installation and enforcement were not verified. |
| Runtime detection | Falco chart configuration | Runtime installation and alert delivery were not verified. |
| Artifact signing | Review the Jenkinsfile and related configuration before asserting signing behavior | No successful signing-and-verification result was established during this review. |
| Network controls | Terraform security groups and EKS configuration | Current live rules were not inspected. The cleanup branch narrows public admin sources in the EKS module. |

## Threat-model work

A STRIDE-style threat model can be useful for organizing future tests, but mitigations should be described as implemented only after tracing them to code and validation evidence. Prior versions of this page described MFA, signed-image admission, WAF protections, runtime Falco detection, and immutable CloudTrail retention as active controls; this review did not establish those claims, so they are not repeated here.

## Validation to add

1. Test authentication and authorization for allowed and denied user roles.
2. Verify secret delivery and rotation without exposing values in logs or artifacts.
3. Run and retain successful CI evidence for source, dependency, container, IaC, and DAST checks.
4. Confirm admission policy behavior with both accepted and rejected workloads.
5. Confirm image signing and verification end to end if that capability is intended to be claimed.
6. Inspect deployed network, logging, and runtime-monitoring configuration in the target account.
