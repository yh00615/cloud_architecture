---
title: 'CloudWatch 대시보드 구성'
week: 7
session: 1
awsServices:
  - Amazon CloudWatch
learningObjectives:
  - 클라우드 모니터링의 개요와 전략을 이해할 수 있습니다.
  - Amazon CloudWatch의 핵심 개념(네임스페이스, 지표, 차원)을 설명할 수 있습니다.
  - Amazon CloudWatch 지표를 수집하고 대시보드를 구성할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **CloudWatch 대시보드**를 생성하여 **EC2 인스턴스**를 모니터링합니다. 먼저 EC2 인스턴스를 생성하고 **스트레스 테스트**로 **CPU 부하**를 발생시킵니다. 대시보드에 **선 그래프, 숫자, 게이지 위젯**을 추가하여 **CPU, 네트워크, 디스크 지표**를 시각화합니다. **알람**을 생성하여 **CPU 사용률**이 임계값을 초과하면 **SNS**로 이메일 알림을 받도록 설정합니다.

> [!DOWNLOAD]
> [week7-1-cloudwatch-dashboard.zip](/files/week7/week7-1-cloudwatch-dashboard.zip)
>
> **포함 파일:**
> 
> **setup-7-1.sh** - 사전 환경 구축 스크립트
> - **목적**: CloudWatch 모니터링 실습을 위한 EC2 인스턴스 자동 구축
> - **생성 리소스**:
>   - VPC 네트워크 (VPC, Subnet, Internet Gateway, Route Table, Security Group)
>   - IAM 역할 (CloudWatch 지표 전송 권한)
>   - EC2 인스턴스 (t3.micro, Amazon Linux 2023)
> - **실행 시간**: 약 3-5분
> - **활용**: 태스크 1-5에서 생성된 인스턴스의 지표를 모니터링하고 대시보드를 구성합니다
>
> **cleanup-7-1.sh** - 리소스 정리 스크립트
> - **목적**: 실습에서 생성한 모든 리소스를 안전한 순서로 자동 삭제
> - **삭제 리소스**: EC2 인스턴스, IAM 역할, VPC 및 네트워크 리소스
> - **실행 시간**: 약 2-3분
>
> **사용 태스크:**
> - 태스크 0: 사전 환경 구축 (setup-7-1.sh 실행)
> - 리소스 정리: 실습 완료 후 cleanup-7-1.sh 실행

> [!CONCEPT] Amazon CloudWatch란?
>
> Amazon CloudWatch는 AWS 리소스와 애플리케이션을 **실시간으로 모니터링**하는 서비스입니다.
>
> - **지표(Metrics)**: CPU 사용률, 네트워크 트래픽 등 리소스의 성능 데이터입니다
> - **경보(Alarms)**: 지표가 임계값을 초과하면 자동으로 알림을 보내거나 작업을 수행합니다
> - **대시보드(Dashboards)**: 여러 지표를 한 화면에서 시각적으로 모니터링합니다
> - **네임스페이스(Namespace)**: 지표를 서비스별로 그룹화하는 컨테이너입니다 (예: `AWS/EC2`, `AWS/RDS`)
>
> 이 실습에서는 EC2 인스턴스의 CPU 지표를 모니터링하고, 경보와 대시보드를 구성합니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

### 0.1 사전 환경 구축의 목적

이 실습에서는 **CloudWatch 대시보드**와 **경보**를 통해 EC2 인스턴스를 모니터링하는 방법을 학습합니다. 이를 위해 다음과 같은 환경이 필요합니다:

**구축되는 인프라:**
- **VPC 네트워크**: 격리된 네트워크 환경에서 EC2 인스턴스를 실행합니다
- **EC2 인스턴스 (모니터링 서버)**: CPU 부하를 생성하여 CloudWatch 지표를 발생시킵니다
- **IAM 역할**: CloudWatch에 지표를 전송할 수 있는 권한을 제공합니다
- **CPU 부하 생성 스크립트**: 실습을 위해 의도적으로 CPU 사용률을 높여 경보를 테스트합니다

**실습에서의 활용:**
- **태스크 1**: 생성된 EC2 인스턴스를 확인하고 CloudWatch 기본 지표를 관찰합니다
- **태스크 2**: CPU 사용률 지표를 확인하고 시계열 그래프를 분석합니다
- **태스크 3**: CPU 사용률이 임계값을 초과하면 알림을 보내는 경보를 생성합니다
- **태스크 4**: 여러 지표를 한눈에 볼 수 있는 대시보드를 구성합니다
- **태스크 5**: CPU 부하를 생성하여 경보가 실제로 작동하는지 테스트합니다

> [!TIP]
> 사전 환경 구축 스크립트는 실습에 필요한 모든 인프라를 자동으로 생성하므로, 여러분은 CloudWatch의 핵심 모니터링 기능 학습에만 집중할 수 있습니다.

### 0.2 환경 구축 실행

1. 위 DOWNLOAD 섹션에서 `week7-1-cloudwatch-dashboard.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week7-1-cloudwatch-dashboard.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-7-1.sh cleanup-7-1.sh
./setup-7-1.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 내용을 확인하고 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

### 0.3 생성된 리소스 확인

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 유형 | 리소스 이름 | 실습에서의 역할 |
|------------|------------|----------------|
| VPC | CloudArchitect-Lab-VPC | EC2 인스턴스를 위한 격리된 네트워크 환경 |
| Internet Gateway | CloudArchitect-Lab-IGW | 인터넷 연결을 위한 게이트웨이 |
| Public Subnet | CloudArchitect-Lab-Public-Subnet | EC2 인스턴스가 배치되는 서브넷 |
| Route Table | CloudArchitect-Lab-Public-RT | 인터넷 트래픽 라우팅 |
| Security Group | CloudArchitect-Lab-Web-SG | SSH(22) 트래픽 허용 |
| EC2 인스턴스 | CloudArchitect-Lab-MonitoringServer | CloudWatch 지표 생성 및 모니터링 대상 |
| IAM 역할 | CloudArchitect-Lab-CloudWatchRole | CloudWatch 지표 전송 권한 제공 |

8. 출력 메시지에서 EC2 인스턴스의 **Instance ID**와 **Public IP 주소**를 확인하고 메모합니다.

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week7-1-cloudwatch-dashboard.zip setup-7-1.sh cleanup-7-1.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 Amazon EC2 인스턴스 확인

9. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

10. 왼쪽 메뉴에서 **Instances**를 선택합니다.

11. `CloudArchitect-Lab-MonitoringServer` 인스턴스의 상태가 "Running"인지 확인합니다.

12. 인스턴스를 선택하고 **Instance ID**를 복사하여 메모장에 저장합니다.

> [!NOTE]
> Instance ID는 CloudWatch에서 해당 인스턴스의 지표를 검색할 때 사용합니다. `i-0abc1234def56789` 형태입니다.

13. 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

14. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속하여 웹 서버가 정상 작동하는지 확인합니다.

✅ **태스크 완료**: EC2 인스턴스와 웹 서버가 정상 작동하고 있습니다.


## 태스크 2: Amazon CloudWatch 지표 확인

> [!CONCEPT] Amazon CloudWatch 지표 구조
>
> CloudWatch 지표는 **네임스페이스 → 차원 → 지표** 계층 구조로 구성됩니다.
>
> - **네임스페이스**: `AWS/EC2`, `AWS/RDS` 등 서비스별 그룹입니다
> - **차원(Dimension)**: 인스턴스 ID 등 지표를 구분하는 기준입니다
> - **지표(Metric)**: CPUUtilization, NetworkIn 등 실제 측정값입니다
> - **기간(Period)**: 지표를 집계하는 시간 단위입니다 (1분, 5분 등)

### 2.1 Amazon EC2 지표 확인

15. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

16. 왼쪽 메뉴에서 **Metrics**를 선택하여 확장한 후 **All metrics**를 선택합니다.

17. **Browse** 탭에서 `EC2`를 선택합니다.

18. **Per-Instance Metrics**를 선택합니다.

19. 검색 필터에 태스크 1에서 복사한 **Instance ID**를 입력합니다.

20. 해당 인스턴스의 주요 지표를 확인합니다:
- **CPUUtilization**: CPU 사용률 (%)
- **NetworkIn / NetworkOut**: 네트워크 수신/송신 바이트
- **DiskReadOps / DiskWriteOps**: 디스크 읽기/쓰기 작업 수
- **StatusCheckFailed**: 상태 확인 실패 여부

> [!TIP]
> 지표 이름 옆의 체크박스를 선택하면 하단 그래프에 해당 지표가 표시됩니다. 여러 지표를 동시에 선택하여 비교할 수 있습니다.

✅ **태스크 완료**: CloudWatch에서 EC2 인스턴스의 지표를 확인했습니다.


## 태스크 3: Amazon SNS 토픽 생성 및 이메일 구독 설정

> [!CONCEPT] Amazon SNS(Simple Notification Service)란?
>
> Amazon SNS는 메시지를 여러 구독자에게 동시에 전달하는 **발행-구독(Pub/Sub)** 메시징 서비스입니다. CloudWatch 경보와 연동하면 임계값 초과 시 자동으로 이메일, SMS 등으로 알림을 보낼 수 있습니다.
>
> - **토픽(Topic)**: 메시지를 발행하는 채널입니다
> - **구독(Subscription)**: 토픽의 메시지를 수신하는 엔드포인트입니다 (이메일, SMS, Lambda 등)

### 3.1 Amazon SNS 토픽 생성

21. 상단 검색창에서 `SNS`를 검색하고 **Simple Notification Service**를 선택합니다.

22. 왼쪽 메뉴에서 **Topics**를 선택합니다.

23. [[Create topic]] 버튼을 클릭합니다.

24. **Type**에서 **Standard**를 선택합니다.

25. **Name**에 `CloudArchitect-Lab-Alerts`를 입력합니다.

26. **Tags** 섹션에서 [[Add new tag]] 버튼을 클릭하여 다음 태그를 추가합니다:
   - Key: `Name`, Value: `CloudArchitect-Lab-Alerts`
   - Key: `StudentId`, Value: `[본인 학번]` (예: 20241234)

27. [[Create topic]] 버튼을 클릭합니다.

### 3.2 이메일 구독 설정

28. 생성된 토픽 상세 페이지에서 [[Create subscription]] 버튼을 클릭합니다.

29. **Protocol**에서 **Email**을 선택합니다.

30. **Endpoint**에 개인 이메일 주소를 입력합니다.

31. [[Create subscription]] 버튼을 클릭합니다.

32. 이메일 수신함을 확인하고 **Confirm subscription** 링크를 선택합니다.

> [!IMPORTANT]
> 이메일 확인을 완료해야 경보 알림을 수신할 수 있습니다. 구독 상태가 "Confirmed"로 변경되었는지 SNS 콘솔에서 확인합니다. 이메일이 보이지 않으면 스팸 폴더를 확인합니다.

✅ **태스크 완료**: SNS 토픽이 생성되고 이메일 구독이 확인되었습니다.


## 태스크 4: Amazon CloudWatch 경보 생성

> [!CONCEPT] Amazon CloudWatch 경보(Alarm)
>
> CloudWatch 경보는 지표가 설정한 임계값을 초과하면 자동으로 작업을 수행합니다.
>
> - **OK**: 지표가 정상 범위 내에 있는 상태입니다
> - **ALARM**: 지표가 임계값을 초과한 상태입니다
> - **INSUFFICIENT_DATA**: 데이터가 부족하여 판단할 수 없는 상태입니다
>
> 경보가 ALARM 상태로 전환되면 SNS 토픽을 통해 이메일 알림을 보내도록 설정할 수 있습니다.

### 4.1 Amazon CloudWatch 경보 설정

33. CloudWatch 콘솔에서 왼쪽 메뉴의 **Alarms**를 선택합니다.

34. [[Create alarm]] 버튼을 클릭합니다.

35. [[Select metric]] 버튼을 클릭합니다.

36. **Browse** 탭에서 `EC2` > **Per-Instance Metrics**를 선택합니다.

37. 검색 필터에 태스크 1에서 복사한 **Instance ID**를 입력하고 `CPUUtilization`을 선택합니다.

38. [[Select metric]] 버튼을 클릭합니다.

### 4.2 경보 조건 설정

39. **Statistic**에서 **Average**를 선택합니다.

40. **Period**에서 **1 minute**를 선택합니다.

41. **Threshold type**에서 **Static**을 선택합니다.

42. **Whenever CPUUtilization is**에서 **Greater**를 선택합니다.

43. **than** 필드에 `40`을 입력합니다.

44. [[Next]] 버튼을 클릭합니다.

### 4.3 알림 설정

45. **Alarm state trigger**에서 **In alarm**을 선택합니다.

46. **Send a notification to...** 에서 **Select an existing SNS topic**을 선택하고 **CloudArchitect-Lab-Alerts**를 선택합니다.

47. [[Next]] 버튼을 클릭합니다.

48. **Alarm name**에 `CloudArchitect-Lab-HighCPU`를 입력합니다.

49. **Alarm description**에 `CPU usage exceeds 40%`를 입력합니다.

50. **Tags** 섹션에서 [[Add new tag]] 버튼을 클릭하여 다음 태그를 추가합니다:
   - Key: `Name`, Value: `CloudArchitect-Lab-HighCPU`
   - Key: `StudentId`, Value: `[본인 학번]` (예: 20241234)

51. [[Next]] 버튼을 클릭합니다.

52. 설정을 검토한 후 [[Create alarm]] 버튼을 클릭합니다.

53. 경보 상태가 "OK"인지 확인합니다.

✅ **태스크 완료**: CPU 사용률 40% 초과 시 이메일 알림을 보내는 경보가 생성되었습니다.


## 태스크 5: Amazon CloudWatch 대시보드 생성

### 5.1 대시보드 생성

54. 왼쪽 메뉴에서 **Dashboards**를 선택합니다.

55. [[Create dashboard]] 버튼을 클릭합니다.

56. **Dashboard name**에 `CloudArchitect-Lab-Dashboard`를 입력합니다.

57. [[Create dashboard]] 버튼을 클릭합니다.

### 5.2 위젯 추가

58. **Add widget** 대화상자에서 **Widget type**으로 **Line**을 선택합니다.

59. [[Next]] 버튼을 클릭합니다.

60. **Browse** 탭에서 `EC2` > **Per-Instance Metrics**를 선택합니다.

61. 검색 필터에 **Instance ID**를 입력하고 **CPUUtilization**, **NetworkIn**, **NetworkOut** 지표를 선택합니다.

62. [[Create widget]] 버튼을 클릭합니다.

63. [[Save]] 버튼을 클릭하여 대시보드를 저장합니다.

64. 대시보드 상단의 **Settings** 아이콘(⚙️)을 선택합니다.

65. **Tags** 탭에서 [[Manage tags]] 버튼을 클릭합니다.

66. [[Add new tag]] 버튼을 클릭하여 다음 태그를 추가합니다:
   - Key: `Name`, Value: `CloudArchitect-Lab-Dashboard`
   - Key: `StudentId`, Value: `[본인 학번]` (예: 20241234)

67. [[Save]] 버튼을 클릭합니다.

> [!TIP]
> 대시보드에 여러 위젯을 추가하여 CPU, 네트워크, 디스크 지표를 한 화면에서 모니터링할 수 있습니다. 위젯은 드래그하여 크기와 위치를 조정할 수 있습니다.

✅ **태스크 완료**: CloudWatch 대시보드가 생성되었습니다.


## 태스크 6: 스트레스 테스트 및 경보 확인

### 6.1 Amazon EC2 인스턴스 접속

68. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

69. 왼쪽 메뉴에서 **Instances**를 선택합니다.

70. `CloudArchitect-Lab-MonitoringServer` 인스턴스를 선택합니다.

71. [[Connect]] 버튼을 클릭합니다.

72. **EC2 Instance Connect** 탭에서 [[Connect]] 버튼을 클릭합니다.

### 6.2 CPU 스트레스 테스트 실행

73. 터미널에서 다음 명령어를 실행하여 CPU 부하를 생성합니다:

```bash
stress --cpu 1 --timeout 180
```

> [!NOTE]
> `stress` 명령어는 3분(180초) 동안 CPU 부하를 생성합니다. 사전 구축 스크립트에서 이미 설치되어 있습니다.

### 6.3 경보 상태 확인

74. Amazon CloudWatch 콘솔로 이동합니다. 왼쪽 메뉴에서 **Alarms**를 선택합니다.

75. `CloudArchitect-Lab-HighCPU` 경보의 상태가 "OK"에서 "In alarm"으로 변경될 때까지 기다립니다.

> [!NOTE]
> 경보 상태 변경에 약 2-3분이 소요됩니다. Period가 1분으로 설정되어 있으므로, 1분간의 평균 CPU 사용률이 40%를 초과하면 경보가 발생합니다.

76. 대시보드에서 CPU 사용률 그래프가 급격히 상승하는 것을 확인합니다.

77. 이메일 수신함에서 경보 알림 메일이 도착했는지 확인합니다.

> [!TROUBLESHOOTING]
> - 경보가 "INSUFFICIENT_DATA" 상태로 유지되면: EC2 인스턴스가 Running 상태인지 확인합니다
> - 이메일이 수신되지 않으면: SNS 구독 상태가 "Confirmed"인지 확인하고, 스팸 폴더를 확인합니다

✅ **태스크 완료**: 스트레스 테스트를 통해 경보가 정상적으로 동작하고 이메일 알림이 전송되는 것을 확인했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-7-1.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - CloudWatch 경보 (`CloudArchitect-Lab-HighCPU`)
   - CloudWatch 대시보드 (`CloudArchitect-Lab-Dashboard`)
   - SNS 주제 (`CloudArchitect-Lab-Alerts`)
   - EC2 인스턴스 (`CloudArchitect-Lab-MonitoringServer`)
   - IAM 역할 (`CloudArchitect-Lab-CloudWatchRole`)
   - Security Group, VPC 및 관련 리소스

> [!NOTE]
> 정리 스크립트는 이 실습에서 생성한 리소스만 삭제합니다. 다른 리소스에는 영향을 주지 않습니다.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

#### 태스크 1: Amazon CloudWatch 리소스 삭제

1. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

2. 왼쪽 메뉴에서 **Alarms**를 선택합니다.

3. `CloudArchitect-Lab-HighCPU` 경보를 선택하고 **Actions** > **Delete**를 선택합니다.

4. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

5. 왼쪽 메뉴에서 **Dashboards**를 선택합니다.

6. `CloudArchitect-Lab-Dashboard`를 선택하고 **Delete**를 클릭합니다.

7. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 2: Amazon SNS 주제 삭제

8. 상단 검색창에서 `SNS`를 검색하고 **SNS**를 선택합니다.

9. 왼쪽 메뉴에서 **Topics**를 선택합니다.

10. `CloudArchitect-Lab-Alerts`를 선택하고 **Delete**를 클릭합니다.

11. 확인 필드에 `delete me`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 3: Amazon EC2 인스턴스 종료

12. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

13. 왼쪽 메뉴에서 **Instances**를 선택합니다.

14. `CloudArchitect-Lab-MonitoringServer` 인스턴스를 선택합니다.

15. **Instance state** > **Terminate instance**를 선택합니다.

16. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 4: Security Group 및 Amazon VPC 삭제

17. EC2 인스턴스 종료 후, 왼쪽 메뉴의 **Security Groups**에서 `CloudArchitect-Lab-Web-SG`를 삭제합니다.

18. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

19. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

20. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 5: 최종 확인

21. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

22. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

23. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: **Asia Pacific (Seoul) ap-northeast-2**
   - **Resource types**: **All supported resource types**
   - **Tags**: Tag key에 **StudentId**를 선택하고, Tag value에 본인 학번을 입력합니다.

> [!TIP]
> StudentId 태그로 검색하면 본인이 수동으로 생성한 리소스(Alarm, Dashboard, SNS Topic)만 표시됩니다. setup 스크립트로 생성된 리소스는 Name 태그(`CloudArchitect-Lab`)로 검색할 수 있습니다.

24. [[Search resources]]를 클릭합니다.

25. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

📊
Amazon CloudWatch 지표
AWS 리소스의 성능 데이터를 실시간으로 수집하고 모니터링합니다. 네임스페이스 → 차원 → 지표 계층 구조로 구성됩니다

📈
대시보드
여러 지표를 한 화면에서 시각적으로 모니터링하여 리소스 상태를 빠르게 파악할 수 있습니다

🔔
알람 설정
지표가 임계값을 초과하면 자동으로 알림을 보내거나 Auto Scaling 등의 작업을 트리거할 수 있습니다

📉
위젯 유형
선 그래프, 숫자, 게이지 등 다양한 위젯으로 데이터를 시각화하여 직관적으로 이해할 수 있습니다

⏱️
통계 및 기간
평균, 최대, 최소, 합계 등의 통계를 선택하고 1분, 5분 등의 기간을 설정하여 데이터를 집계합니다

🎯
차원 필터링
인스턴스 ID, 로드 밸런서 이름 등 차원을 사용하여 특정 리소스의 지표만 선택적으로 모니터링합니다
