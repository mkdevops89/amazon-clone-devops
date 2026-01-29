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
      image: maven:3.9.6-eclipse-temurin-17
      command:
        - cat
      tty: true
      volumeMounts:
        - name: nvd-cache
          mountPath: /var/maven/odc-data
      resources:
        requests:
          cpu: "50m"
          memory: "512Mi"
        limits:
          cpu: "1000m"
          memory: "1Gi"
    - name: tools
      image: ubuntu:latest
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: "20m"
          memory: "64Mi"
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

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security: Secrets') {
            steps {
                container('security') {
                    // Use $WORKSPACE and clean job name for safety
                    sh 'trufflehog git file://${WORKSPACE} --only-verified'
                }
            }
        }

        stage('Security: SCA') {
            steps {
                container('maven') {
                    dir('backend') {
                        withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_KEY')]) {
                            sh '''
                                set -euo pipefail

                                if [ -z "${NVD_KEY:-}" ]; then
                                  echo "ERROR: NVD_KEY is empty - Jenkins credential injection failed."
                                  exit 1
                                fi
                                echo "NVD_KEY injected (length=${#NVD_KEY})"

                                # Safe path using tr (POSIX compliant)
                                JOB_SAFE_NAME=$(echo "$JOB_NAME" | tr / _)
                                ODC_DATA_DIR="/var/maven/odc-data/${JOB_SAFE_NAME}"
                                mkdir -p "$ODC_DATA_DIR"

                                # Run ODC with Warn-Only (exit code 0 on failure)
                                echo "Running OWASP Dependency Check (Warn Only mode)..."
                                mvn -B org.owasp:dependency-check-maven:9.0.9:check \
                                  -DnvdApiKey="${NVD_KEY}" \
                                  -DnvdApiDelay=25000 \
                                  -DdataDirectory="$ODC_DATA_DIR" \
                                  -DfailOnError=false || echo "ODC Scan failed (Ignored)"
                            '''
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
                                # Cleanup credentials on exit (trap works even if build fails)
                                trap "rm -f settings.xml" EXIT

                                # Generate settings.xml
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

    post {
        success {
            container('tools') {
               withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
                   sh """
                       apt-get update && apt-get install -y curl
                       curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ *Build Succeeded!* \\nProject: ${JOB_NAME} \\nBuild Number: ${BUILD_NUMBER} \\nURL: ${BUILD_URL}"}' \${SLACK_URL}
                   """
               }
            }
        }
        failure {
            container('tools') {
               withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_URL')]) {
                   sh """
                       apt-get update && apt-get install -y curl
                       curl -X POST -H 'Content-type: application/json' --data '{"text":"❌ *Build Failed!* \\nProject: ${JOB_NAME} \\nBuild Number: ${BUILD_NUMBER} \\nURL: ${BUILD_URL}"}' \${SLACK_URL}
                   """
               }
            }
        }
    }
}
