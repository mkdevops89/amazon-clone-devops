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
    - name: docker
      image: docker:dind
      securityContext:
        privileged: true
      command:
        - cat
      tty: true
    - name: tools
      image: ubuntu:latest
      command:
        - cat
      tty: true
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

        stage('Deploy (Mock)') {
            steps {
                container('tools') {
                    sh 'echo "Deploying to Kubernetes..."'
                }
            }
        }
    }
}
