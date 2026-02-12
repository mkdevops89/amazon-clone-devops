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
          cpu: "50m"
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
          cpu: "50m"
          memory: "256Mi"
    - name: tools
      image: ubuntu:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "20m"
          memory: "64Mi"
    - name: node
      image: node:20-alpine
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "128Mi"
    - name: security
      image: trufflesecurity/trufflehog:latest
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
        GIT_COMMIT_SHORT = ""
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                script {
                    checkout scm
                    env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "--- 🛠️ Building Version: ${env.GIT_COMMIT_SHORT} ---"
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

        stage('Build: Backend (Artifact)') {
            steps {
                container('maven') {
                    dir('backend') {
                        sh 'mvn clean install -DskipTests' // Fast build for Docker layer
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
                            
                            // Login to ECR
                            sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"

                            // Build & Push Backend
                            dir('backend') {
                                sh "docker build -t ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-backend:latest ."
                                sh "docker push ${ECR_REGISTRY}/amazon-backend:${env.GIT_COMMIT_SHORT}"
                                sh "docker push ${ECR_REGISTRY}/amazon-backend:latest"
                            }

                            // Build & Push Frontend
                            dir('frontend') {
                                sh "docker build --build-arg NEXT_PUBLIC_API_URL='https://api.devcloudproject.com' -t ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT} -t ${ECR_REGISTRY}/amazon-frontend:latest ."
                                sh "docker push ${ECR_REGISTRY}/amazon-frontend:${env.GIT_COMMIT_SHORT}"
                                sh "docker push ${ECR_REGISTRY}/amazon-frontend:latest"
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
                        echo "--- 🚀 Updating GitOps Manifests with Version: ${env.GIT_COMMIT_SHORT} ---"
                        // In a real multi-repo GitOps setup, this would commit to a separate 'config' repo.
                        // For this phase, we update the local values.yaml to prepare for ArgoCD to pull it.
                        sh """
                            sed -i 's/tag: .*/tag: "${env.GIT_COMMIT_SHORT}"/g' ops/helm/amazon-app/values.yaml
                        """
                        
                        // FUTURE: Add 'git commit' and 'git push' here to trigger ArgoCD
                        echo "Values updated. Ready for GitOps Sync."
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

