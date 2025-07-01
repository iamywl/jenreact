# Dockerfile

# 1. 빌드(Build) 단계: 리액트 앱을 빌드합니다.
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
RUN npm run build

# 2. 실행(Serve) 단계: 빌드된 결과물을 Nginx 서버에 올립니다.
FROM nginx:stable-alpine
# build 단계의 /app/build 폴더를 nginx의 웹 서버 루트로 복사
COPY --from=builder /app/build /usr/share/nginx/html
# 컨테이너 80번 포트 개방
EXPOSE 80
# nginx 서버 실행
CMD ["nginx", "-g", "daemon off;"]
