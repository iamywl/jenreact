// Jenkinsfile (최종 버전)
pipeline {
    agent any

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
                script {
                    echo "도커 이미지를 빌드합니다: ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    docker.build(IMAGE_NAME, "--tag ${IMAGE_NAME}:${env.BUILD_NUMBER} .")
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "이미지를 Docker Hub로 푸시합니다."
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        docker.image(IMAGE_NAME).push("${env.BUILD_NUMBER}")
                        docker.image(IMAGE_NAME).push("latest")
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // ================ 여기부터 수정 ================
                withKubeConfig() {
                    echo '쿠버네티스에 배포를 시작합니다.'
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${env.BUILD_NUMBER}|g' deployment.yaml"
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl apply -f deployment.yaml'
                    echo '배포가 성공적으로 완료되었습니다!'
                }
                // ============================================
            }
        }
    }
}
