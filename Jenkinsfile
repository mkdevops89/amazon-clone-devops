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
                    }
                }
            }
        }

        stage('Security: Secrets Scan') {
            steps {
                container('security') {
                    sh "trufflehog git file://${WORKSPACE} --only-verified"
                }
            }
        }

        stage('Security: SCA Scan') {
            steps {
                container('maven') {
                    withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                        dir('backend') {
                            // Using persistent cache for NVD data and high delay (16s) to avoid 403/Rate limits
                            // Note: We use || true so a temporary NVD outage doesn't block the whole build
                            sh 'mvn org.owasp:dependency-check-maven:check -DnvdApiKey=${NVD_API_KEY} -DdataDirectory=/var/maven/odc-data -DnvdApiDelay=16000 || echo "SCA Scan encountered an NVD issue, check logs."'
                        }
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

        stage('Security: SAST Scan') {
            steps {
                container('maven') {
                    dir('backend') {
                        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                            sh 'mvn sonar:sonar -Dsonar.login=${SONAR_TOKEN} -Dsonar.host.url=http://sonarqube'
                        }
                    }
                }
            }
        }

        stage('Build: Docker Images') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
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
                            
                            // Install AWS CLI (it's missing in docker:dind)
                            sh 'apk add --no-cache aws-cli'
                            
                            // Login to ECR
                            sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"

                            // Build Backend with both SHA and latest tags
                            dir('backend') {
                                sh "docker build -t ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-backend:latest ."
                            }

                            // Build Frontend with both SHA and latest tags
                            dir('frontend') {
                                sh "docker build --build-arg NEXT_PUBLIC_API_URL='https://api.devcloudproject.com' -t ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-frontend:latest ."
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
                        sh "docker push ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${ECR_REGISTRY}/amazon-backend:latest"
                        sh "docker push ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                        sh "docker push ${ECR_REGISTRY}/amazon-frontend:latest"
                    }
                }
            }
        }

        stage('Security: Image Scan') {
            steps {
                container('trivy') {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                        script {
                            // Install AWS CLI in Trivy container to get login token
                            sh 'apk add --no-cache aws-cli'
                            sh "export TRIVY_PASSWORD=\$(aws ecr get-login-password --region ${AWS_REGION}) && \
                                export TRIVY_USERNAME=AWS && \
                                trivy image --severity HIGH,CRITICAL --scanners vuln --cache-dir /tmp/trivy-cache ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} && \
                                trivy image --severity HIGH,CRITICAL --scanners vuln --cache-dir /tmp/trivy-cache ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                        }
                    }
                }
            }
        }

        stage('Security: DAST Scan') {
            steps {
                container('zap') {
                    script {
                        // OWASP ZAP Baseline scan against the app URL
                        // Note: Using the stable image which has the script in /zap/
                        sh '/zap/zap-baseline.py -t https://api.devcloudproject.com -I || true' 
                        sh '/zap/zap-baseline.py -t https://devcloudproject.com -I || true'
                    }
                }
            }
        }

        stage('GitOps: Update Manifests') {
            steps {
                container('tools') {
                    script {
                        echo "--- 🚀 Updating GitOps Manifests with Version: ${env.GIT_COMMIT_SHORT} ---"
                        
                        // Ensure git and sed are present in the tools container
                        sh "apt-get update && apt-get install -y git sed"

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
                                git config user.email "jenkins@devcloudproject.com"
                                git config user.name "Jenkins CI"
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
                            curl -X POST -H 'Content-type: application/json' --data '{"text":"*Jenkins Build: ${status}*\\nProject: ${JOB_NAME}\\nVersion: ${env.GIT_COMMIT_SHORT}\\nURL: ${BUILD_URL}"}' \${SLACK_URL}
                        """
                   }
               }
            }
        }
    }
}

