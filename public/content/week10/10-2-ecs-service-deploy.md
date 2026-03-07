---
title: 'Amazon ECS 서비스 배포'
week: 10
session: 2
awsServices:
  - Amazon ECS
  - Amazon ECR
learningObjectives:
  - Amazon ECR의 주요 기능과 컨테이너 이미지 관리 방법을 파악할 수 있습니다.
  - Amazon ECS의 핵심 개념(태스크 정의, 서비스, 클러스터)을 이해할 수 있습니다.
  - Amazon ECS를 활용하여 컨테이너화된 애플리케이션을 배포하고 관리할 수 있습니다.
---

> [!DOWNLOAD]
> [week10-2-ecs-service-deploy.zip](/files/week10/week10-2-ecs-service-deploy.zip)
>
> - `setup-6-2-student.sh` - 사전 환경 구축 스크립트 (VPC, Public/Private Subnets, NAT Gateway, Security Groups, Amazon ECR 리포지토리, Docker 이미지 등 생성)
> - `cleanup-6-2-student.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-6-2-student.sh 실행)

> [!NOTE]
> 이 실습에서는 Amazon ECS를 사용하여 컨테이너 기반 애플리케이션을 배포하고 관리합니다. AWS Fargate를 이용한 서버리스 컨테이너 실행과 Application Load Balancer를 통한 고가용성 구성을 구현합니다.

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - ECS Fargate 아키텍처
>
> <img src="/images/week10/10-2-architecture-diagram.svg" alt="ECS Fargate 아키텍처 - VPC 내 2개 AZ에 ALB, ECS Fargate 태스크, NAT Gateway, ECR에서 컨테이너 이미지를 Pull하는 구조" class="guide-img-lg" />

> [!CONCEPT] Amazon ECS란?
>
> Amazon ECS(Elastic Container Service)는 Docker 컨테이너를 **대규모로 실행하고 관리**하는 완전 관리형 컨테이너 오케스트레이션 서비스입니다.
>
> - **클러스터(Cluster)**: 태스크와 서비스를 실행하는 논리적 그룹입니다
> - **태스크 정의(Task Definition)**: 컨테이너 이미지, CPU/메모리, 포트 등을 정의한 설계도입니다
> - **서비스(Service)**: 지정된 수의 태스크를 유지하고 로드 밸런서와 연동합니다
> - **AWS Fargate**: 서버를 관리하지 않고 컨테이너를 실행하는 서버리스 컴퓨팅 엔진입니다

## 태스크 0: 사전 환경 구축

1. 위 DOWNLOAD 섹션에서 `week10-2-ecs-service-deploy.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > `Upload file`을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week10-2-ecs-service-deploy.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-6-2-student.sh
./setup-6-2-student.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 5-10분이 소요됩니다. NAT Gateway 생성 및 Docker 이미지 빌드/푸시까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| VPC | CloudArchitect-Lab-VPC |
| Public Subnet 1/2 | CloudArchitect-Lab-Public-Subnet-1/2 |
| Private Subnet 1/2 | CloudArchitect-Lab-Private-Subnet-1/2 |
| NAT Gateway | CloudArchitect-Lab-NAT-GW |
| ALB Security Group | CloudArchitect-Lab-ALB-SG |
| ECS Security Group | CloudArchitect-Lab-ECS-SG |
| ECR 리포지토리 | cloudarchitect-lab-webapp |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 Amazon VPC 인프라 확인

8. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

9. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

10. `CloudArchitect-Lab-VPC`가 생성되어 있는지 확인합니다.

11. 왼쪽 메뉴에서 **Subnets**를 선택하여 4개의 서브넷(Public 2개, Private 2개)을 확인합니다.

### 1.2 Amazon ECR 리포지토리 및 이미지 URI 확인

12. 상단 검색창에서 `ECR`을 검색하고 **ECR**을 선택합니다.

13. ECR 콘솔의 왼쪽 메뉴에서 **Private registry** 섹션 아래의 **Repositories**를 선택합니다.

14. `cloudarchitect-lab-webapp` 리포지토리를 선택합니다.

15. `latest` 태그가 있는 Docker 이미지를 확인합니다.

16. **URI** 열에서 이미지 URI를 복사하여 메모장에 저장합니다.

> [!IMPORTANT]
> 이미지 URI는 태스크 3에서 태스크 정의를 생성할 때 사용합니다. 형식: `[계정ID].dkr.ecr.ap-northeast-2.amazonaws.com/cloudarchitect-lab-webapp:latest`

✅ **태스크 완료**: VPC 인프라와 ECR 이미지가 정상적으로 구축되어 있습니다.


## 태스크 2: Amazon ECS 클러스터 생성

> [!CONCEPT] Amazon ECS 클러스터와 AWS Fargate
>
> ECS 클러스터는 태스크와 서비스를 실행하는 논리적 그룹입니다. AWS Fargate를 사용하면 EC2 인스턴스를 직접 관리하지 않고 컨테이너를 실행할 수 있습니다. Fargate가 컨테이너에 필요한 컴퓨팅 리소스를 자동으로 프로비저닝합니다.

### 2.1 Amazon ECS 클러스터 생성

17. 상단 검색창에서 `ECS`를 검색하고 **ECS**를 선택합니다.

18. 왼쪽 메뉴에서 **Clusters**를 선택합니다.

19. [[Create cluster]] 버튼을 클릭합니다.

20. **Cluster name**에 `CloudArchitect-Lab-Cluster`를 입력합니다.

21. **Infrastructure** 섹션에서 `AWS Fargate (serverless)`가 선택되어 있는지 확인합니다.

22. [[Create]] 버튼을 클릭합니다.

23. 클러스터 상태가 "Active"로 변경되는지 확인합니다.

✅ **태스크 완료**: AWS Fargate 기반 ECS 클러스터가 생성되었습니다.


## 태스크 3: AWS Fargate 태스크 정의 생성

> [!CONCEPT] 태스크 정의(Task Definition)
>
> 태스크 정의는 컨테이너를 실행하기 위한 **설계도**입니다. 어떤 이미지를 사용할지, CPU/메모리를 얼마나 할당할지, 어떤 포트를 열지 등을 정의합니다. 하나의 태스크 정의에 여러 컨테이너를 포함할 수 있으며, 리비전(버전) 관리가 가능합니다.

### 3.1 태스크 정의 생성

24. ECS 콘솔에서 왼쪽 메뉴의 **Task definitions**를 선택합니다.

25. [[Create new task definition]] 버튼을 클릭합니다.

26. **Task definition family**에 `cloudarchitect-lab-task`를 입력합니다.

27. **Launch type**에서 `AWS Fargate`를 선택합니다.

28. **Operating system/Architecture**에서 `Linux/X86_64`를 선택합니다.

29. **CPU**를 `0.25 vCPU`로 설정합니다.

30. **Memory**를 `0.5 GB`로 설정합니다.

31. **Task roles** 섹션을 확장합니다.

32. **Task execution role**에서 `Create new role`을 선택합니다.

> [!NOTE]
> Task execution role은 ECS가 ECR에서 이미지를 가져오고 CloudWatch에 로그를 전송하는 데 필요한 권한입니다. `Create new role`을 선택하면 `AmazonECSTaskExecutionRolePolicy`가 자동으로 부여됩니다.

### 3.2 컨테이너 구성

33. **Container details** 섹션에서 **Name**에 `cloudarchitect-lab-app`을 입력합니다.

34. **Image URI**에 태스크 1에서 복사한 ECR 이미지 URI를 붙여넣습니다.

35. **Port mappings** 섹션에서 **Container port**를 `3000`으로 설정합니다.

36. **Protocol**이 `TCP`로 설정되어 있는지 확인합니다.

37. [[Create]] 버튼을 클릭합니다.

✅ **태스크 완료**: ECR 이미지를 사용하는 Fargate 태스크 정의가 생성되었습니다.


## 태스크 4: Application Load Balancer 구성

### 4.1 Application Load Balancer 생성

38. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

39. EC2 콘솔의 왼쪽 메뉴에서 **Load Balancing** 섹션 아래의 **Load Balancers**를 선택합니다.

40. [[Create load balancer]] 버튼을 클릭합니다.

41. **Application Load Balancer** 섹션에서 [[Create]] 버튼을 클릭합니다.

42. **Load balancer name**에 `CloudArchitect-Lab-ALB`를 입력합니다.

43. **Scheme**에서 `Internet-facing`을 선택합니다.

44. **IP address type**에서 `IPv4`를 선택합니다.

### 4.2 네트워크 및 보안 그룹 설정

45. **Network mapping** 섹션에서 `CloudArchitect-Lab-VPC`를 선택합니다.

46. **Availability Zones and subnets**에서 **Public 서브넷** 2개를 선택합니다 (이름에 "Public"이 포함된 서브넷).

47. **Security groups** 섹션에서 기본 보안 그룹을 제거하고 `CloudArchitect-Lab-ALB-SG`를 선택합니다.

### 4.3 Target Group 생성

48. **Listeners and routing** 섹션에서 **Protocol**이 `HTTP`, **Port**가 `80`인지 확인합니다.

49. **Default action**에서 `Create target group` 링크를 선택합니다.

50. 새 탭에서 **Target type**으로 `IP addresses`를 선택합니다.

51. **Target group name**에 `CloudArchitect-Lab-TG`를 입력합니다.

52. **Protocol**을 `HTTP`, **Port**를 `3000`으로 설정합니다.

53. **VPC**에서 `CloudArchitect-Lab-VPC`를 선택합니다.

54. **Health check path**를 `/health`로 설정합니다.

55. [[Next]] 버튼을 클릭합니다.

56. 타겟 등록 단계에서 아무것도 추가하지 않고 [[Create target group]] 버튼을 클릭합니다.

> [!NOTE]
> Target Group의 타겟은 ECS 서비스가 생성될 때 자동으로 등록됩니다. 여기서는 빈 Target Group만 생성합니다.

57. ALB 생성 탭으로 이동하여 **Default action** 드롭다운 옆의 새로고침 아이콘을 선택합니다.

58. `CloudArchitect-Lab-TG`를 선택합니다.

59. [[Create load balancer]] 버튼을 클릭합니다.

60. ALB 상태가 "Provisioning"에서 "Active"로 변경될 때까지 기다립니다.

✅ **태스크 완료**: Application Load Balancer와 Target Group이 생성되었습니다.


## 태스크 5: Amazon ECS 서비스 생성 및 배포

> [!CONCEPT] Amazon ECS 서비스와 프라이빗 서브넷
>
> ECS 서비스는 지정된 수의 태스크를 항상 유지합니다. 태스크가 실패하면 자동으로 새 태스크를 시작합니다. 컨테이너는 **프라이빗 서브넷**에 배치하여 인터넷에서 직접 접근할 수 없게 하고, ALB를 통해서만 트래픽을 받습니다. 프라이빗 서브넷의 컨테이너가 ECR에서 이미지를 가져오려면 **NAT Gateway**가 필요합니다.

### 5.1 Amazon ECS 서비스 생성

61. ECS 콘솔에서 `CloudArchitect-Lab-Cluster`를 선택합니다.

62. **Services** 탭에서 [[Create]] 버튼을 클릭합니다.

63. **Compute options**에서 `Launch type`을 선택하고 `FARGATE`를 설정합니다.

64. **Task definition** 섹션에서 **Family**로 `cloudarchitect-lab-task`를 선택합니다.

65. **Service name**에 `cloudarchitect-lab-service`를 입력합니다.

66. **Desired tasks**를 `2`로 설정합니다.

### 5.2 네트워킹 설정

67. **Networking** 섹션을 확장합니다.

68. **VPC**에서 `CloudArchitect-Lab-VPC`를 선택합니다.

69. **Subnets**에서 **Private 서브넷** 2개를 선택합니다 (이름에 "Private"이 포함된 서브넷).

> [!TIP]
> ALB는 퍼블릭 서브넷에, ECS 태스크는 프라이빗 서브넷에 배치합니다. 이렇게 하면 컨테이너가 외부에 직접 노출되지 않아 보안이 강화됩니다.

70. **Security group**에서 `Use an existing security group`을 선택한 후 `CloudArchitect-Lab-ECS-SG`를 선택합니다.

71. **Public IP** 토글을 `Turned off`로 설정합니다.

### 5.3 로드 밸런서 연동

72. **Load balancing** 섹션에서 `Application Load Balancer`를 선택합니다.

73. `Use an existing load balancer`를 선택합니다.

74. **Load balancer**에서 `CloudArchitect-Lab-ALB`를 선택합니다.

75. **Listener**에서 `Use an existing listener`를 선택하고 `80:HTTP`를 선택합니다.

76. **Target group**에서 `Use an existing target group`을 선택하고 `CloudArchitect-Lab-TG`를 선택합니다.

77. [[Create]] 버튼을 클릭합니다.

> [!NOTE]
> 서비스가 생성되면 Desired tasks(2개)만큼 태스크가 자동으로 시작됩니다. 태스크가 시작되고 헬스 체크를 통과하기까지 약 2-3분이 소요됩니다.

✅ **태스크 완료**: ALB와 연동된 고가용성 ECS 서비스가 생성되었습니다.


## 태스크 6: 서비스 테스트 및 모니터링

### 6.1 태스크 상태 확인

78. 서비스 상세 페이지에서 **Tasks** 탭을 선택합니다.

79. 태스크 2개의 **Last status**가 "RUNNING"으로 변경될 때까지 기다립니다.

> [!TROUBLESHOOTING]
> 태스크 상태가 "STOPPED"인 경우:
> - 태스크를 선택하여 **Stopped reason**을 확인합니다
> - "CannotPullContainerError": ECR 이미지 URI가 올바른지, NAT Gateway가 정상인지 확인합니다
> - "ResourceInitializationError": 보안 그룹에서 아웃바운드 트래픽이 허용되어 있는지 확인합니다

### 6.2 Application Load Balancer 접속 테스트

80. EC2 콘솔에서 왼쪽 메뉴의 **Load Balancers**를 선택합니다.

81. `CloudArchitect-Lab-ALB`를 선택합니다.

82. **State**가 "Active"인지 확인합니다.

83. **DNS name**을 복사합니다.

84. 새 브라우저 탭을 열고 `http://[복사한 DNS name]`으로 접속합니다.

85. Docker 애플리케이션 페이지가 정상적으로 표시되는지 확인합니다.

86. 페이지를 여러 번 새로고침(F5)하여 로드 밸런싱이 작동하는지 확인합니다.

> [!TIP]
> 새로고침할 때마다 페이지 하단의 Container ID나 호스트명이 변경되면 ALB가 2개의 태스크에 트래픽을 균등하게 분산하고 있는 것입니다.

### 6.3 Target Group 헬스 체크 확인

87. EC2 콘솔에서 왼쪽 메뉴의 **Target Groups**를 선택합니다.

88. `CloudArchitect-Lab-TG`를 선택합니다.

89. **Targets** 탭에서 등록된 타겟들의 **Health status**가 "healthy"인지 확인합니다.

✅ **태스크 완료**: ECS 서비스가 정상적으로 실행되고 ALB를 통해 접근할 수 있습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요. 특히 **NAT Gateway**와 **ALB**는 시간당 요금이 발생합니다.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-6-2-student.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - ECS 서비스 (`cloudarchitect-lab-service`)
   - ECS 클러스터 (`CloudArchitect-Lab-Cluster`)
   - Task Definition (`cloudarchitect-lab-task`)
   - ECR 리포지토리 (`cloudarchitect-lab-webapp`)
   - ALB, Target Group, NAT Gateway
   - Security Groups, VPC 및 관련 리소스

> [!NOTE]
> 정리 스크립트는 이 실습에서 생성한 리소스만 삭제합니다. 다른 리소스에는 영향을 주지 않습니다.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> 삭제 순서가 중요합니다. ECS 서비스 → ALB → NAT Gateway → Elastic IP → VPC 순서로 삭제합니다.

#### 태스크 1: Amazon ECS 서비스 및 클러스터 삭제

1. 상단 검색창에서 `ECS`를 검색하고 **ECS**를 선택합니다.

2. **Clusters**에서 `CloudArchitect-Lab-Cluster`를 선택합니다.

3. **Services** 탭에서 `cloudarchitect-lab-service`를 선택하고 **Delete service**를 클릭합니다.

4. **Force delete service** 체크박스를 선택하고 확인 필드에 `delete`를 입력한 후 [[Delete]]를 클릭합니다.

> [!NOTE]
> 서비스 삭제 시 실행 중인 태스크가 자동으로 종료됩니다. 약 1-2분 기다립니다.

5. 서비스 삭제 후 **Delete cluster**를 클릭합니다.

6. 확인 필드에 `delete CloudArchitect-Lab-Cluster`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 2: Application Load Balancer 및 Target Group 삭제

7. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

8. 왼쪽 메뉴에서 **Load Balancers**를 선택합니다.

9. `CloudArchitect-Lab-ALB`를 선택하고 **Actions** > **Delete load balancer**를 선택합니다.

10. 확인 필드에 `confirm`을 입력하고 [[Delete]]를 클릭합니다.

11. 왼쪽 메뉴에서 **Target Groups**를 선택합니다.

12. `CloudArchitect-Lab-TG`를 선택하고 **Actions** > **Delete**를 선택합니다.

#### 태스크 3: Amazon ECR 리포지토리 삭제

13. 상단 검색창에서 `ECR`을 검색하고 **ECR**을 선택합니다.

14. `cloudarchitect-lab-webapp` 리포지토리를 선택하고 **Delete**를 클릭합니다.

15. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: NAT Gateway 및 Elastic IP 삭제

16. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

17. 왼쪽 메뉴에서 **NAT gateways**를 선택합니다.

18. `CloudArchitect-Lab-NAT-GW`를 선택하고 **Actions** > **Delete NAT gateway**를 선택합니다.

19. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

20. NAT Gateway 삭제 완료 후, 왼쪽 메뉴에서 **Elastic IPs**를 선택합니다.

21. 사용하지 않는 Elastic IP를 선택하고 **Actions** > **Release Elastic IP addresses**를 선택합니다.

#### 태스크 5: Security Group 및 Amazon VPC 삭제

22. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

23. 왼쪽 메뉴의 **Security Groups**에서 `CloudArchitect-Lab-ECS-SG`와 `CloudArchitect-Lab-ALB-SG`를 각각 삭제합니다.

24. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

25. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

26. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

27. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

28. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

29. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

30. [[Search resources]]를 클릭합니다.

31. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🚀
Amazon ECS 클러스터
AWS Fargate를 사용하여 서버 관리 없이 컨테이너를 실행하는 클러스터를 생성했습니다

📋
태스크 정의
ECR 이미지, CPU/메모리, 포트 매핑을 정의한 컨테이너 실행 설계도를 작성했습니다

⚖️
Application Load Balancer
ALB와 Target Group을 생성하여 여러 태스크에 트래픽을 분산했습니다

🔒
프라이빗 서브넷 배포
컨테이너를 프라이빗 서브넷에 배치하고 ALB를 통해서만 접근하도록 보안을 강화했습니다

🔄
ECS 서비스
지정된 수의 태스크를 자동으로 유지하고 장애 시 자동 복구하는 서비스를 배포했습니다
