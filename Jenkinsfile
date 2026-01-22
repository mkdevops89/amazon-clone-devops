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
      image: trufflesecurity/trufflehog:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "256Mi"
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
                    sh 'trufflehog git file:///home/jenkins/agent/workspace/amazone-clone --only-verified'
                }
            }
        }

        stage('Security: SCA') {
            steps {
                container('maven') {
                    dir('backend') {
                        // Pass NVD API Key to avoid 403 rate limiting
                        withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_KEY')]) {
                            sh 'mvn dependency-check:check -DnvdApiKey=${NVD_KEY}'
                        }
                    }
                }
            }
        }

        stage('Build & Unit Test') {
            steps {
                container('maven') {
                    dir('backend') {
                        // Removed -DskipTests to run real unit tests
                        sh 'mvn clean install'
                    }
                }
            }
        }

        stage('Security: SAST') {
            steps {
                container('maven') {
                    dir('backend') {
                        sh 'mvn spotbugs:check'
                    }
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                container('maven') {
                    dir('backend') {
                        // Uses 'nexus-credentials' created in Walkthrough Step 7
                        withCredentials([usernamePassword(credentialsId: 'nexus-credentials', passwordVariable: 'NEXUS_PWD', usernameVariable: 'NEXUS_USER')]) {
                            sh '''
                                # Generate a temporary settings.xml with credentials
                                cat > settings.xml <<EOF
<settings>
  <servers>
    <server>
      <id>amazon-maven-releases</id>
      <username>${NEXUS_USER}</username>
      <password>${NEXUS_PWD}</password>
    </server>
    <server>
      <id>amazon-maven-snapshots</id>
      <username>${NEXUS_USER}</username>
      <password>${NEXUS_PWD}</password>
    </server>
  </servers>
</settings>
EOF
                                echo "Uploading artifact to Nexus..."
                                mvn deploy -s settings.xml -DskipTests=true
                                rm settings.xml
                            '''
                        }
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
