---
title: '기본 백업 전략 구성'
week: 12
session: 3
awsServices:
  - AWS Backup
learningObjectives:
  - AWS Backup 서비스의 주요 기능과 클라우드 리소스 보호 메커니즘을 이해할 수 있습니다.
  - AWS Backup의 핵심 기능(백업 계획, 백업 볼트, 복구 시점)을 활용할 수 있습니다.
  - 다양한 AWS 재해 복구 전략 유형(백업/복원, 파일럿 라이트, 웜 스탠바이, 다중 사이트)을 비교할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **AWS Backup**으로 **EC2 인스턴스**의 백업 전략을 구현합니다. **백업 볼트**를 생성하여 백업 데이터를 안전하게 저장하고, **백업 계획**으로 자동 백업 스케줄을 설정합니다. **태그 기반 리소스 선택**으로 특정 태그를 가진 EC2 인스턴스를 자동으로 백업 대상에 포함합니다. 수동 백업을 생성하고, **복구 시점**을 사용하여 EC2 인스턴스를 이전 상태로 복원하는 과정을 실습합니다.

> [!DOWNLOAD]
> [week12-3-backup-strategy.zip](/files/week12/week12-3-backup-strategy.zip)
>
> - `setup-12-3.sh` - 사전 환경 구축 스크립트 (VPC, Subnet, Security Group, Amazon EC2 인스턴스, AWS IAM 백업 역할 등 생성)
> - `cleanup-12-3.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-12-3.sh 실행)

> [!CONCEPT] AWS Backup이란?
>
> AWS Backup은 AWS 리소스의 백업을 **중앙에서 관리하고 자동화**하는 완전 관리형 서비스입니다.
>
> - **백업 볼트(Vault)**: 백업 데이터를 안전하게 저장하는 암호화된 컨테이너입니다
> - **백업 계획(Plan)**: 백업 빈도, 보존 기간, 대상 리소스를 정의한 정책입니다
> - **복구 시점(Recovery Point)**: 특정 시점의 백업 데이터로, 이를 통해 리소스를 복원합니다
> - **태그 기반 선택**: 태그 조건에 맞는 리소스를 자동으로 백업 대상에 포함합니다

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week12-3-backup-strategy.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** → **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week12-3-backup-strategy.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-12-3.sh
./setup-12-3.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| VPC | CloudArchitect-Lab-VPC |
| Public Subnet | CloudArchitect-Lab-Public-Subnet |
| Security Group | CloudArchitect-Lab-EC2-SG |
| EC2 인스턴스 | CloudArchitect-Lab-TestInstance |
| IAM 백업 역할 | CloudArchitect-Lab-BackupRole |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week12-3-backup-strategy.zip setup-12-3.sh cleanup-12-3.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

8. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

9. Amazon EC2 콘솔의 왼쪽 메뉴에서 **Instances** 섹션 아래의 **Instances**를 선택합니다.

10. `CloudArchitect-Lab-TestInstance` 인스턴스의 상태가 "Running"인지 확인합니다.

11. 인스턴스를 선택하고 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

12. 하단의 **Tags** 탭을 선택하여 백업용 태그를 확인합니다:
- **Project**: `CloudArchitect`
- **Week**: `Week12-3`
- **Purpose**: `Backup-Test`

> [!NOTE]
> 이 태그들은 태스크 3에서 AWS Backup이 백업 대상 리소스를 자동으로 식별하는 데 사용됩니다. 태그 기반 선택을 사용하면 새 리소스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함됩니다.

13. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속하여 웹 페이지가 표시되는지 확인합니다.

> [!TROUBLESHOOTING]
> 페이지가 로드되지 않는 경우:
> - 인스턴스 생성 후 2-3분 대기합니다 (웹서버 설치 및 시작 중)
> - 주소가 `https://`가 아닌 `http://`로 시작하는지 확인합니다
> - 보안 그룹에 HTTP(80) 인바운드 규칙이 있는지 확인합니다

✅ **태스크 완료**: EC2 인스턴스와 웹 서버가 정상 작동하고 있습니다.


## 태스크 2: AWS Backup 볼트 생성

> [!NOTE]
> 백업 볼트는 백업 데이터를 저장하는 암호화된 컨테이너입니다. 볼트를 별도로 생성하면 백업 데이터를 논리적으로 분리하여 관리할 수 있고, 볼트별로 다른 암호화 키와 접근 정책을 적용할 수 있습니다.

14. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

15. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Backup vaults**를 선택합니다.

16. [[Create backup vault]] 버튼을 클릭합니다.

17. **Vault name**에 `CloudArchitect-Lab-BackupVault`를 입력합니다.

18. **Vault type**에서 **Backup vault**를 선택합니다 (기본값).

19. **Encryption key** 섹션의 **Choose KMS key**에서 기본 AWS 관리형 키를 유지합니다.

20. [[Create vault]] 버튼을 클릭합니다.

✅ **태스크 완료**: 백업 데이터를 저장할 볼트가 생성되었습니다.


## 태스크 3: 백업 계획 생성

> [!CONCEPT] 백업 계획의 구성 요소
>
> 백업 계획은 **백업 규칙**과 **리소스 할당** 두 부분으로 구성됩니다:
>
> - **백업 규칙**: 백업 빈도(매일/매주), 백업 시간, 보존 기간을 정의합니다
> - **리소스 할당**: 태그 기반으로 백업 대상 리소스를 자동 선택합니다
>
> 태그 기반 선택을 사용하면 새 리소스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함됩니다.

### 3.1 백업 계획 생성

21. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Backup plans**를 선택합니다.

22. [[Create backup plan]] 버튼을 클릭합니다.

23. **Build a new plan**을 선택합니다.

24. **Backup plan name**에 `CloudArchitect-Lab-BackupPlan`을 입력합니다.

### 3.2 백업 규칙 설정

25. **Backup rule configuration** 섹션에서 **Backup rule name**에 `DailyBackups`를 입력합니다.

26. **Backup vault** 드롭다운에서 `CloudArchitect-Lab-BackupVault`를 선택합니다.

27. **Backup frequency**를 `Daily`로 설정합니다.

28. **Backup window**의 **Start time**은 기본값을 유지합니다.

29. **Lifecycle** 섹션에서 **Total retention period**를 `7 days`로 설정합니다.

30. [[Create plan]] 버튼을 클릭합니다.

### 3.3 리소스 할당

31. 백업 계획 상세 페이지에서 [[Assign resources]] 버튼을 클릭합니다.

32. **Resource assignment name**에 `CloudArchitect-Lab-BackupSelection`을 입력합니다.

33. **IAM role**에서 **Choose an IAM role**을 선택한 후 `CloudArchitect-Lab-BackupRole`을 선택합니다.

34. **Define resource selection**에서 **Include specific resource types**를 선택합니다.

35. **Select specific resource types** 섹션의 **Select resource types** 드롭다운에서 **EC2**를 선택합니다.

36. **Refine selection using tags** 섹션에서 [[Add tags]] 버튼을 클릭합니다.

37. 첫 번째 태그 조건을 설정합니다:
- **Key**: `Project`
- **Condition for value**: **Equals**
- **Value**: `CloudArchitect`

38. [[Add tag]] 버튼을 클릭하여 두 번째 태그 조건을 추가합니다:
- **Key**: `Week`
- **Condition for value**: **Equals**
- **Value**: `Week12-3`

39. [[Assign resources]] 버튼을 클릭합니다.

40. 리소스 할당이 완료되면 백업 계획 상세 페이지로 돌아갑니다.

> [!NOTE]
> 두 태그 조건은 AND 조건으로 동작합니다. `Project=CloudArchitect`와 `Week=Week12-3` 태그를 모두 가진 EC2 인스턴스만 백업 대상으로 선택됩니다. 이 방식을 사용하면 새 인스턴스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함되어 관리가 편리합니다.

✅ **태스크 완료**: 백업 계획이 생성되고 태그 기반으로 EC2 인스턴스가 백업 대상에 할당되었습니다.


## 태스크 4: 수동 백업 실행

> [!NOTE]
> 백업 계획은 설정된 스케줄에 따라 자동으로 실행되지만, 즉시 백업이 필요한 경우 수동(온디맨드) 백업을 실행할 수 있습니다. 이 태스크에서는 수동 백업을 실행하여 백업 프로세스를 직접 체험합니다.

40. AWS Backup 콘솔의 왼쪽 메뉴에서 **Dashboard**를 선택합니다.

41. 대시보드 화면 오른쪽 상단의 [[Create on-demand backup]] 버튼을 클릭합니다.

42. **Resource type**에서 **EC2**를 선택합니다.

43. **Instance ID** 드롭다운에서 `CloudArchitect-Lab-TestInstance`를 선택합니다.

44. **Backup vault** 드롭다운에서 `CloudArchitect-Lab-BackupVault`를 선택합니다.

45. **IAM role**에서 **Choose an IAM role**을 선택한 후 `CloudArchitect-Lab-BackupRole`을 선택합니다.

46. **Total retention period**를 `7 days`로 설정합니다.

47. [[Create on-demand backup]] 버튼을 클릭합니다.

48. 자동으로 왼쪽 메뉴의 **Jobs** 페이지가 열리고 **Backup jobs** 탭에서 백업 작업 상태를 확인할 수 있습니다.

> [!NOTE]
> EC2 인스턴스 백업에 약 10-15분이 소요됩니다. **Status** 열에서 "Created" → "Running" → "Completed" 순서로 진행됩니다. 페이지를 새로고침하여 상태를 확인합니다. 대기하는 동안 다음 태스크를 미리 읽어봅니다.

49. 백업 작업 상태가 "Completed"로 변경될 때까지 기다립니다.

✅ **태스크 완료**: EC2 인스턴스의 수동 백업이 완료되었습니다.


## 태스크 5: 백업 복원 실습

> [!IMPORTANT]
> 태스크 4의 백업 작업이 "Completed" 상태여야 복원을 진행할 수 있습니다. Jobs 페이지에서 Status를 확인합니다.

50. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Protected resources**를 선택합니다.

51. 리소스 목록에서 `CloudArchitect-Lab-TestInstance`를 선택합니다.

52. **Recovery points** 섹션에서 생성된 복구 시점의 라디오 버튼을 선택합니다.

53. [[Restore]] 버튼을 클릭합니다.

54. **Instance configuration** 섹션에서 다음 설정을 확인합니다:
- **Instance type**: `t3.micro` (원본과 동일)
- **VPC**: 원본 VPC 선택
- **Subnet**: 원본 서브넷 선택
- **Security groups**: 원본 보안 그룹 선택

55. **Restore role**에서 `CloudArchitect-Lab-BackupRole`을 선택합니다.

56. [[Restore backup]] 버튼을 클릭합니다.

> [!NOTE]
> EC2 인스턴스 복원에 약 5-10분이 소요됩니다. Jobs 페이지의 **Restore jobs** 탭에서 진행 상태를 확인합니다.

57. 복원이 완료되면 Amazon EC2 콘솔로 이동하여 새로 생성된 복원 인스턴스를 확인합니다.

> [!OUTPUT]
> ```
> EC2 인스턴스 목록에서 다음과 같이 두 개의 인스턴스가 표시됩니다:
>
> Name                              | Instance state | Instance type
> CloudArchitect-Lab-TestInstance   | Running        | t3.micro
> (복원된 인스턴스 - 이름 없음)       | Running        | t3.micro
> ```

58. 복원된 인스턴스의 **Public IPv4 address**를 복사합니다.

59. 새 브라우저 탭에서 `http://[복원된 인스턴스 IP]`로 접속합니다.

60. 원본 인스턴스와 동일한 웹 페이지가 표시되는지 확인합니다.

✅ **태스크 완료**: 백업에서 EC2 인스턴스가 성공적으로 복원되었습니다.


## 태스크 6: AWS Backup 대시보드 확인

61. AWS Backup 콘솔의 왼쪽 메뉴에서 **Dashboard**를 선택합니다.

62. **Jobs status over time** 섹션에서 백업/복원 작업 상태 그래프를 확인합니다.

63. **Backup job status overview**에서 Completed, Failed 작업 수를 확인합니다.

64. **Backup job health** 섹션에서 백업 성공률을 확인합니다.

> [!TIP]
> 실무에서는 AWS Backup 대시보드를 주기적으로 확인하여 백업 상태를 모니터링합니다. CloudWatch와 연동하면 백업 실패 시 자동으로 알림을 받을 수 있습니다.

✅ **태스크 완료**: AWS Backup 대시보드에서 백업 작업 현황을 확인했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-12-3.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - EC2 인스턴스 (`CloudArchitect-Lab-TestInstance`)
   - IAM 역할 (`CloudArchitect-Lab-BackupRole`)
   - Security Group, VPC 및 관련 리소스

> [!NOTE]
> 실습 중 직접 생성한 AWS Backup 리소스(볼트, 계획, 복구 시점)는 스크립트로 삭제되지 않을 수 있습니다. 아래 수동 삭제 단계를 확인하세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> AWS Backup 리소스는 복구 시점 → 백업 계획 → 백업 볼트 순서로 삭제해야 합니다.

#### 태스크 1: AWS Backup 복구 시점 삭제

1. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

2. 왼쪽 메뉴에서 **Backup vaults**를 선택합니다.

3. `CloudArchitect-Lab-BackupVault`를 선택합니다.

4. **Recovery points** 목록에서 모든 복구 시점을 선택하고 **Actions** > **Delete**를 선택합니다.

5. 확인 필드에 `delete`를 입력하고 [[Delete recovery points]]를 클릭합니다.

> [!NOTE]
> 복구 시점 삭제에는 약 1-2분이 소요될 수 있습니다.

#### 태스크 2: AWS Backup 계획 삭제

6. 왼쪽 메뉴에서 **Backup plans**를 선택합니다.

7. `CloudArchitect-Lab-BackupPlan`을 선택합니다.

8. **Resource assignments** 섹션에서 리소스 할당을 먼저 삭제합니다.

9. **Delete** 버튼을 클릭합니다.

10. 확인 필드에 `delete`를 입력하고 [[Delete plan]]을 클릭합니다.

#### 태스크 3: AWS Backup 볼트 삭제

11. 왼쪽 메뉴에서 **Backup vaults**를 선택합니다.

12. `CloudArchitect-Lab-BackupVault`를 선택합니다.

13. **Delete** 버튼을 클릭합니다.

14. 확인 필드에 `CloudArchitect-Lab-BackupVault`를 입력하고 [[Delete backup vault]]를 클릭합니다.

#### 태스크 4: Amazon EC2 인스턴스 종료

15. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

16. 왼쪽 메뉴에서 **Instances**를 선택합니다.

17. `CloudArchitect-Lab-TestInstance` 인스턴스를 선택합니다.

> [!TIP]
> 복원된 인스턴스가 있다면 함께 선택하여 종료합니다.

18. **Instance state** > **Terminate instance**를 선택합니다.

19. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 5: Security Group 및 Amazon VPC 삭제

20. EC2 인스턴스 종료 후, 왼쪽 메뉴의 **Security Groups**에서 `CloudArchitect-Lab-EC2-SG`를 삭제합니다.

21. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

22. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

23. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

24. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

25. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

26. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

27. [[Search resources]]를 클릭합니다.

28. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🔒
AWS Backup 볼트
백업 데이터를 암호화하여 안전하게 저장하는 컨테이너를 생성했습니다

📋
백업 계획
매일 자동 백업, 7일 보존 기간의 백업 정책을 구성했습니다

🔄
백업 및 복원
수동 백업을 실행하고 복구 시점에서 EC2 인스턴스를 성공적으로 복원했습니다

📊
대시보드 모니터링
AWS Backup 대시보드에서 백업 작업 현황과 성공률을 확인했습니다
