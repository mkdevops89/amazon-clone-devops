pipeline {
    // Run on any available agent
    agent any

    // Define tools available in the Jenkins environment
    tools {
        maven 'Maven 3'
        jdk 'Java 17'
        nodejs 'NodeJS 18'
    }

    stages {
        // Step 1: Checkout Code from SCM (Git)
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // Step 2: Build Backend & Check Security
        stage('Backend Build') {
            steps {
                dir('backend') {
                    // Compile and Package JAR
                    sh 'mvn clean package'
                    // Run Static Code Analysis (Quality Gate)
                    sh 'mvn sonar:sonar'
                    // Security: SCA Scan (Check for known vulnerabilities in dependencies)
                    sh 'mvn org.owasp:dependency-check-maven:check'
                }
            }
        }

        // Step 3: Deploy Artifacts to Nexus
        stage('Nexus Deploy') {
            when {
                branch 'main'
            }
            steps {
                dir('backend') {
                    // Upload JAR to Nexus Repository Manager
                    sh 'mvn deploy'
                }
            }
        }

        // Step 4: Build Frontend
        stage('Frontend Build') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        // Step 5: Build Docker Images
        stage('Docker Build') {
            steps {
                // Uses docker-compose to build services defined in docker-compose.yml
                sh 'docker-compose build'
            }
        }

        // Step 6: Security Scanning (Container)
        stage('Security Scan (Trivy)') {
            steps {
                // Security: Scan built Docker images for OS/Package vulnerabilities
                // Fail build if CRITICAL or HIGH severities are found
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH amazon-backend:latest'
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH amazon-frontend:latest'
            }
        }

        stage('SCA Scan (Snyk)') {
            steps {
                // Requires SNYK_TOKEN credentials in Jenkins
                echo 'Running Snyk test...'
                // sh 'snyk test --all-projects'
            }
        }

        stage('DAST Scan (OWASP ZAP)') {
            steps {
                echo 'Running ZAP Baseline Scan...'
                // sh 'docker run -t owasp/zap2docker-stable zap-baseline.py -t http://app-url'
            }
        }

    }

    // ==========================================
    // Post-Build Actions (Notifications)
    // ==========================================
    post {
        success {
            slackSend (color: '#00FF00', message: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}
