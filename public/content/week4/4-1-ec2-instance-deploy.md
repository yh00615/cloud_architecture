---
title: 'Amazon EC2 인스턴스 생성'
week: 4
session: 1
awsServices:
  - Amazon EC2
learningObjectives:
  - Amazon EC2의 기본 개념과 아키텍처를 이해할 수 있습니다.
  - EC2 인스턴스 패밀리의 종류와 특징을 구분할 수 있습니다.
  - Amazon EC2 인스턴스를 생성하고 관리할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **AWS**의 가상 서버인 **EC2 인스턴스**를 생성하고 웹 서버를 배포합니다. **인스턴스 타입**을 선택하고 키 페어를 생성하여 **SSH 접속**을 준비합니다. **User Data 스크립트**로 **Apache 웹 서버**를 자동으로 설치하고, **보안 그룹**으로 HTTP와 SSH 포트를 개방합니다. 인스턴스가 실행되면 **퍼블릭 IP**로 웹 브라우저에서 접속하여 웹 페이지를 확인합니다.

> [!DOWNLOAD]
> [week4-1-ec2-instance-deploy.zip](/files/week4/week4-1-ec2-instance-deploy.zip)
>
> **포함 파일:**
> 
> **setup-4-1.sh** - 사전 환경 구축 스크립트
> - **목적**: EC2 인스턴스 생성 실습을 위한 네트워크 인프라 자동 구축
> - **생성 리소스**:
>   - VPC 네트워크 (VPC, Internet Gateway, Public Subnet, Route Table)
>   - Security Group (HTTP 80, SSH 22 포트 허용)
> - **실행 시간**: 약 2-3분
> - **활용**: 태스크 1-5에서 이 네트워크에 EC2 인스턴스를 생성하고 웹 서버를 배포합니다
>
> **cleanup-4-1.sh** - 리소스 정리 스크립트
> - **목적**: 실습에서 생성한 모든 리소스를 안전한 순서로 자동 삭제
> - **삭제 리소스**: EC2 인스턴스, Security Group, VPC 및 네트워크 리소스
> - **실행 시간**: 약 2-3분
>
> **사용 태스크:**
> - 태스크 0: 사전 환경 구축 (setup-4-1.sh 실행)
> - 리소스 정리: 실습 완료 후 cleanup-4-1.sh 실행

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - EC2 인스턴스 배포
>
> <img src="/images/week4/4-1-architecture-diagram.svg" alt="EC2 인스턴스 아키텍처 - VPC, Public Subnet, Internet Gateway, Security Group, EC2 인스턴스 구조" class="guide-img-lg" />

> [!CONCEPT] Amazon EC2란?
>
> Amazon EC2(Elastic Compute Cloud)는 AWS에서 제공하는 가상 서버 서비스입니다. 필요할 때 서버를 생성하고, 사용한 만큼만 비용을 지불합니다.
>
> - **인스턴스 타입**: CPU, 메모리 사양을 결정합니다 (예: t3.micro = vCPU 2개, 메모리 1GB)
> - **AMI(Amazon Machine Image)**: 운영체제와 소프트웨어가 사전 설치된 이미지입니다
> - **User Data**: 인스턴스 시작 시 자동으로 실행되는 부트스트랩 스크립트입니다
> - **Instance Connect**: 키 페어 없이 브라우저에서 SSH 접속이 가능한 기능입니다

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

### 0.1 사전 환경 구축의 목적

이 실습에서는 **Amazon EC2**를 사용하여 가상 서버를 생성하고 웹 서버를 구축하는 방법을 학습합니다. 이를 위해 다음과 같은 환경이 필요합니다:

**구축되는 인프라:**
- **VPC 네트워크**: 격리된 네트워크 환경에서 EC2 인스턴스를 안전하게 실행합니다
- **Internet Gateway**: VPC와 인터넷 간 통신을 가능하게 합니다
- **Public Subnet**: 인터넷에서 접근 가능한 서브넷으로, EC2 인스턴스가 배치됩니다
- **Route Table**: 인터넷 트래픽을 Internet Gateway로 라우팅합니다
- **Security Group**: HTTP(80), SSH(22) 트래픽만 허용하여 보안을 강화합니다

**실습에서의 활용:**
- **태스크 1**: 생성된 VPC 네트워크 인프라를 확인합니다
- **태스크 2**: 사전 구축된 네트워크에 EC2 인스턴스를 생성합니다
- **태스크 3**: User Data를 사용하여 웹 서버를 자동으로 설치합니다
- **태스크 4**: 웹 브라우저로 접속하여 웹 서버가 정상 작동하는지 확인합니다
- **태스크 5**: EC2 Instance Connect로 인스턴스에 접속하여 관리합니다

> [!TIP]
> 사전 환경 구축 스크립트는 네트워크 인프라를 자동으로 생성하므로, 여러분은 EC2 인스턴스 생성과 웹 서버 구축에만 집중할 수 있습니다.

### 0.2 환경 구축 실행

1. 위 DOWNLOAD 섹션에서 `week4-1-ec2-instance-deploy.zip` 파일을 다운로드합니다.

2. AWS 콘솔 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** → **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어를 실행합니다:

```bash
unzip week4-1-ec2-instance-deploy.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-4-1.sh cleanup-4-1.sh
./setup-4-1.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 내용을 확인하고 `y`를 입력하여 진행합니다.

> [!WARNING] 스크립트 실행 시간:
> 사전 환경 구축에 약 2-3분이 소요됩니다. 스크립트가 완료될 때까지 기다려주세요.

### 0.3 생성된 리소스 확인

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 유형 | 리소스 이름 | 실습에서의 역할 |
|------------|------------|----------------|
| VPC | CloudArchitect-Lab-VPC | EC2 인스턴스를 위한 격리된 네트워크 환경 |
| Internet Gateway | CloudArchitect-Lab-IGW | 인터넷 연결을 위한 게이트웨이 |
| Public Subnet | CloudArchitect-Lab-Public-Subnet | EC2 인스턴스가 배치되는 서브넷 |
| Route Table | CloudArchitect-Lab-Public-RT | 인터넷 트래픽 라우팅 |
| Security Group | CloudArchitect-Lab-Web-SG | HTTP(80), SSH(22) 트래픽 허용 |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week4-1-ec2-instance-deploy.zip setup-4-1.sh cleanup-4-1.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 Amazon VPC 네트워크 확인

8. AWS Management Console에 로그인한 후 상단 검색창에 `VPC`를 검색하고 **VPC**를 선택합니다.

9. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

10. **CloudArchitect-Lab-VPC**를 찾아 선택합니다.

11. **CIDR 블록**이 **10.0.0.0/16**인지 확인합니다.

12. **DNS hostnames**와 **DNS resolution**이 모두 **Enabled**인지 확인합니다.

> [!TIP]
> DNS hostnames가 Enabled여야 EC2 인스턴스에 퍼블릭 DNS 이름이 자동으로 할당됩니다. 이 설정이 없으면 IP 주소로만 접근해야 합니다.

### 1.2 Internet Gateway 확인

13. 왼쪽 메뉴에서 **Internet Gateways**를 선택합니다.

14. **CloudArchitect-Lab-IGW**를 찾아 선택합니다.

15. **State**가 **Attached**인지, **VPC ID**가 **CloudArchitect-Lab-VPC**와 연결되어 있는지 확인합니다.

### 1.3 Public Subnet 확인

16. 왼쪽 메뉴에서 **Subnets**를 선택합니다.

17. **CloudArchitect-Lab-Public-Subnet**을 찾아 선택합니다.

18. 다음 설정을 확인합니다:
- **IPv4 CIDR**: **10.0.0.0/24**
- **Availability zone**: **ap-northeast-2a**
- **Auto-assign public IPv4 address**: **Yes**

> [!NOTE]
> Auto-assign public IPv4 address가 "Yes"로 설정되어 있어야 이 서브넷에 생성되는 EC2 인스턴스에 자동으로 퍼블릭 IP가 할당됩니다.

### 1.4 Route Table 확인

19. 왼쪽 메뉴에서 **Route Tables**를 선택합니다.

20. **CloudArchitect-Lab-Public-RT**를 찾아 선택합니다.

21. **Routes** 탭을 선택합니다.

22. **0.0.0.0/0** 경로가 **Internet Gateway(igw-xxx)**로 설정되어 있는지 확인합니다.

23. **Subnet associations** 탭을 선택하여 **CloudArchitect-Lab-Public-Subnet**이 연결되어 있는지 확인합니다.

> [!IMPORTANT]
> `0.0.0.0/0 → igw-xxx` 라우팅 규칙이 없으면 EC2 인스턴스가 인터넷에 접근할 수 없습니다. 이 규칙이 Public Subnet을 "Public"으로 만드는 핵심 설정입니다.

### 1.5 보안 그룹 확인

24. AWS Management Console에 로그인한 후 상단 검색창에 `EC2`를 검색하고 **EC2**를 선택합니다.

25. EC2 콘솔의 왼쪽 메뉴에서 **Network & Security** 섹션 아래의 **Security Groups**를 선택합니다.

26. **CloudArchitect-Lab-Web-SG**를 찾아 선택합니다.

27. **Inbound rules** 탭에서 다음 규칙이 설정되어 있는지 확인합니다:

| Type | Source type | Source | Description | 용도 |
|------|-------------|--------|-------------|------|
| SSH (22) | Anywhere-IPv4 | 0.0.0.0/0 | Allow SSH | EC2 Instance Connect 접속 |
| HTTP (80) | Anywhere-IPv4 | 0.0.0.0/0 | Allow HTTP | 웹 서버 접근 |

> [!SUCCESS] 네트워크 환경 준비 완료:
> VPC, 서브넷, 라우팅 테이블, 보안 그룹이 모두 준비되었습니다. 이제 EC2 인스턴스를 생성합니다.

✅ **태스크 완료**: VPC, 서브넷, 라우팅 테이블, 보안 그룹이 정상적으로 구축되어 있음을 확인했습니다.


## 태스크 2: Amazon EC2 인스턴스 생성

> [!CONCEPT] User Data와 IMDSv2
>
> **User Data**는 EC2 인스턴스가 처음 시작될 때 자동으로 실행되는 스크립트입니다. 서버 초기 설정을 자동화할 수 있어 매번 수동으로 소프트웨어를 설치할 필요가 없습니다.
>
> **IMDSv2(Instance Metadata Service v2)**는 EC2 인스턴스 내부에서 자신의 메타데이터(인스턴스 ID, IP 주소 등)를 조회하는 보안 강화된 방식입니다. 토큰 기반 인증을 사용하여 SSRF(Server-Side Request Forgery) 공격을 방지합니다.

### 2.1 기본 설정

28. EC2 콘솔에서 왼쪽 메뉴의 **Instances**를 선택합니다.

29. 오른쪽 상단의 [[Launch instances]] 버튼을 클릭합니다.

30. **Name and tags** 섹션의 **Name** 필드에 `CloudArchitect-Lab-WebServer`를 입력합니다.

31. **Name** 필드 아래의 **Add additional tags** 링크를 클릭합니다.

32. **Add new tag** 버튼을 클릭하고 다음과 같이 입력합니다:
- **Key**: `StudentId`
- **Value**: `[본인 학번]` (예: 20241234)
- **Resource types**: `Instances`와 `Volumes` 모두 체크 ✅

> [!TIP]
> StudentId 태그를 추가하면 공유 AWS 계정에서 본인의 리소스를 쉽게 구분할 수 있습니다. Resource types에서 Instances와 Volumes를 모두 체크하면 EC2 인스턴스와 연결된 EBS 볼륨에도 태그가 자동으로 적용됩니다.

33. **Application and OS Images (Amazon Machine Image)** 섹션에서 기본 선택된 **Amazon Linux 2023 AMI**를 그대로 사용합니다.

34. **Instance type**에서 **t3.micro**를 선택합니다.

35. **Key pair (login)**에서 **Proceed without a key pair (Not recommended)**를 선택합니다.

> [!TIP]
> EC2 Instance Connect를 사용하면 키 페어 없이도 브라우저에서 SSH 접속이 가능합니다.

### 2.2 네트워크 설정

36. **Network settings** 섹션에서 [[Edit]] 버튼을 클릭합니다.

37. **VPC**에서 **CloudArchitect-Lab-VPC**를 선택합니다.

38. **Subnet**에서 **CloudArchitect-Lab-Public-Subnet**을 선택합니다.

39. **Auto-assign public IP**에서 **Enable**을 선택합니다.

40. **Firewall (security groups)**에서 **Select existing security group**을 선택합니다.

41. **CloudArchitect-Lab-Web-SG**를 선택합니다.

### 2.3 User Data 스크립트 설정

42. 페이지를 아래로 스크롤하여 **Advanced details** 섹션을 클릭해 확장합니다.

43. 맨 아래의 **User data** 텍스트 박스에 다음 스크립트를 입력합니다:

```bash
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# EC2 Instance Connect 설정
dnf install -y ec2-instance-connect
systemctl enable ec2-instance-connect
systemctl start ec2-instance-connect

# SSH 서비스 재시작
systemctl restart sshd

# 메타데이터 정보 가져오기 (IMDSv2 방식)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s 2>/dev/null || echo "")
if [ -n "$TOKEN" ]; then
    INSTANCE_ID_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "N/A")
    AZ_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "N/A")
    PUBLIC_IP_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
    PRIVATE_IP_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "N/A")
else
    INSTANCE_ID_META="N/A"
    AZ_META="N/A"
    PUBLIC_IP_META="N/A"
    PRIVATE_IP_META="N/A"
fi

# 웹 페이지 생성 (메타데이터 직접 삽입)
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html>
<head>
    <title>CloudArchitect Lab05 - EC2 Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success { color: #27ae60; font-weight: bold; }
        .meta-value { color: #e74c3c; font-family: monospace; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 CloudArchitect Lab05 성공!</h1>
        <div class="info">
            <h3>EC2 인스턴스 정보:</h3>
            <p><strong>인스턴스 ID:</strong> <span class="meta-value">$INSTANCE_ID_META</span></p>
            <p><strong>가용 영역:</strong> <span class="meta-value">$AZ_META</span></p>
            <p><strong>퍼블릭 IP:</strong> <span class="meta-value">$PUBLIC_IP_META</span></p>
            <p><strong>프라이빗 IP:</strong> <span class="meta-value">$PRIVATE_IP_META</span></p>
        </div>
        <div class="success">
            ✅ Apache 웹 서버가 성공적으로 설치되고 실행 중입니다!
        </div>
        <p>이 페이지는 EC2 인스턴스의 User Data를 통해 자동으로 생성되었습니다.</p>
        <p><small>생성 시간: $(date)</small></p>
    </div>
</body>
</html>
HTML
```

44. 페이지 오른쪽 하단의 [[Launch instance]] 버튼을 클릭합니다.

45. 성공 메시지가 표시되면 [[View all instances]]를 클릭합니다.

> [!NOTE]
> 인스턴스가 시작되면 User Data 스크립트가 자동으로 실행됩니다. Apache 웹 서버 설치와 웹 페이지 생성까지 약 3-5분이 소요됩니다.

✅ **태스크 완료**: User Data 스크립트가 포함된 EC2 인스턴스가 생성되었습니다.


## 태스크 3: 웹 서버 테스트 및 관리

### 3.1 인스턴스 시작 확인

46. **CloudArchitect-Lab-WebServer** 인스턴스의 **Instance state**가 **Running**으로 변경될 때까지 기다립니다.

47. **Status check**가 **2/2 checks passed**로 변경될 때까지 기다립니다 (약 3-5분 소요).

> [!NOTE] User Data 스크립트 실행 확인
>
> User Data 스크립트는 인스턴스가 처음 시작될 때 root 권한으로 자동 실행됩니다. 실행 완료 여부는 다음 방법으로 확인할 수 있습니다:
>
> 1. **Status check**: "2/2 checks passed"가 표시되면 인스턴스가 정상 작동 중입니다
>    - 1/2: 시스템 상태 체크 (AWS 인프라 레벨 - 하드웨어, 네트워크)
>    - 2/2: 인스턴스 상태 체크 (OS 및 네트워크 설정)
>
> 2. **웹 서버 접속**: HTTP로 접속하여 웹 페이지가 표시되면 스크립트 실행 완료
>
> 3. **로그 확인** (Instance Connect 접속 후):
>    ```bash
>    sudo cat /var/log/cloud-init-output.log
>    ```
>    이 로그 파일에서 User Data 스크립트의 모든 실행 과정과 오류를 확인할 수 있습니다.

48. 인스턴스를 선택하고 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

### 3.2 웹 서버 동작 확인

49. 새 브라우저 탭에서 `http://[복사한 Public IP]`로 접속합니다.

50. **CloudArchitect Lab05 성공!** 페이지가 표시되는지 확인합니다.

51. 웹 페이지에 인스턴스 ID, 가용 영역, IP 주소 정보가 표시되는지 확인합니다.

> [!TROUBLESHOOTING]
> 페이지가 로드되지 않는 경우:
> - **Status check**가 `2/2 checks passed`인지 확인합니다 (User Data 실행 완료 전일 수 있음)
> - 주소가 `https://`가 아닌 `http://`로 시작하는지 확인합니다
> - 보안 그룹에 HTTP(80) 인바운드 규칙이 있는지 확인합니다
> - 2-3분 더 기다린 후 다시 시도합니다

### 3.3 Instance Connect를 통한 SSH 접속

52. EC2 콘솔에서 **CloudArchitect-Lab-WebServer** 인스턴스를 선택합니다.

53. 상단의 [[Connect]] 버튼을 클릭합니다.

54. **EC2 Instance Connect** 탭에서 **User name**이 **ec2-user**인지 확인합니다.

55. [[Connect]] 버튼을 클릭합니다.

56. 터미널이 열리면 다음 명령어를 실행합니다:

```bash
# 시스템 정보 확인
uname -a
```

> [!OUTPUT]
> ```
> Linux ip-10-0-0-xxx.ap-northeast-2.compute.internal 6.1.xxx ... x86_64 GNU/Linux
> ```

```bash
# 웹 서버 상태 확인
sudo systemctl status httpd
```

> [!OUTPUT]
> ```
> ● httpd.service - The Apache HTTP Server
>      Loaded: loaded
>      Active: active (running)
> ```

```bash
# 로컬에서 웹 페이지 응답 확인
curl -s localhost | head -5
```

> [!SUCCESS] EC2 Instance Connect 접속 완료:
> 브라우저를 통해 EC2 인스턴스에 성공적으로 접속했습니다. 별도의 SSH 클라이언트나 키 파일 없이도 서버 관리가 가능합니다.

✅ **태스크 완료**: 웹 서버 접속과 Instance Connect를 통한 SSH 접속을 확인했습니다.


## 태스크 4: 실습 완료 후 리소스 정리

### 4.1 Amazon EC2 인스턴스 종료

57. EC2 콘솔에서 **CloudArchitect-Lab-WebServer** 인스턴스를 선택합니다.

58. 상단의 **Instance state** > **Terminate instance**를 선택합니다.

59. 확인 창에서 [[Terminate]]를 클릭합니다.

> [!NOTE]
> 인스턴스 상태가 "Shutting-down"을 거쳐 "Terminated"로 변경됩니다. 종료된 인스턴스는 약 1시간 후 목록에서 자동으로 사라집니다.

### 4.2 Cleanup 스크립트 실행

60. CloudShell에서 cleanup 스크립트를 실행합니다:

```bash
./cleanup-4-1.sh
```

> [!WARNING]
> EC2 인스턴스를 먼저 종료(Terminate)한 후 cleanup 스크립트를 실행합니다. 인스턴스가 실행 중이면 보안 그룹 삭제가 실패할 수 있습니다.

✅ **실습 종료**: 모든 리소스가 정리되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-4-1.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - EC2 인스턴스 (`CloudArchitect-Lab-WebServer`)
   - Security Group (`CloudArchitect-Lab-Web-SG`)
   - VPC 및 관련 리소스 (`CloudArchitect-Lab-VPC`)

> [!NOTE]
> 정리 스크립트는 이 실습에서 생성한 리소스만 삭제합니다. 다른 리소스에는 영향을 주지 않습니다.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> 삭제 순서가 중요합니다. 의존 관계가 있는 리소스는 먼저 삭제해야 다음 리소스를 삭제할 수 있습니다.

#### 태스크 1: Amazon EC2 인스턴스 종료

1. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

2. 왼쪽 메뉴에서 **Instances**를 선택합니다.

3. **CloudArchitect-Lab-WebServer** 인스턴스를 선택합니다.

4. **Instance state** > **Terminate instance**를 선택합니다.

5. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

> [!NOTE]
> 인스턴스 상태가 "Terminated"로 변경될 때까지 약 1-2분 기다립니다. 인스턴스가 완전히 종료되어야 보안 그룹을 삭제할 수 있습니다.

#### 태스크 2: Security Group 삭제

6. 왼쪽 메뉴의 **Network & Security** 섹션에서 **Security Groups**를 선택합니다.

7. **CloudArchitect-Lab-Web-SG**를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

8. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 3: Amazon VPC 삭제

> [!TIP]
> VPC를 삭제하면 연결된 서브넷, 라우팅 테이블, Internet Gateway가 함께 삭제됩니다.

9. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

10. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

11. **CloudArchitect-Lab-VPC**를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

12. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: 최종 확인

13. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

14. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

15. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: **Asia Pacific (Seoul) ap-northeast-2**
   - **Resource types**: **All supported resource types**
   - **Tags**: Tag key에 **StudentId**를 선택하고, Tag value에 본인 학번을 입력합니다.

> [!TIP]
> StudentId 태그로 검색하면 본인이 생성한 리소스만 정확히 확인할 수 있습니다. Name 태그로 검색하려면 Tag key를 `Name`, Tag value를 `CloudArchitect-Lab`로 입력합니다.

16. [[Search resources]]를 클릭합니다.

17. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

18. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🖥️
EC2 인스턴스 타입
범용(t3), 컴퓨팅 최적화(c5), 메모리 최적화(r5) 등 워크로드에 따라 적합한 인스턴스 패밀리를 선택합니다.

🔑
키 페어 인증
EC2 인스턴스에 SSH 접속하려면 키 페어(공개키/개인키)를 생성하고 개인키(.pem)를 안전하게 보관해야 합니다.

💾
EBS 볼륨
EC2 인스턴스의 영구 스토리지로, 인스턴스를 중지해도 데이터가 유지되며 크기와 타입을 선택할 수 있습니다.

📝
User Data 스크립트
인스턴스 시작 시 자동으로 실행되는 스크립트로, 소프트웨어 설치나 초기 설정을 자동화할 수 있습니다.

🌐
퍼블릭 IP와 Elastic IP
퍼블릭 IP는 인스턴스 재시작 시 변경되지만, Elastic IP는 고정 IP 주소로 인스턴스에 연결할 수 있습니다.

🔒
보안 그룹 규칙
인바운드 규칙으로 허용된 트래픽만 인스턴스에 도달할 수 있으며, SSH(22), HTTP(80) 등 포트별로 설정합니다.
