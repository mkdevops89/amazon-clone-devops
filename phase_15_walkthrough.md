# Phase 15: AWS Cognito Authentication Architecture

## 1. Objective
Transition the Amazon Clone application from a homegrown JWT authentication mechanism (with passwords stored in MySQL) to an enterprise-grade AWS Cognito Identity Provider. This secures user data, offloads auth infrastructure to AWS Serverless, and enables future features like MFA and Social Logins (Google/Apple).

## 2. Infrastructure Changes (Terraform)
We executed Terraform to provision:
*   **`aws_cognito_user_pool`**: The core directory storing customer emails and cryptographic user subjects (`sub`).
*   **`aws_cognito_user_pool_client`**: The OAuth App Client bridging Next.js to the Cognito directory.
*   **`aws_cognito_user_pool_domain`**: The Hosted UI Domain (e.g., `auth-devcloudproject...`) that powers the secure AWS login page.

## 3. Application Security Refactoring

### Spring Boot Backend
*   **Removed Legacy Code**: Deleted `AuthController.java`, `AuthTokenFilter.java`, and custom JWT minting utilities.
*   **OAuth2 Resource Server**: Integrated `spring-boot-starter-oauth2-resource-server` into `WebSecurityConfig.java`. The backend now naturally trusts the AWS Cognito JWKS (JSON Web Key Set) strictly via the `application.properties` URL.
*   **Silent Database Synchronization**: Created `CurrentUserController.java` (`/api/auth/me`). When a user authenticates via Next.js and hits the backend for the first time, Spring automatically extracts their AWS Cognito `sub` identifier and silently bridges them into the local MySQL `users` table so features like the Shopping Cart continue functioning perfectly.

### Next.js Frontend (In Progress)
*   **Amplify SDK Integration**: Injected `@aws-amplify/ui-react` globally via the root `layout.tsx`.

## 4. Current Blockers / Next Steps
*   **Amazon UX**: The user has requested that the Cognito Login Page looks exactly like the Amazon.com login page. We will evaluate customizing the Cognito Hosted UI CSS, or building a custom React Authentication form using Amplify API calls to perfectly replicate the Amazon aesthetics!
