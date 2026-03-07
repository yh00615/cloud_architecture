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

> [!NOTE]
> 이 실습에서는 Docker를 사용하여 Node.js 애플리케이션을 컨테이너화하고 Amazon ECR에 이미지를 저장하는 방법을 학습합니다. 사전 구축 스크립트 없이 CloudShell에서 직접 진행합니다.

> [!CONCEPT] Docker 컨테이너란?
>
> Docker는 애플리케이션을 **컨테이너**라는 격리된 환경에서 실행하는 플랫폼입니다.
>
> - **이미지(Image)**: 애플리케이션 코드, 런타임, 라이브러리를 포함한 읽기 전용 템플릿입니다
> - **컨테이너(Container)**: 이미지를 기반으로 실행되는 격리된 프로세스입니다
> - **Dockerfile**: 이미지를 빌드하기 위한 명령어를 정의한 텍스트 파일입니다
> - **레지스트리(Registry)**: 이미지를 저장하고 배포하는 저장소입니다 (Amazon ECR, Docker Hub 등)
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
        <title>Lab14 Docker App</title>
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
            <h1>🐳 Lab14 Docker Application</h1>
            <div class="info">
                <p>Docker 컨테이너가 성공적으로 실행되고 있습니다.</p>
                <p class="highlight">CloudArchitect AWS 가이드 - Lab14</p>
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
    message: 'Lab14 Docker App is running'
  });
});

app.listen(port, () => {
  console.log(`Lab14 Docker App running on port ${port}`);
});
SERVEREOF
```

✅ **태스크 완료**: Node.js 웹 애플리케이션 파일이 생성되었습니다.


## 태스크 3: Dockerfile 작성 및 이미지 빌드

> [!CONCEPT] Dockerfile 주요 명령어
>
> | 명령어 | 설명 |
> |--------|------|
> | `FROM` | 베이스 이미지를 지정합니다 (예: `node:18-alpine`) |
> | `WORKDIR` | 컨테이너 내 작업 디렉토리를 설정합니다 |
> | `COPY` | 호스트 파일을 컨테이너로 복사합니다 |
> | `RUN` | 이미지 빌드 시 실행할 명령어입니다 |
> | `EXPOSE` | 컨테이너가 사용하는 포트를 명시합니다 |
> | `CMD` | 컨테이너 시작 시 실행할 기본 명령어입니다 |

### 3.1 Dockerfile 생성

6. Dockerfile을 작성합니다:

```bash
cat > ~/docker-lab/Dockerfile << 'EOF'
FROM node:18-alpine

# 메타데이터
LABEL maintainer="Lab14 Student"
LABEL description="Lab14 Docker Container Application"
LABEL version="1.0"

# 작업 디렉토리 설정
WORKDIR /app

# 패키지 파일 복사 및 의존성 설치
COPY package*.json ./
RUN npm install --only=production && npm cache clean --force

# 애플리케이션 코드 복사
COPY server.js .

# 비특권 사용자 생성 및 전환
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 && \
    chown -R appuser:nodejs /app
USER appuser

# 포트 노출
EXPOSE 3000

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# 애플리케이션 실행
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
> `-d`는 백그라운드 실행, `-p 8080:3000`은 호스트의 8080 포트를 컨테이너의 3000 포트에 매핑합니다. `--name`으로 컨테이너에 이름을 지정합니다.

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

12. 헬스 체크 엔드포인트를 확인합니다:

```bash
curl http://localhost:8080/health
```

> [!OUTPUT]
> ```json
> {"status":"healthy","timestamp":"2025-xx-xxTxx:xx:xx.xxxZ","message":"Lab14 Docker App is running"}
> ```

13. 컨테이너 로그를 확인합니다:

```bash
docker logs cloudarchitect-lab-app
```

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

> [!OUTPUT]
> ```
> Login Succeeded
> ```

17. 이미지에 ECR 태그를 추가합니다:

```bash
docker tag cloudarchitect-lab-app:latest $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-app:latest
```

18. 이미지를 ECR에 푸시합니다:

```bash
docker push $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-app:latest
```

### 5.3 Amazon ECR 콘솔에서 확인

19. 상단 검색창에서 `ECR`을 검색하고 **ECR**을 선택합니다.

20. ECR 콘솔의 왼쪽 메뉴에서 **Private registry** 섹션 아래의 **Repositories**를 선택합니다.

21. `cloudarchitect-lab-app` 리포지토리를 선택합니다.

22. `latest` 태그가 있는 이미지가 표시되는지 확인합니다.

✅ **태스크 완료**: Docker 이미지가 Amazon ECR에 성공적으로 저장되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: 최종 확인

1. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

2. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

3. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

4. [[Search resources]]를 클릭합니다.

5. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

6. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🏗️
이미지 빌드 및 테스트
Docker 이미지를 빌드하고 로컬에서 컨테이너를 실행하여 애플리케이션을 테스트했습니다

🚀
배포 준비
ECR에 저장된 이미지를 Amazon ECS 등 AWS 컨테이너 서비스에서 배포할 수 있습니다
