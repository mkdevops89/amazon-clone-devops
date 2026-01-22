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
      resources:
        requests:
          cpu: "100m"
          memory: "256Mi"
    - name: docker
      image: docker:dind
      securityContext:
        privileged: true
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "256Mi"
    - name: tools
      image: ubuntu:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "128Mi"
'''
        }
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security: Secrets') {
            steps {
                container('tools') {
                    // Placeholder: In a real environment, install trufflehog binary
                    sh 'echo "Scanning for secrets..."'
                    // sh 'trufflehog --only-verified git+file://.' 
                }
            }
        }

        stage('Security: SCA') {
            steps {
                container('maven') {
                    // Placeholder: Snyk CLI would be installed here
                    sh 'echo "Scanning dependencies..."'
                    // sh 'snyk test'
                }
            }
        }

        stage('Build & Unit Test') {
            steps {
                container('maven') {
                    sh 'mvn clean install -DskipTests=true'
                }
            }
        }

        stage('Security: SAST') {
            steps {
                container('maven') {
                    // Placeholder: SonarScanner
                    sh 'echo "Scanning code quality..."'
                    // sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                container('maven') {
                    // Uses 'nexus-credentials' created in Walkthrough Step 7
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', passwordVariable: 'NEXUS_PWD', usernameVariable: 'NEXUS_USER')]) {
                        sh 'echo "Uploading artifact to Nexus: https://nexus.devcloudproject.com/repository/amazon-maven-releases/"'
                        // sh "mvn deploy -DaltDeploymentRepository=nexus::default::https://nexus.devcloudproject.com/repository/amazon-maven-releases/"
                    }
                }
            }
        }

        stage('Deploy (Mock)') {
            steps {
                container('tools') {
                    sh 'echo "Deploying to Kubernetes..."'
                }
            }
        }
    }
}
