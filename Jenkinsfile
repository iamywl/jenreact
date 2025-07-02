// Jenkinsfile (플러그인 의존성 제거 최종 버전)
pipeline {
    agent {
        kubernetes {
            // 파이프라인을 실행할 Pod의 상세 스펙을 직접 정의
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
  # kubectl 명령어를 실행할 컨테이너 추가
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
                    script {
                        echo "도커 이미지를 빌드합니다: ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker build -t ${IMAGE_NAME} --tag ${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    script {
                        echo "이미지를 Docker Hub로 푸시합니다."
                        docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                            docker.image(IMAGE_NAME).push("${env.BUILD_NUMBER}")
                            docker.image(IMAGE_NAME).push("latest")
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // kubectl 컨테이너 안에서 배포 작업 실행
                container('kubectl') {
                    withKubeConfig() {
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
}
