// Jenkinsfile (플러그인 의존성 제거 최종 버전)
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:3309.v27b_9314fd1a_4-6
    args: ['$(JENKINS_SECRET)', '$(JENKINS_NAME)']
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  - name: docker
    image: docker:27.0
    command: ['cat']
    tty: true
    volumeMounts:
      - name: docker-sock
        mountPath: /var/run/docker.sock
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  volumes:
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
    - name: workspace-volume
      emptyDir: {}
'''
        }
    }

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKERHUB_USERNAME = 'ywleedev'
        IMAGE_NAME = "${DOCKERHUB_USERNAME}/jenreact"
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo 'GitHub에서 소스 코드를 가져옵니다.'
                git branch: 'main', url: 'https://github.com/iamywl/jenreact.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    echo "도커 이미지를 빌드합니다: ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_NAME} --tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    echo "이미지를 Docker Hub로 푸시합니다."
                    // withDockerRegistry 대신, withCredentials와 sh 명령어로 직접 로그인 및 푸시
                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                        sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push ${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    echo '쿠버네티스에 배포를 시작합니다.'
                    // withKubeConfig 없이, Pod 내부에서 자동으로 인증을 처리합니다.
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${env.BUILD_NUMBER}|g' deployment.yaml"
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl apply -f deployment.yaml'
                    echo '배포가 성공적으로 완료되었습니다!'
                }
            }
        }
    }
}
