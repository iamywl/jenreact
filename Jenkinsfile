// Jenkinsfile
pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        // ⚠️ 본인의 Docker Hub 사용자 이름으로 변경하세요.
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
                echo "도커 이미지를 빌드합니다: ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                // Dockerfile을 사용하여 이미지 빌드
                docker.build(IMAGE_NAME, "--tag ${IMAGE_NAME}:${env.BUILD_NUMBER} .")
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "이미지를 Docker Hub로 푸시합니다."
                // Jenkins에 저장된 인증 정보를 사용하여 Docker Hub에 로그인 후 이미지 푸시
                docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                    // 1. 빌드 번호 태그로 푸시 (예: my-repo:5)
                    docker.image(IMAGE_NAME).push("${env.BUILD_NUMBER}")
                    // 2. latest 태그로 푸시
                    docker.image(IMAGE_NAME).push("latest")
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '쿠버네티스에 배포를 시작합니다.'
                // 1. deployment.yaml 파일의 이미지 주소를 방금 푸시한 이미지로 변경
                sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${env.BUILD_NUMBER}|g' deployment.yaml"
                
                // 2. kubectl 명령어로 서비스와 배포를 클러스터에 적용(업데이트)
                sh 'kubectl apply -f service.yaml'
                sh 'kubectl apply -f deployment.yaml'

                echo '배포가 성공적으로 완료되었습니다!'
            }
        }
    }
}
