---
title: 'Docker 컨테이너 이미지 빌드'
week: 10
session: 1
awsServices:
  - Amazon ECR
learningObjectives:
  - 컨테이너의 개념과 가상머신과의 차이점을 이해할 수 있습니다.
  - Docker의 기본 개념과 구성요소(이미지, 컨테이너, 레지스트리)를 설명할 수 있습니다.
  - Dockerfile을 작성하여 컨테이너 이미지를 빌드할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **Docker 이미지**를 빌드하고 **컨테이너**를 실행한 후, **Amazon ECR**에 이미지를 푸시하여 컨테이너 기술의 기본을 학습합니다.

> [!CONCEPT] Docker 컨테이너란?
>
> Docker는 애플리케이션을 **컨테이너**라는 격리된 환경에서 실행하는 플랫폼입니다.
>
> - **이미지(Image)**: 애플리케이션 코드, 런타임, 라이브러리를 포함한 읽기 전용 템플릿입니다.
> - **컨테이너(Container)**: 이미지를 기반으로 실행되는 격리된 프로세스입니다.
> - **Dockerfile**: 이미지를 빌드하기 위한 명령어를 정의한 텍스트 파일입니다.
> - **레지스트리(Registry)**: 이미지를 저장하고 배포하는 저장소입니다 (Amazon ECR, Docker Hub 등).
>
> 가상머신(VM)과 달리 컨테이너는 OS 커널을 공유하므로 가볍고 빠르게 시작됩니다.

## 태스크 1: Docker 환경 설정

### 1.1 CloudShell에서 Docker 환경 확인

1. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

2. Docker 버전을 확인합니다:

```bash
docker --version
```

> [!OUTPUT]
> ```
> Docker version 25.x.x, build xxxxxxx
> ```

3. 작업 디렉토리를 생성합니다:

```bash
mkdir -p ~/docker-lab
```

✅ **태스크 완료**: CloudShell에서 Docker 환경이 준비되었습니다.


## 태스크 2: 웹 애플리케이션 생성

> [!CONCEPT] Node.js와 Express
>
> Node.js는 서버 측 JavaScript 런타임이며, Express는 가장 널리 사용되는 Node.js 웹 프레임워크입니다. 이 실습에서는 Express로 간단한 웹 서버를 만들고 Docker로 컨테이너화합니다.

### 2.1 Node.js 애플리케이션 파일 생성

4. `package.json` 파일을 생성합니다:

```bash
cat > ~/docker-lab/package.json << 'EOF'
{
  "name": "cloudarchitect-lab-app",
  "version": "1.0.0",
  "description": "CloudArchitect Lab Docker Container Application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF
```

5. Express 서버 파일을 생성합니다:

```bash
cat > ~/docker-lab/server.js << 'SERVEREOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <title>CloudArchitect Week 10-1 Docker App</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 0; 
                padding: 40px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                text-align: center;
            }
            .container { 
                max-width: 600px; 
                margin: 0 auto; 
                background: rgba(255,255,255,0.1);
                padding: 40px;
                border-radius: 10px;
            }
            h1 { font-size: 2.5em; margin-bottom: 20px; }
            .info { font-size: 1.2em; margin: 20px 0; }
            .highlight { color: #FFD700; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🐳 CloudArchitect Week 10-1 Docker Application</h1>
            <div class="info">
                <p>Docker 컨테이너가 성공적으로 실행되고 있습니다.</p>
                <p class="highlight">CloudArchitect AWS 가이드 - Week 10-1</p>
                <p>실행 시간: ${new Date().toLocaleString()}</p>
                <p>포트: 3000</p>
            </div>
        </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    message: 'CloudArchitect Week 10-1 Docker App is running'
  });
});

app.listen(port, () => {
  console.log(`CloudArchitect Week 10-1 Docker App running on port ${port}`);
});
SERVEREOF
```

✅ **태스크 완료**: Node.js 웹 애플리케이션 파일이 생성되었습니다.


## 태스크 3: Dockerfile 작성 및 이미지 빌드

> [!CONCEPT] Dockerfile 주요 명령어
>
> | 명령어 | 설명 | 예시 |
> |--------|------|------|
> | `FROM` | 베이스 이미지를 지정합니다 | `FROM node:18-alpine` |
> | `LABEL` | 이미지 메타데이터를 추가합니다 | `LABEL version="1.0"` |
> | `WORKDIR` | 컨테이너 내 작업 디렉토리를 설정합니다 | `WORKDIR /app` |
> | `COPY` | 호스트 파일을 컨테이너로 복사합니다 | `COPY package.json ./` |
> | `RUN` | 이미지 빌드 시 실행할 명령어입니다 | `RUN npm install` |
> | `USER` | 컨테이너 실행 사용자를 지정합니다 | `USER appuser` |
> | `EXPOSE` | 컨테이너가 사용하는 포트를 명시합니다 (문서화) | `EXPOSE 3000` |
> | `HEALTHCHECK` | 컨테이너 상태 확인 명령어를 정의합니다 | `HEALTHCHECK CMD curl localhost` |
> | `CMD` | 컨테이너 시작 시 실행할 기본 명령어입니다 | `CMD ["npm", "start"]` |
>
> **주요 차이점:**
>
> **RUN vs CMD:**
> - **RUN**: 이미지 **빌드 시점**에 실행되며, 실행 결과가 새로운 레이어로 저장됩니다
>   - 예: **RUN npm install**은 빌드할 때 의존성을 설치하고 그 결과를 이미지에 포함
>   - 여러 번 사용 가능하며, 각각 새로운 레이어를 생성합니다
> - **CMD**: 컨테이너 **실행 시점**에 실행되며, 이미지에는 명령어만 저장됩니다
>   - 예: **CMD ["npm", "start"]**는 컨테이너가 시작될 때마다 애플리케이션을 실행
>   - Dockerfile에 하나만 존재하며, 마지막 CMD만 유효합니다
>   - **docker run** 명령어로 덮어쓸 수 있습니다
>
> **EXPOSE의 실제 동작:**
> - **EXPOSE 3000**은 컨테이너가 3000번 포트를 사용한다는 것을 **문서화**하는 역할만 합니다
> - 실제로 포트를 외부에 노출하지 않으며, 방화벽 규칙도 생성하지 않습니다
> - 실제 포트 매핑은 **docker run -p 8080:3000** 명령어의 **-p** 옵션으로 수행합니다
>   - **-p 8080:3000**: 호스트의 8080 포트를 컨테이너의 3000 포트에 연결
> - EXPOSE는 개발자 간 커뮤니케이션과 자동화 도구를 위한 메타데이터입니다
>
> **COPY vs ADD:**
> - **COPY**: 단순히 파일/디렉토리를 복사합니다 (권장)
> - **ADD**: 복사 + URL 다운로드 + tar 자동 압축 해제 기능 (복잡하므로 특별한 경우만 사용)

### 3.1 Dockerfile 생성

6. Dockerfile을 작성합니다:

```bash
cat > ~/docker-lab/Dockerfile << 'EOF'
# 베이스 이미지 지정 - Alpine Linux 기반의 경량 Node.js 18 이미지
FROM node:18-alpine

# 메타데이터 - 이미지에 대한 정보를 레이블로 추가
LABEL maintainer="CloudArchitect Student"
LABEL description="CloudArchitect Week 10-1 Docker Container Application"
LABEL version="1.0"

# 작업 디렉토리 설정 - 이후 모든 명령어는 이 디렉토리에서 실행됨
WORKDIR /app

# 패키지 파일 복사 및 의존성 설치
# package.json과 package-lock.json을 먼저 복사하여 Docker 레이어 캐싱 최적화
COPY package*.json ./
# --only=production: 개발 의존성 제외, npm cache clean: 캐시 삭제로 이미지 크기 감소
RUN npm install --only=production && npm cache clean --force

# 애플리케이션 코드 복사
# 의존성 설치 후 코드를 복사하면 코드 변경 시 의존성 재설치를 방지할 수 있음
COPY server.js .

# 비특권 사용자 생성 및 전환 (보안 모범 사례)
# root 권한으로 컨테이너를 실행하지 않아 보안 위험을 줄임
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 && \
    chown -R appuser:nodejs /app
USER appuser

# 포트 노출 - 컨테이너가 3000번 포트를 사용함을 명시 (문서화 목적)
EXPOSE 3000

# 헬스체크 추가 - 컨테이너의 상태를 주기적으로 확인
# --interval: 30초마다 체크, --timeout: 3초 내 응답, --start-period: 시작 후 5초 대기
# --retries: 3번 실패 시 unhealthy 상태로 표시
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# 애플리케이션 실행 - 컨테이너 시작 시 실행될 기본 명령어
CMD ["npm", "start"]
EOF
```

> [!TIP]
> `USER appuser`로 비특권 사용자를 사용하면 컨테이너가 root 권한으로 실행되지 않아 보안이 강화됩니다. 프로덕션 환경에서는 반드시 적용해야 하는 모범 사례입니다.

### 3.2 Docker 이미지 빌드

7. Docker 이미지를 빌드합니다:

```bash
docker build -t cloudarchitect-lab-app:latest ~/docker-lab/
```

> [!NOTE]
> - `-t cloudarchitect-lab-app:latest`: 이미지에 이름(태그)을 지정합니다
>   - `cloudarchitect-lab-app`: 이미지 이름
>   - `latest`: 이미지 버전 태그 (기본값)
> - `~/docker-lab/`: Dockerfile이 있는 디렉토리 경로 (빌드 컨텍스트)

8. 빌드된 이미지를 확인합니다:

```bash
docker images cloudarchitect-lab-app
```

> [!OUTPUT]
> ```
> REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
> cloudarchitect-lab-app    latest    abc123def456   10 seconds ago   ~180MB
> ```

> [!NOTE]
> Alpine 기반 이미지를 사용하여 이미지 크기가 약 180MB로 경량화되었습니다. 일반 Node.js 이미지(~1GB)에 비해 크게 줄어듭니다.

✅ **태스크 완료**: Dockerfile을 작성하고 Docker 이미지를 빌드했습니다.


## 태스크 4: 컨테이너 실행 및 테스트

### 4.1 컨테이너 실행

9. 컨테이너를 백그라운드로 실행합니다:

```bash
docker run -d --name cloudarchitect-lab-app -p 8080:3000 cloudarchitect-lab-app:latest
```

> [!NOTE]
> Docker run 옵션 설명:
> - `-d`: 백그라운드(detached) 모드로 실행합니다
> - `--name cloudarchitect-lab-app`: 컨테이너에 이름을 지정합니다 (관리 편의성)
> - `-p 8080:3000`: 포트 매핑 (호스트:컨테이너)
>   - 호스트의 8080 포트로 들어오는 요청을 컨테이너의 3000 포트로 전달합니다
> - `cloudarchitect-lab-app:latest`: 실행할 이미지 이름과 태그

10. 컨테이너 상태를 확인합니다:

```bash
docker ps
```

> [!OUTPUT]
> ```
> CONTAINER ID   IMAGE                          STATUS          PORTS                    NAMES
> abc123def456   cloudarchitect-lab-app:latest   Up 5 seconds    0.0.0.0:8080->3000/tcp   cloudarchitect-lab-app
> ```

### 4.2 애플리케이션 테스트

11. 웹 페이지 응답을 확인합니다:

```bash
curl http://localhost:8080
```

> [!NOTE]
> `curl` 명령어는 HTTP 요청을 보내고 응답을 확인하는 도구입니다. 컨테이너가 정상적으로 실행 중이면 HTML 페이지가 출력됩니다.

12. 헬스 체크 엔드포인트를 확인합니다:

```bash
curl http://localhost:8080/health
```

> [!OUTPUT]
> ```json
> {"status":"healthy","timestamp":"2025-xx-xxTxx:xx:xx.xxxZ","message":"CloudArchitect Week 10-1 Docker App is running"}
> ```

13. 컨테이너 로그를 확인합니다:

```bash
docker logs cloudarchitect-lab-app
```

> [!NOTE]
> 컨테이너 내부에서 출력되는 모든 로그(console.log 등)를 확인할 수 있습니다. 애플리케이션 디버깅에 유용합니다.

✅ **태스크 완료**: Docker 컨테이너가 정상적으로 실행되고 웹 애플리케이션에 접근할 수 있습니다.


## 태스크 5: Amazon ECR 리포지토리 생성 및 이미지 푸시

> [!CONCEPT] Amazon ECR(Elastic Container Registry)
>
> Amazon ECR은 Docker 컨테이너 이미지를 저장, 관리, 배포하는 **완전 관리형 컨테이너 레지스트리**입니다. Amazon ECS, EKS 등 AWS 컨테이너 서비스와 네이티브로 통합되며, IAM 기반 접근 제어를 제공합니다.

### 5.1 Amazon ECR 리포지토리 생성

14. ECR 리포지토리를 생성합니다:

```bash
aws ecr create-repository --repository-name cloudarchitect-lab-app --region ap-northeast-2
```

15. 계정 ID를 변수에 저장합니다:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "계정 ID: $ACCOUNT_ID"
```

### 5.2 Amazon ECR 로그인 및 이미지 푸시

16. ECR에 로그인합니다:

```bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com
```

> [!NOTE]
> AWS CLI로 ECR 인증 토큰을 받아 Docker에 로그인합니다. 파이프(`|`)를 사용하여 비밀번호를 안전하게 전달합니다.

> [!OUTPUT]
> ```
> Login Succeeded
> ```

17. 이미지에 ECR 태그를 추가합니다:

```bash
docker tag cloudarchitect-lab-app:latest $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-app:latest
```

> [!NOTE]
> 로컬 이미지에 ECR 리포지토리 경로를 포함한 새로운 태그를 추가합니다. 하나의 이미지에 여러 태그를 붙일 수 있습니다.

18. 이미지를 ECR에 푸시합니다:

```bash
docker push $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-app:latest
```

> [!NOTE]
> 로컬 이미지를 ECR 리포지토리에 업로드합니다. 이미지 크기에 따라 수 초에서 수 분이 소요될 수 있습니다.

### 5.3 Amazon ECR 콘솔에서 확인

19. 상단 검색창에서 `ECR`을 검색하고 **ECR**을 선택합니다.

20. ECR 콘솔의 왼쪽 메뉴에서 **Private registry** 섹션 아래의 **Repositories**를 선택합니다.

21. `cloudarchitect-lab-app` 리포지토리를 선택합니다.

22. `latest` 태그가 있는 이미지가 표시되는지 확인합니다.

✅ **태스크 완료**: Docker 이미지가 Amazon ECR에 성공적으로 저장되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 태스크 1: CloudShell에서 Docker 리소스 정리

1. CloudShell에서 실행 중인 컨테이너를 정지하고 삭제합니다:

```bash
docker stop cloudarchitect-lab-app
docker rm cloudarchitect-lab-app
```

2. 로컬 Docker 이미지를 삭제합니다:

```bash
docker rmi cloudarchitect-lab-app:latest
```

3. ECR 이미지도 삭제합니다 (계정 ID 확인):

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker rmi $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-app:latest
```

4. 작업 디렉토리를 삭제합니다:

```bash
rm -rf ~/docker-lab
```

### 태스크 2: Amazon ECR 리포지토리 삭제

5. ECR 리포지토리를 삭제합니다:

```bash
aws ecr delete-repository --repository-name cloudarchitect-lab-app --region ap-northeast-2 --force
```

> [!OUTPUT]
> ```json
> {
>     "repository": {
>         "repositoryName": "cloudarchitect-lab-app",
>         "registryId": "xxxxxxxxxxxx"
>     }
> }
> ```

### 태스크 3: 최종 확인

6. 상단 검색창에서 `ECR`을 검색하고 **ECR**을 선택합니다.

7. 왼쪽 메뉴에서 **Repositories**를 선택합니다.

8. `cloudarchitect-lab-app` 리포지토리가 목록에 없는지 확인합니다.

9. CloudShell에서 Docker 이미지 목록을 확인합니다:

```bash
docker images
```

10. `cloudarchitect-lab-app` 관련 이미지가 없는지 확인합니다.

✅ **리소스 정리 완료**: 모든 Docker 컨테이너, 이미지, ECR 리포지토리가 삭제되었습니다.


## 💡 핵심 포인트 정리

🏗️
이미지 빌드 및 테스트
Docker 이미지를 빌드하고 로컬에서 컨테이너를 실행하여 애플리케이션을 테스트했습니다

🚀
배포 준비
ECR에 저장된 이미지를 Amazon ECS 등 AWS 컨테이너 서비스에서 배포할 수 있습니다
