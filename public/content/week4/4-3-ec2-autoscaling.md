---
title: 'Amazon EC2 Auto Scaling 환경 구축'
week: 4
session: 3
awsServices:
  - Amazon EC2
  - Elastic Load Balancing
learningObjectives:
  - Amazon EC2 Auto Scaling의 개념과 주요 이점을 이해할 수 있습니다.
  - Auto Scaling 그룹의 구성 요소(시작 템플릿, 조정 정책)를 설명할 수 있습니다.
  - 다양한 로드 밸런서 유형의 특징을 파악하고 적절한 사용 사례를 구분할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 트래픽에 따라 자동으로 확장되는 고가용성 웹 서비스를 구축합니다. **시작 템플릿**으로 **EC2 인스턴스** 설정을 정의하고, **Auto Scaling 그룹**으로 최소/최대 용량을 설정합니다. **Application Load Balancer**를 생성하여 여러 인스턴스에 트래픽을 분산하고, **타겟 그룹**으로 헬스 체크를 설정합니다. 마지막으로 **동적 확장 정책**을 구성하여 **CPU 사용률**에 따라 인스턴스가 자동으로 추가되거나 제거되는 것을 확인합니다.

> [!DOWNLOAD]
> [week4-3-ec2-autoscaling.zip](/files/week4/week4-3-ec2-autoscaling.zip)
>
> **포함 파일:**
> 
> **setup-4-3.sh** - 사전 환경 구축 스크립트
> - **목적**: Auto Scaling 실습을 위한 Multi-AZ 네트워크와 템플릿 웹 서버 자동 구축
> - **생성 리소스**:
>   - VPC 네트워크 (VPC, Internet Gateway, 2개 AZ의 Public Subnet, Route Table)
>   - Security Group (HTTP 80, SSH 22 포트 허용)
>   - EC2 인스턴스 (AMI 생성을 위한 템플릿 웹 서버)
> - **실행 시간**: 약 3-5분
> - **활용**: 태스크 1에서 이 인스턴스로 AMI를 생성하고, 태스크 2-5에서 Auto Scaling과 Load Balancer를 구성합니다
>
> **cleanup-4-3.sh** - 리소스 정리 스크립트
> - **목적**: 실습에서 생성한 모든 리소스를 안전한 순서로 자동 삭제
> - **삭제 리소스**: Auto Scaling Group, Launch Template, ALB, Target Group, EC2 인스턴스, Security Group, VPC 및 네트워크 리소스
> - **실행 시간**: 약 3-5분
>
> **사용 태스크:**
> - 태스크 0: 사전 환경 구축 (setup-4-3.sh 실행)
> - 리소스 정리: 실습 완료 후 cleanup-4-3.sh 실행

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - Auto Scaling 아키텍처
>
> <img src="/images/week4/4-3-architecture-diagram.svg" alt="EC2 Auto Scaling 아키텍처 - VPC 내 2개 AZ에 ALB, Auto Scaling Group, CloudWatch 경보 기반 스케일링 구조" class="guide-img-lg" />

> [!CONCEPT] Auto Scaling과 Load Balancer
>
> **Auto Scaling**은 트래픽 변화에 따라 EC2 인스턴스 수를 자동으로 조절하는 서비스입니다. CPU 사용률이 높아지면 인스턴스를 추가하고, 낮아지면 제거하여 비용을 최적화합니다.
>
> **Application Load Balancer(ALB)**는 여러 인스턴스에 HTTP/HTTPS 트래픽을 균등하게 분산합니다. 헬스 체크를 통해 정상 인스턴스에만 트래픽을 전달하여 서비스 가용성을 보장합니다.
>
> 이 두 서비스를 함께 사용하면 트래픽 증가 시 자동으로 서버를 늘리고, 줄어들면 자동으로 축소하는 탄력적인 웹 서비스를 구축할 수 있습니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

### 0.1 사전 환경 구축의 목적

이 실습에서는 **Auto Scaling**과 **Elastic Load Balancer**를 사용하여 트래픽에 따라 자동으로 확장/축소되는 웹 서비스를 구축하는 방법을 학습합니다. 이를 위해 다음과 같은 환경이 필요합니다:

**구축되는 인프라:**
- **VPC 네트워크 (Multi-AZ)**: 2개 가용 영역에 Public 서브넷을 구성하여 고가용성을 확보합니다
- **Internet Gateway**: VPC와 인터넷 간 통신을 가능하게 합니다
- **Security Group**: HTTP(80), SSH(22) 트래픽을 허용합니다
- **EC2 인스턴스 (템플릿용)**: Auto Scaling에서 사용할 AMI를 생성하기 위한 기본 웹 서버입니다

**실습에서의 활용:**
- **태스크 1**: 생성된 웹 서버 인스턴스를 확인하고 AMI를 생성합니다
- **태스크 2**: Application Load Balancer를 생성하여 트래픽을 분산합니다
- **태스크 3**: Launch Template을 생성하여 Auto Scaling 설정을 정의합니다
- **태스크 4**: Auto Scaling Group을 생성하고 스케일링 정책을 설정합니다
- **태스크 5**: 부하 테스트를 통해 자동 확장/축소를 확인합니다

> [!TIP]
> 사전 환경 구축 스크립트는 Multi-AZ 네트워크와 템플릿용 웹 서버를 자동으로 생성하므로, 여러분은 Auto Scaling과 Load Balancer 구성에만 집중할 수 있습니다.

### 0.2 환경 구축 실행

1. 위 DOWNLOAD 섹션에서 `week4-3-ec2-autoscaling.zip` 파일을 다운로드합니다.

2. AWS 콘솔 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** → **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어를 실행합니다:

```bash
unzip week4-3-ec2-autoscaling.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-4-3.sh
./setup-4-3.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 내용을 확인하고 `y`를 입력하여 진행합니다.

> [!WARNING] 스크립트 실행 시간:
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다려주세요.

### 0.3 생성된 리소스 확인

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 유형 | 리소스 이름 | 실습에서의 역할 |
|------------|------------|----------------|
| VPC | CloudArchitect-Lab-VPC | Auto Scaling 인스턴스를 위한 격리된 네트워크 환경 |
| Internet Gateway | CloudArchitect-Lab-IGW | 인터넷 연결을 위한 게이트웨이 |
| Public Subnet 1 | CloudArchitect-Lab-Public-Subnet-1 | 첫 번째 가용 영역의 서브넷 (Multi-AZ) |
| Public Subnet 2 | CloudArchitect-Lab-Public-Subnet-2 | 두 번째 가용 영역의 서브넷 (Multi-AZ) |
| Route Table | CloudArchitect-Lab-Public-RT | 인터넷 트래픽 라우팅 |
| Security Group | CloudArchitect-Lab-WebServer-SG | HTTP(80), SSH(22) 트래픽 허용 |
| EC2 인스턴스 | CloudArchitect-Lab-WebServer | AMI 생성을 위한 템플릿 웹 서버 |

8. 출력 메시지에서 EC2 인스턴스의 **Public IP 주소**를 확인하고 메모합니다.

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week4-3-ec2-autoscaling.zip setup-4-3.sh cleanup-4-3.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 기존 인스턴스 확인

### 1.1 사전 구축된 웹 서버 인스턴스 확인

8. AWS Management Console에 로그인한 후 상단 검색창에 `EC2`를 검색하고 **EC2**를 선택합니다.

9. 왼쪽 메뉴에서 **Instances**를 선택합니다.

10. **CloudArchitect-Lab-WebServer** 인스턴스를 찾아 선택합니다.

11. 인스턴스 상태가 "Running"인지 확인합니다.

12. 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

13. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속하여 웹 서버가 정상 작동하는지 확인합니다.

### 1.2 네트워크 환경 확인

14. AWS Management Console에 로그인한 후 상단 검색창에 `VPC`를 검색하고 **VPC**를 선택합니다.

15. 왼쪽 메뉴에서 **Subnets**를 선택합니다.

16. 다음 2개의 서브넷이 있는지 확인합니다:
- **CloudArchitect-Lab-Public-Subnet-1** (ap-northeast-2a)
- **CloudArchitect-Lab-Public-Subnet-2** (ap-northeast-2c)

> [!IMPORTANT]
> Application Load Balancer는 최소 2개의 가용 영역에 서브넷이 필요합니다. 서브넷이 1개만 있으면 ALB 생성이 실패합니다.

### 1.3 보안 그룹 확인

17. 왼쪽 메뉴에서 **Security Groups**를 선택합니다.

18. **CloudArchitect-Lab-WebServer-SG**를 찾아 선택합니다.

19. **Inbound rules** 탭에서 SSH(22)와 HTTP(80) 규칙이 설정되어 있는지 확인합니다.

✅ **태스크 완료**: 사전 구축된 EC2 인스턴스, 네트워크 환경, 보안 그룹을 확인했습니다.


## 태스크 2: Amazon EC2 Launch Template 생성

Launch Template은 Auto Scaling Group이 새 인스턴스를 생성할 때 사용하는 설정 템플릿입니다. AMI, 인스턴스 타입, 보안 그룹, User Data 등을 미리 정의합니다.

### 2.1 Launch Template 생성 시작

20. AWS Management Console에 로그인한 후 상단 검색창에 `EC2`를 검색하고 **EC2**를 선택합니다.

21. EC2 콘솔의 왼쪽 메뉴에서 **Instances** 섹션 아래의 **Launch Templates**를 선택합니다.

22. [[Create launch template]] 버튼을 클릭합니다.

23. **Launch template name**에 `CloudArchitect-Lab-WebServer-Template`를 입력합니다.

24. **Template version description**에 `Web server template for Auto Scaling`를 입력합니다.

25. **Auto Scaling guidance** 체크박스를 체크합니다.

> [!TIP]
> Auto Scaling guidance를 체크하면 Auto Scaling에 필요한 설정 항목이 강조 표시되어 누락을 방지할 수 있습니다.

### 2.2 AMI 및 인스턴스 타입 설정

26. **Application and OS Images**에서 `Amazon Linux 2023 AMI`를 선택합니다.

27. **Instance type**에서 `t3.micro`를 선택합니다.

28. **Key pair (login)**에서 `Proceed without a key pair`를 선택합니다.

### 2.3 보안 설정

29. **Network settings** 섹션에서 **Firewall (security groups)**의 `Select existing security group`를 선택합니다.

30. **Common security groups**에서 **CloudArchitect-Lab-WebServer-SG**를 선택합니다.

### 2.4 User Data 스크립트 설정

31. **Advanced details** 섹션을 확장합니다. **Advanced details**는 **Network settings** 아래에 접힌 상태로 있습니다. 섹션 제목을 클릭하여 확장합니다.

32. **Advanced details** 섹션 내에서 맨 아래로 스크롤하면 **User data** 텍스트 박스가 있습니다. 다음 스크립트를 입력합니다:

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

# 인스턴스별 고유 웹 페이지 생성 (IMDSv2 방식)
TOKEN=$(curl -s -f -m 5 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    INSTANCE_ID=$(curl -s -m 5 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
    AZ=$(curl -s -m 5 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "unknown")
    PRIVATE_IP=$(curl -s -m 5 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "unknown")
else
    INSTANCE_ID="unknown"
    AZ="unknown"
    PRIVATE_IP="unknown"
fi

cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head><title>Lab06: Auto Scaling Web Server</title></head>
<body style="font-family: Arial; margin: 40px; background: #e8f4fd;">
  <h1>🚀 Lab06: Auto Scaling Web Server</h1>
  <h2>서버 정보</h2>
  <p><strong>인스턴스 ID:</strong> $INSTANCE_ID</p>
  <p><strong>가용 영역:</strong> $AZ</p>
  <p><strong>프라이빗 IP:</strong> $PRIVATE_IP</p>
  <p><strong>생성 시간:</strong> $(date)</p>
  <p>이 서버는 Auto Scaling Group에 의해 자동으로 생성되었습니다.</p>
</body>
</html>
EOF
```

33. [[Create launch template]] 버튼을 클릭합니다.

> [!SUCCESS] Launch Template 생성 완료:
> Auto Scaling Group에서 사용할 인스턴스 템플릿이 생성되었습니다. 이 템플릿을 기반으로 동일한 구성의 인스턴스들이 자동으로 생성됩니다.

✅ **태스크 완료**: Auto Scaling용 Launch Template이 생성되었습니다.


## 태스크 3: Amazon EC2 Auto Scaling Group 생성

> [!CONCEPT] Target Tracking Scaling Policy
>
> Target Tracking은 지정한 메트릭(예: CPU 사용률)을 목표값에 맞추도록 자동으로 인스턴스 수를 조절합니다.
>
> - CPU 사용률이 70%를 **초과**하면 → 인스턴스를 **추가** (Scale Out)
> - CPU 사용률이 70% **미만**으로 떨어지면 → 인스턴스를 **제거** (Scale In)
> - **Cooldown 기간**(기본 300초) 동안은 추가 스케일링이 방지되어 급격한 변동을 막습니다

### 3.1 Auto Scaling Group 생성 시작

34. EC2 콘솔에서 왼쪽 메뉴의 맨 아래 **Auto Scaling** 섹션 아래의 **Auto Scaling Groups**를 선택합니다.

35. [[Create Auto Scaling group]] 버튼을 클릭합니다.

36. **Auto Scaling group name**에 `CloudArchitect-Lab-ASG`를 입력합니다.

37. **Launch template**에서 **CloudArchitect-Lab-WebServer-Template**를 선택합니다.

38. [[Next]] 버튼을 클릭합니다.

### 3.2 네트워크 설정

39. **VPC**에서 **CloudArchitect-Lab-VPC**를 선택합니다.

40. **Availability Zones and subnets**에서 2개의 Public 서브넷을 모두 선택합니다.

41. [[Next]] 버튼을 클릭합니다.

### 3.3 로드 밸런싱 설정

42. **Load balancing**에서 **Attach to a new load balancer**를 선택합니다.

43. **Load balancer type**에서 **Application Load Balancer**를 선택합니다.

44. **Load balancer name**에 `CloudArchitect-Lab-ALB`를 입력합니다.

45. **Load balancer scheme**에서 **Internet-facing**를 선택합니다.

46. **Listeners and routing**에서 **Create a target group**를 선택합니다.

47. **New target group name**에 `CloudArchitect-Lab-TG`를 입력합니다.

48. [[Next]] 버튼을 클릭합니다.

> [!NOTE]
> Target Group의 헬스 체크는 기본적으로 HTTP GET 요청을 "/" 경로로 보내 인스턴스 상태를 확인합니다. 응답 코드 200이면 정상으로 판단합니다.

### 3.4 그룹 크기 및 스케일링 정책

49. **Group size**를 다음과 같이 설정합니다:
- **Desired capacity**: `2`
- **Min desired capacity**: `2`
- **Max desired capacity**: `4`

> [!NOTE]
> AWS UI가 업데이트되어 "Minimum capacity"가 "Min desired capacity"로, "Maximum capacity"가 "Max desired capacity"로 변경되었습니다.

50. **Scaling policies**에서 **Target tracking scaling policy**를 선택합니다.

51. **Metric type**에서 **Average CPU utilization**를 선택합니다.

52. **Target value**에 `70`를 입력합니다.

53. [[Next]] 버튼을 클릭합니다.

### 3.5 알림 설정

54. **Add notifications** 단계에서 [[Next]] 버튼을 클릭합니다.

### 3.6 태그 설정

55. **Add tags** 단계에서 [[Add tag]] 버튼을 클릭합니다.

56. 첫 번째 태그를 다음과 같이 입력합니다:
- **Key**: `Name`
- **Value**: `CloudArchitect-Lab-ASG`
- **Tag new instances**: 체크 ✅

57. [[Add tag]] 버튼을 다시 클릭하고 두 번째 태그를 추가합니다:
- **Key**: `StudentId`
- **Value**: `[본인 학번]` (예: 20241234)
- **Tag new instances**: 체크 ✅

> [!TIP]
> "Tag new instances"를 체크하면 Auto Scaling Group이 생성하는 EC2 인스턴스에도 이 태그가 자동으로 적용됩니다. EC2 콘솔에서 인스턴스 목록을 볼 때 어떤 ASG에서 생성되었는지, 누구의 리소스인지 쉽게 확인할 수 있습니다.

58. [[Next]] 버튼을 클릭합니다.

### 3.7 Auto Scaling Group 생성 완료

59. **Review** 페이지에서 설정을 검토합니다:
- Step 1: Launch template 확인
- Step 2: VPC 및 서브넷 확인
- Step 3: Load balancer 설정 확인
- Step 4: Group size 및 Scaling policies 확인
- Step 6: Tags 확인

60. [[Create Auto Scaling group]] 버튼을 클릭합니다.

> [!NOTE]
> Auto Scaling Group이 생성되면 Desired capacity(2개)만큼 인스턴스가 자동으로 시작됩니다. 인스턴스가 시작되고 헬스 체크를 통과하기까지 약 5-10분이 소요됩니다.

✅ **태스크 완료**: ALB와 Target Tracking 정책이 연결된 Auto Scaling Group이 생성되었습니다.


## 태스크 4: Amazon EC2 Auto Scaling 동작 확인

### 4.1 인스턴스 상태 확인

61. EC2 콘솔에서 왼쪽 메뉴의 **Auto Scaling Groups**를 선택합니다.

62. **CloudArchitect-Lab-ASG**를 선택합니다.

63. **Instance management** 탭을 선택합니다.

64. 인스턴스 2개가 "InService" 상태인지 확인합니다.

> [!TIP]
> 인스턴스 상태가 "Pending"이면 아직 시작 중입니다. "InService"로 변경될 때까지 기다립니다. 상태가 변경되지 않으면 페이지를 새로고침합니다.

### 4.2 Application Load Balancer 접속 테스트

65. EC2 콘솔에서 왼쪽 메뉴의 **Load Balancers**를 선택합니다.

66. **CloudArchitect-Lab-ALB**를 선택합니다.

67. **State**가 "Active"인지 확인합니다.

68. **DNS name**을 복사합니다 (예: **CloudArchitect-Lab-ALB-123456789.ap-northeast-2.elb.amazonaws.com**).

69. 새 브라우저 탭을 열고 `http://[복사한 DNS name]`으로 접속합니다.

70. "Lab06: Auto Scaling Web Server" 페이지가 표시되는지 확인합니다.

71. 페이지를 여러 번 새로고침(F5)하여 **인스턴스 ID**와 **가용 영역**이 변경되는지 확인합니다.

> [!SUCCESS] 로드 밸런싱 확인:
> 새로고침할 때마다 다른 인스턴스 ID가 표시되면 ALB가 2개의 인스턴스에 트래픽을 균등하게 분산하고 있는 것입니다.

### 4.3 Target Group 헬스 체크 확인

72. EC2 콘솔에서 왼쪽 메뉴의 **Target Groups**를 선택합니다.

73. **CloudArchitect-Lab-TG**를 선택합니다.

74. **Targets** 탭을 선택합니다.

75. 등록된 인스턴스들의 **Health status**가 "healthy"인지 확인합니다.

> [!TROUBLESHOOTING]
> 인스턴스 상태가 "unhealthy"인 경우:
> - User Data 스크립트 실행이 완료되지 않았을 수 있습니다 (5분 더 기다립니다)
> - 보안 그룹에 HTTP(80) 인바운드 규칙이 있는지 확인합니다
> - 인스턴스의 **Status check**가 `2/2 checks passed`인지 확인합니다

### 4.4 Auto Scaling 자동 복구 테스트

76. EC2 콘솔에서 왼쪽 메뉴의 **Instances**를 선택합니다.

77. Auto Scaling Group에서 생성된 인스턴스 중 하나를 선택합니다 (이름에 CloudArchitect-Lab-ASG가 포함된 인스턴스).

78. **Instance state** > **Terminate instance**를 선택합니다.

79. 확인 창에서 [[Terminate]] 버튼을 클릭합니다.

80. 왼쪽 메뉴에서 **Auto Scaling Groups**를 선택합니다.

81. **CloudArchitect-Lab-ASG**를 선택한 후 **Activity** 탭을 확인합니다.

82. 종료된 인스턴스를 대체할 새 인스턴스가 자동으로 시작되는 Activity 로그를 확인합니다.

> [!SUCCESS] Auto Scaling 자동 복구 확인:
> 인스턴스가 종료되면 Auto Scaling Group이 Desired capacity(2개)를 유지하기 위해 자동으로 새 인스턴스를 시작합니다. Activity 탭에서 "Launching a new EC2 instance" 메시지를 확인할 수 있습니다.

✅ **태스크 완료**: ALB 로드 밸런싱, 헬스 체크, Auto Scaling 자동 복구를 확인했습니다.


## 태스크 5: 실습 완료 후 리소스 정리

> [!WARNING]
> 다음 순서대로 리소스를 삭제합니다. 의존성이 있으므로 순서를 반드시 지킵니다.

### 5.1 Auto Scaling Group 삭제

83. EC2 콘솔에서 왼쪽 메뉴의 **Auto Scaling Groups**를 선택합니다.

84. **CloudArchitect-Lab-ASG**를 선택합니다.

85. **Actions** > **Delete**를 선택합니다.

86. 확인 텍스트를 입력하고 삭제합니다.

> [!NOTE]
> Auto Scaling Group 삭제 시 연결된 모든 EC2 인스턴스가 자동으로 종료됩니다. 인스턴스가 완전히 종료될 때까지 약 2-3분 기다립니다.

### 5.2 Load Balancer 및 Target Group 삭제

87. 왼쪽 메뉴에서 **Load Balancers**를 선택합니다.

88. **CloudArchitect-Lab-ALB**를 선택합니다.

89. **Actions** > **Delete load balancer**를 선택합니다.

90. 확인 텍스트를 입력하고 삭제합니다.

91. 왼쪽 메뉴에서 **Target Groups**를 선택합니다.

92. **CloudArchitect-Lab-TG**를 선택합니다.

93. **Actions** > **Delete**를 선택합니다.

### 5.3 Launch Template 삭제

94. 왼쪽 메뉴에서 **Launch Templates**를 선택합니다.

95. **CloudArchitect-Lab-WebServer-Template**를 선택합니다.

96. **Actions** > **Delete template**를 선택합니다.

97. 확인 텍스트를 입력하고 삭제합니다.

### 5.4 Cleanup 스크립트 실행

98. CloudShell에서 cleanup 스크립트를 실행하여 사전 구축 리소스를 정리합니다:

```bash
chmod +x cleanup-4-3.sh
./cleanup-4-3.sh
```

> [!WARNING]
> ASG → ALB → Target Group → Launch Template → Cleanup 스크립트 순서로 삭제합니다. ASG가 남아있으면 인스턴스가 계속 재생성됩니다.

✅ **실습 종료**: 모든 리소스가 정리되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-4-3.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - Auto Scaling Group (`CloudArchitect-Lab-ASG`)
   - Application Load Balancer (`CloudArchitect-Lab-ALB`)
   - Target Group (`CloudArchitect-Lab-TG`)
   - Launch Template (`CloudArchitect-Lab-WebServer-Template`)
   - EC2 인스턴스, Security Group
   - VPC 및 관련 리소스 (`CloudArchitect-Lab-VPC`)

> [!NOTE]
> 정리 스크립트는 이 실습에서 생성한 리소스만 삭제합니다. 다른 리소스에는 영향을 주지 않습니다.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> 삭제 순서가 중요합니다. ASG가 남아있으면 인스턴스가 계속 재생성되므로 반드시 ASG를 먼저 삭제합니다.

#### 태스크 1: Auto Scaling Group 삭제

1. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

2. 왼쪽 메뉴에서 **Auto Scaling Groups**를 선택합니다.

3. **CloudArchitect-Lab-ASG**를 선택하고 **Delete**를 클릭합니다.

4. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

> [!NOTE]
> Auto Scaling Group 삭제 시 연결된 모든 EC2 인스턴스가 자동으로 종료됩니다. 인스턴스가 완전히 종료될 때까지 약 2-3분 기다립니다.

#### 태스크 2: Application Load Balancer 및 Target Group 삭제

5. 왼쪽 메뉴에서 **Load Balancers**를 선택합니다.

6. **CloudArchitect-Lab-ALB**를 선택하고 **Actions** > **Delete load balancer**를 선택합니다.

7. 확인 필드에 `confirm`을 입력하고 [[Delete]]를 클릭합니다.

8. 왼쪽 메뉴에서 **Target Groups**를 선택합니다.

9. **CloudArchitect-Lab-TG**를 선택하고 **Actions** > **Delete**를 선택합니다.

10. 확인 대화 상자에서 [[Yes, delete]]를 클릭합니다.

#### 태스크 3: Launch Template 삭제

11. 왼쪽 메뉴에서 **Launch Templates**를 선택합니다.

12. **CloudArchitect-Lab-WebServer-Template**를 선택하고 **Actions** > **Delete template**를 선택합니다.

13. 확인 필드에 `Delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: Security Group 삭제

14. 왼쪽 메뉴의 **Network & Security** 섹션에서 **Security Groups**를 선택합니다.

15. **CloudArchitect-Lab-WebServer-SG**를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

16. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 5: Amazon VPC 삭제

17. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

18. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

19. **CloudArchitect-Lab-VPC**를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

20. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

21. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

22. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

23. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `StudentId`를 선택하고, Tag value에 본인 학번을 입력합니다.

> [!TIP]
> StudentId 태그로 검색하면 본인이 생성한 리소스만 정확히 확인할 수 있습니다. Name 태그로 검색하려면 Tag key를 `Name`, Tag value를 `CloudArchitect-Lab`로 입력합니다.

24. [[Search resources]]를 클릭합니다.

25. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

26. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

📋
Launch Template
인스턴스 구성을 템플릿화하여 일관된 환경에서 자동으로 인스턴스를 생성합니다.

🔄
Auto Scaling Group
CPU 사용률 기반으로 자동으로 인스턴스를 추가/제거하여 성능과 비용을 최적화합니다.

⚖️
Application Load Balancer
여러 인스턴스에 HTTP 트래픽을 분산하고 헬스 체크를 통해 고가용성을 보장합니다.

🌐
Multi-AZ 배포
여러 가용 영역에 인스턴스를 분산 배치하여 단일 장애 지점을 제거합니다.

📊
Target Tracking 정책
CPU 사용률 70% 기준으로 자동 스케일링하여 성능과 비용의 균형을 맞춥니다.
