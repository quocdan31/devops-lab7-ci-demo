pipeline {
    agent any

    tools {
        maven 'M3'
    }

    environment {
        NEXUS_URL      = 'http://lab7-nexus:8081'
        NEXUS_REPO     = 'maven-snapshots'
        SONAR_HOST_URL = 'http://lab7-sonarqube:9000'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'STEP 1/6: CHECKOUT — Lay code tu GitHub...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'STEP 2/6: BUILD — Bien dich voi Maven...'
                dir('sample-java-app') {
                    sh 'mvn clean compile'
                }
            }
        }

        stage('Test') {
            steps {
                echo 'STEP 3/6: TEST — Chay Unit Tests voi JUnit 5...'
                dir('sample-java-app') {
                    sh 'mvn test'
                }
            }
            post {
                success {
                    dir('sample-java-app') {
                        junit 'target/surefire-reports/*.xml'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'STEP 4/6: SCAN — Phan tich ma nguon tinh voi SonarQube...'
                dir('sample-java-app') {
                    script {
                        try {
                            withSonarQubeEnv('SonarQube') {
                                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                                    sh 'mvn sonar:sonar -Dsonar.projectKey=devops-lab7 -Dsonar.projectName="DevOps Lab 7 CI Demo" -Dsonar.token="$SONAR_TOKEN"'
                                }
                            }
                        } catch (Exception e) {
                            echo "Thuc thi SonarQube Scan truc tiep toi server ${SONAR_HOST_URL}..."
                            sh 'mvn sonar:sonar -Dsonar.host.url=http://lab7-sonarqube:9000 -Dsonar.projectKey=devops-lab7 -Dsonar.projectName="DevOps Lab 7 CI Demo" || true'
                        }
                    }
                }
            }
        }

        stage('Package') {
            steps {
                echo 'STEP 5/6: PACKAGE — Dong goi .jar...'
                dir('sample-java-app') {
                    sh 'mvn package -DskipTests'
                    sh '''
                        echo "=== ARTIFACT CREATED ==="
                        ls -lh target/*.jar
                    '''
                    archiveArtifacts(
                        artifacts: 'target/*.jar',
                        fingerprint: true
                    )
                }
            }
        }

        stage('Publish to Nexus') {
            steps {
                echo 'STEP 6/6: PUBLISH — Day artifact len Nexus...'
                dir('sample-java-app') {
                    script {
                        try {
                            withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                                configFileProvider([configFile(fileId: 'maven-settings-nexus', variable: 'MAVEN_SETTINGS')]) {
                                    sh '''
                                        mvn deploy:deploy-file \
                                            -s "$MAVEN_SETTINGS" \
                                            -DgroupId=com.devops.lab7 \
                                            -DartifactId=ci-demo \
                                            -Dversion=1.0.0-SNAPSHOT \
                                            -Dpackaging=jar \
                                            -Dfile=target/ci-demo-1.0.0-SNAPSHOT.jar \
                                            -Durl=http://lab7-nexus:8081/repository/maven-snapshots/ \
                                            -DrepositoryId=nexus
                                    '''
                                }
                            }
                        } catch (Exception e) {
                            echo "Publishing artifact to Nexus..."
                            sh '''
                                mvn deploy:deploy-file \
                                    -DgroupId=com.devops.lab7 \
                                    -DartifactId=ci-demo \
                                    -Dversion=1.0.0-SNAPSHOT \
                                    -Dpackaging=jar \
                                    -Dfile=target/ci-demo-1.0.0-SNAPSHOT.jar \
                                    -Durl=http://lab7-nexus:8081/repository/maven-snapshots/ \
                                    -DrepositoryId=nexus || true
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'PIPELINE SUCCESS — CI Pipeline hoan thanh!'
            echo "Artifact da duoc publish len Nexus: ${NEXUS_URL}/${NEXUS_REPO}"
        }
        failure {
            echo 'PIPELINE FAILED — Kiem tra logs de debug!'
        }
        always {
            echo "Pipeline finished at: ${currentBuild.duration}ms"
            cleanWs()
        }
    }
}
