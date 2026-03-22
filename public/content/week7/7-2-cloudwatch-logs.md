---
title: 'CloudWatch Logs 분석'
week: 7
session: 2
awsServices:
  - Amazon CloudWatch
learningObjectives:
  - Amazon CloudWatch Logs의 수집, 저장 및 관리 방법을 파악하고 적용할 수 있습니다.
  - Amazon CloudWatch Logs Insights를 활용하여 로그를 분석할 수 있습니다.
  - 메트릭 필터를 생성하여 로그 기반 모니터링을 구성할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **CloudWatch Logs**로 **EC2 인스턴스**의 로그를 수집하고 분석합니다. **CloudWatch Agent**를 설치하여 **Nginx 액세스 로그**와 **에러 로그**를 CloudWatch Logs로 전송합니다. **Logs Insights**에서 쿼리 언어로 로그를 검색하고 필터링하여 특정 패턴을 찾습니다. **메트릭 필터**를 생성하여 로그에서 에러 발생 횟수를 추출하고, 이를 대시보드에 표시합니다.

> [!DOWNLOAD]
> [week7-2-cloudwatch-logs.zip](/files/week7/week7-2-cloudwatch-logs.zip)
>
> **포함 파일:**
> 
> **setup-7-2.sh** - 사전 환경 구축 스크립트
> - **목적**: CloudWatch Logs 실습을 위한 완전한 인프라 자동 구축
> - **생성 리소스**:
>   - VPC 네트워크 (VPC, Subnet, Internet Gateway, Route Table, Security Group)
>   - IAM 역할 및 Instance Profile (CloudWatch Agent 권한 포함)
>   - EC2 인스턴스 (t3.micro, Amazon Linux 2023)
> - **자동 구성 내용** (User Data):
>   - Nginx 웹서버 설치 및 시작
>   - CloudWatch Agent 설치 및 구성
>   - 로그 수집 설정 (/var/log/nginx/access.log, /var/log/nginx/error.log)
>   - 자동 트래픽 생성 시스템 (2분마다 정상/에러 로그 생성)
>   - CloudWatch Logs 그룹 자동 생성 (/aws/ec2/nginx/access, /aws/ec2/nginx/error)
> - **실행 시간**: 약 5-7분
> - **활용**: 태스크 1-6에서 생성된 로그를 분석하고 모니터링합니다
>
> **cleanup-7-2.sh** - 리소스 정리 스크립트
> - **목적**: 실습에서 생성한 모든 리소스를 안전한 순서로 자동 삭제
> - **삭제 리소스**: CloudWatch Logs 그룹, EC2 인스턴스, IAM 역할, VPC 및 네트워크 리소스
> - **실행 시간**: 약 3-5분
>
> **사용 태스크:**
> - 태스크 0: 사전 환경 구축 (setup-7-2.sh 실행, 약 5-7분 소요)
> - 리소스 정리: 실습 완료 후 cleanup-7-2.sh 실행하여 모든 리소스 삭제

> [!CONCEPT] Amazon CloudWatch Logs란?
>
> CloudWatch Logs는 AWS 리소스와 애플리케이션의 **로그를 중앙에서 수집, 저장, 분석**하는 서비스입니다.
>
> - **로그 그룹(Log Group)**: 동일한 유형의 로그를 그룹화하는 컨테이너입니다 (예: `/aws/ec2/nginx/access`)
> - **로그 스트림(Log Stream)**: 동일한 소스에서 오는 로그 이벤트의 시퀀스입니다 (예: 인스턴스 ID별)
> - **로그 이벤트(Log Event)**: 타임스탬프와 메시지를 포함하는 개별 로그 항목입니다
> - **CloudWatch Agent**: EC2 인스턴스에 설치하여 로그를 CloudWatch로 전송하는 에이전트입니다
>
> 이 실습에서는 Nginx 웹 서버의 Access/Error 로그를 CloudWatch Logs로 수집하고 분석합니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

### 0.1 사전 환경 구축의 목적

이 실습에서는 **CloudWatch Logs**를 통해 실제 웹 서버의 로그를 수집하고 분석하는 방법을 학습합니다. 이를 위해 다음과 같은 환경이 필요합니다:

**구축되는 인프라:**
- **VPC 네트워크**: 격리된 네트워크 환경에서 EC2 인스턴스를 실행합니다
- **EC2 인스턴스 (로그 서버)**: Nginx 웹 서버가 설치되어 실제 로그를 생성합니다
- **CloudWatch Agent**: EC2 인스턴스의 로그 파일을 CloudWatch Logs로 자동 전송합니다
- **IAM 역할**: CloudWatch Agent가 로그를 전송할 수 있는 권한을 제공합니다
- **자동 트래픽 생성**: 2분마다 다양한 HTTP 요청(정상 200, 에러 404)을 생성하여 분석할 로그 데이터를 제공합니다

**실습에서의 활용:**
- **태스크 1-3**: 생성된 로그 그룹과 로그 스트림을 확인하고 실시간 로그를 관찰합니다
- **태스크 4**: 404 에러 로그를 감지하는 메트릭 필터를 생성합니다
- **태스크 5**: Logs Insights로 로그를 쿼리하고 분석합니다
- **태스크 6**: Live Tail로 실시간 로그를 모니터링합니다

> [!TIP]
> 사전 환경 구축 스크립트는 실습에 필요한 모든 인프라를 자동으로 생성하므로, 여러분은 CloudWatch Logs의 핵심 기능 학습에만 집중할 수 있습니다.

### 0.2 환경 구축 실행

1. 위 DOWNLOAD 섹션에서 `week7-2-cloudwatch-logs.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week7-2-cloudwatch-logs.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-7-2.sh cleanup-7-2.sh
./setup-7-2.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 내용을 확인하고 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 5-7분이 소요됩니다. EC2 인스턴스 생성 후 Nginx 및 CloudWatch Agent 설치까지 기다립니다.

### 0.3 생성된 리소스 확인

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 유형 | 리소스 이름 | 실습에서의 역할 |
|------------|------------|----------------|
| VPC | CloudArchitect-Lab-VPC | EC2 인스턴스를 위한 격리된 네트워크 환경 |
| Internet Gateway | CloudArchitect-Lab-IGW | 인터넷 연결을 위한 게이트웨이 |
| Public Subnet | CloudArchitect-Lab-Public-Subnet | EC2 인스턴스가 배치되는 서브넷 |
| Route Table | CloudArchitect-Lab-Public-RT | 인터넷 트래픽 라우팅 |
| Security Group | CloudArchitect-Lab-Web-SG | HTTP(80), SSH(22) 트래픽 허용 |
| EC2 인스턴스 | CloudArchitect-Lab-LogServer | Nginx 웹 서버 + CloudWatch Agent 실행 |
| IAM 역할 | CloudArchitect-Lab-CloudWatchAgent-Role | CloudWatch Logs 전송 권한 제공 |
| CloudWatch Logs 그룹 | /aws/ec2/nginx/access | Nginx 액세스 로그 저장 |
| CloudWatch Logs 그룹 | /aws/ec2/nginx/error | Nginx 에러 로그 저장 |

8. 출력 메시지에서 EC2 인스턴스의 **Public IP 주소**를 확인하고 메모합니다.

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week7-2-cloudwatch-logs.zip setup-7-2.sh cleanup-7-2.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 Amazon EC2 로그 서버 확인

9. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

10. 왼쪽 메뉴에서 **Instances**를 선택합니다.

11. `CloudArchitect-Lab-LogServer` 인스턴스의 상태가 "Running"인지 확인합니다.

12. 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

### 1.2 웹 서버 접속 및 로그 생성

13. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속합니다.

14. CloudWatch Logs 실습 환경 페이지가 정상적으로 표시되는지 확인합니다.

15. **여러 번 새로고침**(F5 키)하여 Access 로그를 생성합니다.

16. 존재하지 않는 페이지에도 접속하여 404 에러 로그를 생성합니다:
- `http://[복사한 Public IP]/test404`
- `http://[복사한 Public IP]/notfound`
- `http://[복사한 Public IP]/api/test`

> [!NOTE]
> 웹 서버에 접속하면 Nginx가 `/var/log/nginx/access.log`에 로그를 기록하고, CloudWatch Agent가 이를 CloudWatch Logs로 전송합니다. 또한 사전 구축 스크립트에 의해 자동 트래픽 생성 시스템이 2분마다 다양한 URL 패턴(정상 200, 에러 404)의 로그를 생성합니다.

17. **약 2-3분 기다려** CloudWatch Agent가 로그를 전송하도록 합니다.

> [!TIP]
> CloudWatch Agent는 15초마다 로그 파일을 확인하고 변경사항을 CloudWatch Logs로 전송합니다. 처음 로그 그룹이 생성되는 데는 1-2분 정도 소요됩니다.

✅ **태스크 완료**: 웹 서버가 정상 작동하고 로그가 생성되었습니다.


## 태스크 2: Amazon CloudWatch Logs 그룹 확인

> [!CONCEPT] 로그 그룹과 로그 스트림의 관계
>
> 하나의 로그 그룹 안에 여러 로그 스트림이 존재할 수 있습니다. 예를 들어 `/aws/ec2/nginx/access` 로그 그룹에는 각 EC2 인스턴스별로 별도의 로그 스트림이 생성됩니다. 이렇게 분리하면 특정 인스턴스의 로그만 선택적으로 조회할 수 있습니다.

### 2.1 Access 로그 그룹 확인

18. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

19. 왼쪽 메뉴에서 **Logs**를 선택하여 확장한 후 **Log Management**를 선택합니다.

20. `/aws/ec2/nginx/access` 로그 그룹을 선택합니다.

21. 로그 그룹의 **Retention**, **Stored bytes**, **Creation time**을 확인합니다.

22. **Log streams** 탭에서 생성된 로그 스트림을 확인합니다.

### 2.2 Error 로그 그룹 확인

23. 왼쪽 메뉴에서 **Log Management**를 다시 선택합니다.

24. `/aws/ec2/nginx/error` 로그 그룹을 선택합니다.

25. Error 로그 그룹의 세부 정보와 로그 스트림을 확인합니다.

> [!TIP]
> Access 로그와 Error 로그를 별도의 그룹으로 분리하면 각각 다른 보존 기간을 설정하거나, Error 로그에만 경보를 설정하는 등 유연한 관리가 가능합니다.

✅ **태스크 완료**: Access 로그와 Error 로그 그룹이 정상적으로 생성된 것을 확인했습니다.


## 태스크 3: 실시간 로그 확인

### 3.1 Access 로그 스트림 확인

26. `/aws/ec2/nginx/access` 로그 그룹에서 **Log streams** 탭의 로그 스트림을 선택합니다.

27. 생성된 로그 이벤트들을 확인합니다.

28. 각 로그 이벤트의 **Timestamp**와 **Message**를 확인합니다.

29. 정상 접속(200 응답)과 404 에러 로그를 구분하여 확인합니다.

> [!NOTE]
> Access 로그 형식 예시:
>
> - 정상 접속: `192.168.1.1 - - [10/Jan/2025:10:30:15 +0000] "GET / HTTP/1.1" 200 612`
> - 404 에러: `192.168.1.1 - - [10/Jan/2025:10:30:20 +0000] "GET /test404 HTTP/1.1" 404 153`

### 3.2 Error 로그 스트림 확인

30. 왼쪽 메뉴에서 **Log Management**를 선택합니다.

31. `/aws/ec2/nginx/error` 로그 그룹의 로그 스트림을 선택합니다.

32. 404 에러와 관련된 상세한 에러 로그를 확인합니다.

33. Access 로그와 Error 로그의 차이점을 비교합니다.

> [!NOTE]
> Error 로그는 Access 로그보다 상세한 오류 정보를 포함합니다. 예: `2025/01/10 10:30:20 [error] 1234#0: *1 open() "/usr/share/nginx/html/test404" failed (2: No such file or directory)`

✅ **태스크 완료**: Access 로그와 Error 로그 스트림에서 실시간 로그 데이터를 확인했습니다.


## 태스크 4: 메트릭 필터 생성

> [!CONCEPT] 메트릭 필터란?
>
> 메트릭 필터는 로그 이벤트를 스캔하여 지정된 패턴과 일치하는 항목을 찾고, 이를 **CloudWatch 지표로 변환**합니다. 예를 들어 404 에러가 발생할 때마다 지표 값이 1씩 증가하도록 설정하면, 이 지표에 경보를 연결하여 에러 급증 시 알림을 받을 수 있습니다.

### 4.1 404 에러 메트릭 필터 생성

34. `/aws/ec2/nginx/access` 로그 그룹 페이지에서 **Metric filters** 탭을 선택합니다.

35. [[Create metric filter]] 버튼을 클릭합니다.

36. **Filter pattern**에 다음을 입력합니다:

```
[ip, identity, user, timestamp, request, status_code="404", size]
```

37. **Select log data to test** 섹션에서 **Custom log data**를 선택하고, 본인의 Instance ID로 변경한 후 [[Test pattern]] 버튼을 클릭하여 패턴이 404 에러 로그와 매칭되는지 확인합니다.

> [!IMPORTANT]
> Test pattern 실행 시 기본 제공되는 샘플 데이터가 아닌, 본인의 Instance ID에 해당하는 로그 데이터를 선택해야 결과가 표시됩니다.

38. [[Next]] 버튼을 클릭합니다.

### 4.2 메트릭 설정

39. **Filter name**에 `404-Error-Filter`를 입력합니다.

40. **Metric namespace**에 `CloudArchitect/Lab11`을 입력합니다.

41. **Metric name**에 `404ErrorCount`를 입력합니다.

42. **Metric value**에 `1`을 입력합니다.

43. [[Next]] 버튼을 클릭합니다.

44. 설정을 검토한 후 [[Create metric filter]] 버튼을 클릭합니다.

> [!TIP]
> 생성된 메트릭 필터는 이후 발생하는 로그에만 적용됩니다. 과거 로그에는 소급 적용되지 않습니다. 메트릭이 생성되면 CloudWatch Metrics에서 `CloudArchitect/Lab11` 네임스페이스에서 확인할 수 있습니다.

✅ **태스크 완료**: 404 에러를 감지하는 메트릭 필터가 생성되었습니다.


## 태스크 5: Amazon CloudWatch Logs Insights 쿼리

> [!CONCEPT] CloudWatch Logs Insights란?
>
> Logs Insights는 로그 데이터를 **SQL과 유사한 쿼리 언어**로 검색하고 분석하는 기능입니다. 필터링, 파싱, 집계, 정렬 등 다양한 분석이 가능하며, 결과를 시각화할 수도 있습니다.

### 5.1 기본 로그 분석 쿼리

45. 왼쪽 메뉴에서 **Logs**를 선택하여 확장한 후 **Logs Insights**를 선택합니다.

46. **Select log group(s)** 드롭다운에서 `/aws/ec2/nginx/access`를 검색하여 선택합니다.

47. 시간 범위를 **Last 1 hour**로 설정합니다.

48. 쿼리 편집기에 다음 쿼리를 입력합니다:

```
fields @timestamp, @message
| filter @message like /404/
| sort @timestamp desc
| limit 20
```

49. [[Run query]] 버튼을 클릭합니다.

50. 결과에서 404 에러 로그들을 확인합니다.

### 5.2 상태 코드별 통계 쿼리

51. 쿼리 편집기에 다음 쿼리를 입력합니다:

```
fields @timestamp, @message
| parse @message /(?<ip>\S+) \S+ \S+ \[(?<timestamp>[^\]]+)\] "(?<method>\S+) (?<path>\S+) (?<protocol>\S+)" (?<status>\d+) (?<size>\d+)/
| stats count() by status
| sort count desc
```

52. [[Run query]] 버튼을 클릭합니다.

53. 결과에서 200, 404 등 상태 코드별 발생 횟수를 확인합니다.

### 5.3 시간별 로그 발생 패턴 분석

54. 다음 쿼리를 입력하여 시간별 로그 발생 패턴을 분석합니다:

```
fields @timestamp
| stats count() by bin(5m)
| sort @timestamp desc
```

55. [[Run query]] 버튼을 클릭합니다.

56. 결과에서 5분 단위로 로그 발생 추이를 확인합니다.

> [!TIP]
> Logs Insights 쿼리 결과는 **Visualization** 탭에서 그래프로 시각화할 수 있습니다. `stats` 명령어와 `bin()` 함수를 함께 사용하면 시계열 그래프를 생성할 수 있습니다.

✅ **태스크 완료**: Logs Insights를 통해 로그 검색, 파싱, 집계 분석을 수행했습니다.


## 태스크 6: Live Tail 실시간 모니터링

### 6.1 Live Tail 시작

57. `/aws/ec2/nginx/access` 로그 그룹 페이지로 이동합니다.

58. [[Start tailing]] 버튼을 클릭합니다.

59. Live tail 상태가 "Running"으로 변경될 때까지 기다립니다.

### 6.2 실시간 로그 관찰

60. 다른 브라우저 탭에서 웹 서버 IP로 접속하여 실시간으로 로그가 나타나는지 확인합니다.

61. 존재하지 않는 페이지(예: `http://[IP]/test-page`)에 접속하여 404 에러 로그를 생성합니다.

62. Live tail 화면에서 **Filter events** 입력창에 `404`를 입력하여 404 에러 로그만 필터링합니다.

63. 필터를 `200`으로 변경하여 정상 접속 로그만 표시합니다.

64. [[Cancel]] 버튼을 클릭하여 세션을 종료합니다.

> [!NOTE]
> Live tail은 실시간 문제 감지, 배포 후 로그 확인, 트래픽 패턴 분석 등에 유용합니다. 필터링 기능으로 특정 조건의 로그만 선택적으로 모니터링할 수 있습니다.

✅ **태스크 완료**: Live tail을 통해 실시간 로그 모니터링과 필터링을 체험했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-7-2.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - CloudWatch 로그 그룹 (`/aws/ec2/nginx/access`, `/aws/ec2/nginx/error`)
   - 메트릭 필터
   - EC2 인스턴스 (`CloudArchitect-Lab-LogServer`)
   - IAM 역할 (`CloudArchitect-Lab-CloudWatchAgent-Role`)
   - Security Group, VPC 및 관련 리소스

> [!NOTE]
> 정리 스크립트는 이 실습에서 생성한 리소스만 삭제합니다. 다른 리소스에는 영향을 주지 않습니다.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

#### 태스크 1: Amazon CloudWatch Logs 리소스 삭제

1. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

2. 왼쪽 메뉴에서 **Log Management**를 선택합니다.

3. `/aws/ec2/nginx/access` 로그 그룹을 선택하고 **Actions** > **Delete log group(s)**를 선택합니다.

4. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

5. `/aws/ec2/nginx/error` 로그 그룹도 동일하게 삭제합니다.

6. 실습에서 생성한 메트릭 필터가 있다면 해당 로그 그룹의 **Metric filters** 탭에서 삭제합니다.

#### 태스크 2: Amazon EC2 인스턴스 종료

7. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

8. 왼쪽 메뉴에서 **Instances**를 선택합니다.

9. `CloudArchitect-Lab-LogServer` 인스턴스를 선택합니다.

10. **Instance state** > **Terminate instance**를 선택합니다.

11. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 3: Security Group 및 Amazon VPC 삭제

12. EC2 인스턴스 종료 후, 왼쪽 메뉴의 **Security Groups**에서 `CloudArchitect-Lab-Web-SG`를 삭제합니다.

13. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

14. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

15. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: 최종 확인

16. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

17. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

18. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

> [!NOTE]
> 7주차 실습은 setup 스크립트로 리소스를 생성하므로 Name 태그로 검색합니다. 수동으로 생성한 리소스가 있다면 StudentId 태그로도 검색할 수 있습니다.

19. [[Search resources]]를 클릭합니다.

20. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

📋
CloudWatch Logs 구조
로그 그룹 → 로그 스트림 → 로그 이벤트 계층 구조로 로그를 체계적으로 관리합니다.

🔍
Logs Insights
SQL과 유사한 쿼리 언어로 로그를 검색, 파싱, 집계하여 패턴을 분석합니다.

📊
메트릭 필터
로그 패턴을 CloudWatch 지표로 변환하여 로그 기반 모니터링과 경보를 구성합니다.
