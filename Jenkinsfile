pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: some-value
spec:
  containers:
    - name: maven
      image: maven:3.8.6-openjdk-18
      command:
        - cat
      tty: true
      volumeMounts:
        - name: nvd-cache
          mountPath: /var/maven/odc-data
      resources:
        requests:
          cpu: "20m"
          memory: "128Mi"
    - name: docker
      image: docker:dind
      securityContext:
        privileged: true
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "20m"
          memory: "256Mi"
    - name: tools
      image: ubuntu:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "10m"
          memory: "64Mi"
    - name: node
      image: node:20-alpine
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "20m"
          memory: "128Mi"
    - name: security
      image: trufflesecurity/trufflehog:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "10m"
          memory: "128Mi"
    - name: trivy
      image: aquasec/trivy:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "20m"
          memory: "256Mi"
    - name: zap
      image: ghcr.io/zaproxy/zaproxy:stable
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "256Mi"
    - name: sonar
      image: sonarsource/sonar-scanner-cli:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "128Mi"
  volumes:
    - name: nvd-cache
      persistentVolumeClaim:
        claimName: jenkins-nvd-cache
'''
        }
    }

    environment {
        AWS_REGION = "us-east-1"
        ECR_REGISTRY = "406312601212.dkr.ecr.us-east-1.amazonaws.com"
        DOCKERHUB_USER = "mlis682"
        S3_REPORT_BUCKET = "amazon-clone-reports-6cc84b5432a5904b"
        SONAR_PROJECT = "amazon-pipeline"
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                container('maven') {
                    script {
                        checkout scm
                        def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                        env.GIT_COMMIT_SHORT = commit
                        echo "--- 🛠️ Building Version: ${env.GIT_COMMIT_SHORT} ---"
                        
                        // Create a unique report directory for this build
                        sh "mkdir -p reports"
                    }
                }
            }
        }

        stage('Security: Secrets Scan') {
            steps {
                container('security') {
                    // Scan and output JSON report, failing only on Verified High Severity
                    // || true to allow uploading the report even if it fails later
                    sh "trufflehog git file://${WORKSPACE} --only-verified --json > reports/trufflehog.json || true"
                    
                    // Upload to S3 immediately
                    container('tools') {
                        withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                             sh 'apk add --no-cache aws-cli'
                             sh "aws s3 cp reports/trufflehog.json s3://${S3_REPORT_BUCKET}/${env.GIT_COMMIT_SHORT}/trufflehog.json"
                        }
                    }
                }
            }
        }

        stage('Security: SCA Scan') {
            steps {
                container('maven') {
                    withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                        dir('backend') {
                            // Using persistent cache for NVD data and high delay (16s) to avoid 403/Rate limits
                            sh 'mvn org.owasp:dependency-check-maven:check -DnvdApiKey=${NVD_API_KEY} -DdataDirectory=/var/maven/odc-data -DnvdApiDelay=16000 -Dformat=HTML -DoutputDirectory=../reports/ || echo "SCA Scan encountered an NVD issue, check logs."'
                        }
                    }
                }
                container('tools') {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                         sh "aws s3 cp reports/dependency-check-report.html s3://${S3_REPORT_BUCKET}/${env.GIT_COMMIT_SHORT}/dependency-check.html || true"
                    }
                }
            }
        }

        stage('Build: Backend (Artifact)') {
            steps {
                container('maven') {
                    dir('backend') {
                        sh 'mvn clean install -DskipTests'
                    }
                }
            }
        }

        stage('Security: SAST (Backend)') {
            steps {
                container('maven') {
                    dir('backend') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            // Using specific project key requested by user
                            sh 'mvn sonar:sonar -Dsonar.login=${SONAR_TOKEN} -Dsonar.host.url=http://sonarqube -Dsonar.projectKey=${SONAR_PROJECT} -Dsonar.projectName="Amazon Clone Backend"'
                        }
                    }
                }
            }
        }

        stage('Security: SAST (Frontend)') {
            steps {
                container('sonar') {
                    dir('frontend') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            sh """
                                sonar-scanner \
                                -Dsonar.projectKey=${SONAR_PROJECT}:frontend \
                                -Dsonar.projectName="Amazon Clone Frontend" \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://sonarqube \
                                -Dsonar.login=${SONAR_TOKEN} \
                                -Dsonar.exclusions=**/node_modules/**,**/.next/**
                            """
                        }
                    }
                }
            }
        }

        stage('Build: Docker Images') {
            steps {
                container('docker') {
                    withCredentials([
                        usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID'),
                        usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DOCKERHUB_PASS', usernameVariable: 'DOCKERHUB_USER_CREDS')
                    ]) {
                        script {
                            sh 'dockerd > /var/log/dockerd.log 2>&1 &'
                            sh '''
                                count=0
                                while ! docker info >/dev/null 2>&1; do
                                    sleep 1
                                    count=$((count+1))
                                    if [ $count -ge 30 ]; then echo "Docker failed to start"; exit 1; fi
                                done
                            '''
                            
                            // 1. Login to ECR
                            sh 'apk add --no-cache aws-cli'
                            sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                            
                            // 2. Login to Docker Hub
                            sh "echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER_CREDS} --password-stdin"

                            // 3. Build & Tag (Multi-Registry)
                            dir('backend') {
                                // ECR Tags
                                sh "docker build -t ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-backend:latest ."
                                // Docker Hub Tags
                                sh "docker tag ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} ${DOCKERHUB_USER}/amazon-backend:${env.GIT_COMMIT_SHORT}"
                                sh "docker tag ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} ${DOCKERHUB_USER}/amazon-backend:latest"
                            }

                            dir('frontend') {
                                // ECR Tags
                                sh "docker build --build-arg NEXT_PUBLIC_API_URL='https://api.devcloudproject.com' -t ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-frontend:latest ."
                                // Docker Hub Tags
                                sh "docker tag ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT} ${DOCKERHUB_USER}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                                sh "docker tag ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT} ${DOCKERHUB_USER}/amazon-frontend:latest"
                            }
                        }
                    }
                }
            }
        }

        stage('Push: Docker Images') {
            steps {
                container('docker') {
                    script {
                        // Push to ECR
                        sh "docker push ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${ECR_REGISTRY}/amazon-backend:latest"
                        sh "docker push ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${ECR_REGISTRY}/amazon-frontend:latest"
                        
                        // Push to Docker Hub
                        sh "docker push ${DOCKERHUB_USER}/amazon-backend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${DOCKERHUB_USER}/amazon-backend:latest"
                        sh "docker push ${DOCKERHUB_USER}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${DOCKERHUB_USER}/amazon-frontend:latest"
                    }
                }
            }
        }

        stage('Security: Image Scan') {
            steps {
                container('trivy') {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        script {
                            sh 'apk add --no-cache aws-cli'
                            sh "export TRIVY_PASSWORD=\$(aws ecr get-login-password --region ${AWS_REGION}) && \
                                export TRIVY_USERNAME=AWS && \
                                trivy image --format json --output reports/trivy-backend.json --severity HIGH,CRITICAL --scanners vuln --cache-dir /tmp/trivy-cache ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} && \
                                trivy image --format json --output reports/trivy-frontend.json --severity HIGH,CRITICAL --scanners vuln --cache-dir /tmp/trivy-cache ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                            
                            // Upload Reports
                            sh "aws s3 cp reports/trivy-backend.json s3://${S3_REPORT_BUCKET}/${env.GIT_COMMIT_SHORT}/trivy-backend.json"
                            sh "aws s3 cp reports/trivy-frontend.json s3://${S3_REPORT_BUCKET}/${env.GIT_COMMIT_SHORT}/trivy-frontend.json"
                        }
                    }
                }
            }
        }

        stage('Security: DAST Scan') {
            steps {
                container('zap') {
                    script {
                        // Run ZAP and generate HTML report
                        sh '/zap/zap-baseline.py -t https://api.devcloudproject.com -r reports/zap-report.html -I || true' 
                        
                        // Upload Report
                        container('tools') {
                            withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                                 sh 'apk add --no-cache aws-cli'
                                 sh "aws s3 cp /home/zap/reports/zap-report.html s3://${S3_REPORT_BUCKET}/${env.GIT_COMMIT_SHORT}/zap-report.html || true"
                            }
                        }
                    }
                }
            }
        }

        stage('GitOps: Update Manifests') {
            steps {
                container('tools') {
                    script {
                        withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                            sh """
                                # Avoid "fatal: not in a git directory" by cloning fresh
                                rm -rf temp-gitops
                                git clone https://${GITHUB_TOKEN}@github.com/mkdevops89/amazon-clone-devops.git temp-gitops
                                cd temp-gitops
                                
                                # Checkout the correct branch
                                git checkout phase-11-gitops
                                
                                # Update the tag in the fresh clone
                                sed -i 's/tag: .*/tag: "${env.GIT_COMMIT_SHORT}"/g' ops/helm/amazon-app/values.yaml
                                
                                # Commit and Push
                                git config user.email "mlis.dev89@gmail.com"
                                git config user.name "Micheal L"
                                git add ops/helm/amazon-app/values.yaml
                                
                                # Only commit if there are changes
                                if ! git diff --cached --quiet; then
                                    git commit -m "chore(gitops): update image tag to ${env.GIT_COMMIT_SHORT} [skip ci]"
                                    git push origin phase-11-gitops
                                    echo "✅ GitOps manifests updated successfully."
                                else
                                    echo "No changes to commit."
                                fi
                            """
                        }
                        echo "Values updated and pushed. ArgoCD will sync shortly."
                    }
                }
            }
        }
    }

    post {
        always {
            container('tools') {
               script {
                   def status = currentBuild.currentResult
                   def color = (status == 'SUCCESS') ? 'good' : 'danger'
                   withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
                        sh """
                            apt-get update && apt-get install -y curl
                            curl -X POST -H 'Content-type: application/json' --data '{"text":"*Jenkins Build: ${status}*\\nProject: ${JOB_NAME}\\nVersion: ${env.GIT_COMMIT_SHORT}\\nReport URL: https://s3.console.aws.amazon.com/s3/buckets/${S3_REPORT_BUCKET}?prefix=${env.GIT_COMMIT_SHORT}/"}' \${SLACK_URL}
                        """
                   }
               }
            }
        }
    }
}

