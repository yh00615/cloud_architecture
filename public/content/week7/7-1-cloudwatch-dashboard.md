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

> [!DOWNLOAD]
> [week7-1-cloudwatch-dashboard.zip](/files/week7/week7-1-cloudwatch-dashboard.zip)
>
> - `setup-4-1-student.sh` - 사전 환경 구축 스크립트 (VPC, Subnet, Security Group, EC2 인스턴스, IAM 역할 등 생성)
> - `cleanup-4-1-student.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-4-1-student.sh 실행)

> [!NOTE]
> 이 실습에서는 Amazon CloudWatch를 사용하여 EC2 인스턴스 모니터링, 경보 설정, SNS 알림 구성을 학습합니다. 실제 스트레스 테스트를 통해 경보 동작을 확인하고 대시보드를 구성합니다.

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

1. 위 DOWNLOAD 섹션에서 `week7-1-cloudwatch-dashboard.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > `Upload file`을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week7-1-cloudwatch-dashboard.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-4-1-student.sh
./setup-4-1-student.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| VPC | CloudArchitect-Lab-VPC |
| Internet Gateway | CloudArchitect-Lab-IGW |
| Public Subnet | CloudArchitect-Lab-Public-Subnet |
| Route Table | CloudArchitect-Lab-Public-RT |
| Security Group | CloudArchitect-Lab-Web-SG |
| EC2 인스턴스 | CloudArchitect-Lab-MonitoringServer |
| IAM 역할 | CloudArchitect-Lab-CloudWatchRole |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 Amazon EC2 인스턴스 확인

8. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

9. 왼쪽 메뉴에서 **Instances**를 선택합니다.

10. `CloudArchitect-Lab-MonitoringServer` 인스턴스의 상태가 "Running"인지 확인합니다.

11. 인스턴스를 선택하고 **Instance ID**를 복사하여 메모장에 저장합니다.

> [!NOTE]
> Instance ID는 CloudWatch에서 해당 인스턴스의 지표를 검색할 때 사용합니다. `i-0abc1234def56789` 형태입니다.

12. 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

13. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속하여 웹 서버가 정상 작동하는지 확인합니다.

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

14. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

15. 왼쪽 메뉴에서 **Metrics** 섹션 아래의 **All metrics**를 선택합니다.

16. **Browse** 탭에서 `EC2`를 선택합니다.

17. **Per-Instance Metrics**를 선택합니다.

18. 검색 필터에 태스크 1에서 복사한 **Instance ID**를 입력합니다.

19. 해당 인스턴스의 주요 지표를 확인합니다:
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

20. 상단 검색창에서 `SNS`를 검색하고 **SNS**를 선택합니다.

21. 왼쪽 메뉴에서 **Topics**를 선택합니다.

22. [[Create topic]] 버튼을 클릭합니다.

23. **Type**에서 `Standard`를 선택합니다.

24. **Name**에 `CloudArchitect-Lab-Alerts`를 입력합니다.

25. [[Create topic]] 버튼을 클릭합니다.

### 3.2 이메일 구독 설정

26. 생성된 토픽 상세 페이지에서 [[Create subscription]] 버튼을 클릭합니다.

27. **Protocol**에서 `Email`을 선택합니다.

28. **Endpoint**에 개인 이메일 주소를 입력합니다.

29. [[Create subscription]] 버튼을 클릭합니다.

30. 이메일 수신함을 확인하고 **Confirm subscription** 링크를 선택합니다.

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

31. CloudWatch 콘솔에서 왼쪽 메뉴의 **Alarms** 섹션을 확장하고 **All alarms**를 선택합니다.

32. [[Create alarm]] 버튼을 클릭합니다.

33. [[Select metric]] 버튼을 클릭합니다.

34. **Browse** 탭에서 `EC2` > **Per-Instance Metrics**를 선택합니다.

35. 검색 필터에 태스크 1에서 복사한 **Instance ID**를 입력하고 `CPUUtilization`을 선택합니다.

36. [[Select metric]] 버튼을 클릭합니다.

### 4.2 경보 조건 설정

37. **Statistic**에서 `Average`를 선택합니다.

38. **Period**에서 `1 minute`를 선택합니다.

39. **Threshold type**에서 `Static`을 선택합니다.

40. **Whenever CPUUtilization is**에서 `Greater`를 선택합니다.

41. **than** 필드에 `60`을 입력합니다.

42. [[Next]] 버튼을 클릭합니다.

### 4.3 알림 설정

43. **Alarm state trigger**에서 `In alarm`을 선택합니다.

44. **Select an existing SNS topic**을 선택하고 `CloudArchitect-Lab-Alerts`를 선택합니다.

45. [[Next]] 버튼을 클릭합니다.

46. **Alarm name**에 `CloudArchitect-Lab-HighCPU`를 입력합니다.

47. **Alarm description**에 `CPU usage exceeds 60%`를 입력합니다.

48. [[Next]] 버튼을 클릭합니다.

49. 설정을 검토한 후 [[Create alarm]] 버튼을 클릭합니다.

50. 경보 상태가 "OK"인지 확인합니다.

✅ **태스크 완료**: CPU 사용률 60% 초과 시 이메일 알림을 보내는 경보가 생성되었습니다.


## 태스크 5: Amazon CloudWatch 대시보드 생성

### 5.1 대시보드 생성

51. 왼쪽 메뉴에서 **Dashboards** 섹션을 선택합니다. (왼쪽 메뉴 상단에 위치합니다.)

52. [[Create dashboard]] 버튼을 클릭합니다.

53. **Dashboard name**에 `CloudArchitect-Lab-Dashboard`를 입력합니다.

54. [[Create dashboard]] 버튼을 클릭합니다.

### 5.2 위젯 추가

55. **Add widget** 대화상자에서 **Line**을 선택합니다.

56. [[Next]] 버튼을 클릭합니다.

57. **Browse** 탭에서 `EC2` > **Per-Instance Metrics**를 선택합니다.

58. 검색 필터에 **Instance ID**를 입력하고 `CPUUtilization`, `NetworkIn`, `NetworkOut` 지표를 선택합니다.

59. [[Create widget]] 버튼을 클릭합니다.

60. [[Save]] 버튼을 클릭하여 대시보드를 저장합니다.

> [!TIP]
> 대시보드에 여러 위젯을 추가하여 CPU, 네트워크, 디스크 지표를 한 화면에서 모니터링할 수 있습니다. 위젯은 드래그하여 크기와 위치를 조정할 수 있습니다.

✅ **태스크 완료**: CloudWatch 대시보드가 생성되었습니다.


## 태스크 6: 스트레스 테스트 및 경보 확인

### 6.1 Amazon EC2 인스턴스 접속

61. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

62. 왼쪽 메뉴에서 **Instances**를 선택합니다.

63. `CloudArchitect-Lab-MonitoringServer` 인스턴스를 선택합니다.

64. [[Connect]] 버튼을 클릭합니다.

65. **EC2 Instance Connect** 탭에서 [[Connect]] 버튼을 클릭합니다.

### 6.2 CPU 스트레스 테스트 실행

66. 터미널에서 다음 명령어를 실행하여 CPU 부하를 생성합니다:

```bash
stress --cpu 1 --timeout 300
```

> [!NOTE]
> `stress` 명령어는 5분(300초) 동안 CPU 부하를 생성합니다. 사전 구축 스크립트에서 이미 설치되어 있습니다.

### 6.3 경보 상태 확인

67. Amazon CloudWatch 콘솔로 이동합니다. 왼쪽 메뉴에서 **Alarms** 섹션을 확장하고 **All alarms**를 선택합니다.

68. `CloudArchitect-Lab-HighCPU` 경보의 상태가 "OK"에서 "In alarm"으로 변경될 때까지 기다립니다.

> [!NOTE]
> 경보 상태 변경에 약 2-3분이 소요됩니다. Period가 1분으로 설정되어 있으므로, 1분간의 평균 CPU 사용률이 60%를 초과하면 경보가 발생합니다.

69. 대시보드에서 CPU 사용률 그래프가 급격히 상승하는 것을 확인합니다.

70. 이메일 수신함에서 경보 알림 메일이 도착했는지 확인합니다.

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
./cleanup-4-1-student.sh
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

2. 왼쪽 메뉴에서 **All alarms**를 선택합니다.

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
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

24. [[Search resources]]를 클릭합니다.

25. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

📊
Amazon CloudWatch 지표
AWS 리소스의 성능 데이터를 실시간으로 수집하고 모니터링합니다. 네임스페이스 → 차원 → 지표 계층 구조로 구성됩니다.

📈
대시보드
여러 지표를 한 화면에서 시각적으로 모니터링하여 리소스 상태를 빠르게 파악할 수 있습니다.
