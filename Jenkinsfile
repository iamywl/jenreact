// Jenkinsfile (최종 Agent 이미지 수정 버전)
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  # 1. Jenkins와 통신하는 기본 jnlp 컨테이너
  - name: jnlp
    image: jenkins/inbound-agent:3309.v27b_9314fd1a_4-6
    args: ['$(JENKINS_SECRET)', '$(JENKINS_NAME)']
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  # 2. Docker 명령어를 실행할 docker 컨테이너 추가
  - name: docker
    image: docker:27.0
    command: ['cat']
    tty: true
    volumeMounts:
      - name: docker-sock
        mountPath: /var/run/docker.sock
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  # ⚠️ bitnami/kubectl 대신 google/cloud-sdk 이미지로 변경
  - name: kubectl
    image: google/cloud-sdk:latest
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
                // 'docker' 라는 이름의 컨테이너 안에서 아래 작업을 실행하도록 지정
                container('docker') {
                    echo "도커 이미지를 빌드합니다: ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_NAME} --tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                container('docker') {
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
                // ⚠️ kubectl이 포함된 google/cloud-sdk 컨테이너에서 배포 작업 실행
                container('kubectl') {
                    echo '쿠버네티스에 배포를 시작합니다.'
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${env.BUILD_NUMBER}|g' deployment.yaml"
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl apply -f deployment.yaml'
                    echo '배포가 성공적으로 완료되었습니다!'
                }
            }
        }
    }
}
