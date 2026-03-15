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
> **포함 파일:**
> 
> **setup-12-3.sh** - 사전 환경 구축 스크립트
> - **목적**: AWS Backup 실습을 위한 네트워크와 백업 대상 EC2 인스턴스 자동 구축
> - **생성 리소스**:
>   - VPC 네트워크 (VPC, Internet Gateway, Public Subnet, Route Table)
>   - Security Group (HTTP 80, SSH 22 포트 허용)
>   - EC2 인스턴스 (백업 대상, 웹 서버 및 샘플 데이터 포함)
>   - IAM 백업 역할 (AWS Backup 서비스 권한)
>   - 백업용 태그 (Project=CloudArchitect, Week=Week12-3)
> - **실행 시간**: 약 3-5분
> - **활용**: 태스크 2-6에서 백업 볼트를 생성하고, 백업 계획을 설정하며, 태그 기반으로 EC2를 백업하고 복원합니다
>
> **cleanup-12-3.sh** - 리소스 정리 스크립트
> - **목적**: 실습에서 생성한 모든 리소스를 안전한 순서로 자동 삭제
> - **삭제 리소스**: 백업 복구 포인트, 백업 계획, 백업 볼트, EC2 인스턴스, IAM 역할, VPC 및 네트워크 리소스
> - **실행 시간**: 약 3-5분
>
> **사용 태스크:**
> - 태스크 0: 사전 환경 구축 (setup-12-3.sh 실행)
> - 리소스 정리: 실습 완료 후 cleanup-12-3.sh 실행

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

### 0.1 사전 환경 구축의 목적

이 실습에서는 **AWS Backup**을 사용하여 EC2 인스턴스를 자동으로 백업하고 복원하는 방법을 학습합니다. 이를 위해 다음과 같은 환경이 필요합니다:

**구축되는 인프라:**
- **VPC 네트워크**: 격리된 네트워크 환경에서 EC2 인스턴스를 실행합니다
- **EC2 인스턴스 (백업 대상)**: 웹 서버와 샘플 데이터가 포함된 테스트 인스턴스입니다
- **백업용 태그**: Project, Week, Purpose 태그로 백업 대상을 자동 식별합니다
- **IAM 백업 역할**: AWS Backup 서비스가 리소스를 백업/복원할 수 있는 권한을 제공합니다
- **샘플 데이터**: 백업 및 복원을 테스트할 수 있는 웹 페이지와 파일이 생성됩니다

**실습에서의 활용:**
- **태스크 1**: 생성된 EC2 인스턴스와 백업용 태그를 확인합니다
- **태스크 2**: AWS Backup 볼트를 생성하여 백업을 저장할 공간을 마련합니다
- **태스크 3**: 백업 계획을 생성하고 일정, 보관 기간, 태그 기반 선택을 설정합니다
- **태스크 4**: On-demand 백업을 실행하여 즉시 백업을 생성합니다
- **태스크 5**: 백업 작업을 모니터링하고 완료 상태를 확인합니다
- **태스크 6**: 백업에서 EC2 인스턴스를 복원하여 재해 복구를 테스트합니다

> [!TIP]
> 사전 환경 구축 스크립트는 백업 대상 인스턴스와 필요한 권한을 자동으로 준비하므로, 여러분은 AWS Backup의 핵심 백업/복원 기능 학습에만 집중할 수 있습니다.

### 0.2 환경 구축 실행

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

6. 스크립트 실행 중 생성 계획이 표시되면 내용을 확인하고 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

### 0.3 생성된 리소스 확인

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 유형 | 리소스 이름 | 실습에서의 역할 |
|------------|------------|----------------|
| VPC | CloudArchitect-Lab-VPC | EC2 인스턴스를 위한 격리된 네트워크 환경 |
| Public Subnet | CloudArchitect-Lab-Public-Subnet | EC2 인스턴스가 배치되는 서브넷 |
| Security Group | CloudArchitect-Lab-EC2-SG | HTTP(80), SSH(22) 트래픽 허용 |
| EC2 인스턴스 | CloudArchitect-Lab-TestInstance | 백업 대상 인스턴스 (웹 서버 + 샘플 데이터) |
| IAM 백업 역할 | CloudArchitect-Lab-BackupRole | AWS Backup 서비스 권한 제공 |
| 백업용 태그 | Project=CloudArchitect, Week=Week12-3 | 태그 기반 백업 대상 식별 |

8. 출력 메시지에서 EC2 인스턴스의 **Public IP 주소**를 확인하고 메모합니다.

9. 웹 브라우저에서 `http://[Public IP]`로 접속하여 백업 테스트용 웹 페이지가 표시되는지 확인합니다.

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

15. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Vaults**를 선택합니다.

16. 우측 상단의 [[Create new vault]] 버튼을 클릭합니다.

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

31. 백업 계획이 생성되면 **Assign resources** 페이지가 표시됩니다.

32. **Resource assignment name**에 `CloudArchitect-Lab-BackupSelection`을 입력합니다.

33. **IAM role**에서 **Choose an IAM role**을 선택한 후 `CloudArchitect-Lab-BackupRole`을 선택합니다.

34. **Define resource selection**에서 **Include specific resource types**를 선택합니다.

35. **Select specific resource types** 섹션의 **Select resource types** 드롭다운에서 **EC2**를 선택합니다. Instance IDs는 **All instances**로 유지합니다.

36. **Refine selection using tags** 섹션에서 [[Add tags]] 버튼을 클릭합니다.

37. 첫 번째 태그 조건을 설정합니다:
- **Key**: `Project`
- **Condition for value**: **Equals**
- **Value**: `CloudArchitect`

38. [[Add tags]] 버튼을 클릭하여 두 번째 태그 조건을 추가합니다:
- **Key**: `Week`
- **Condition for value**: **Equals**
- **Value**: `Week12-3`

39. [[Assign resources]] 버튼을 클릭합니다.

40. 확인 화면에서 [[Continue]] 버튼을 클릭합니다.

41. 리소스 할당이 완료되면 백업 계획 상세 페이지로 돌아갑니다.

> [!NOTE]
> 두 태그 조건은 AND 조건으로 동작합니다. `Project=CloudArchitect`와 `Week=Week12-3` 태그를 모두 가진 EC2 인스턴스만 백업 대상으로 선택됩니다. 이 방식을 사용하면 새 인스턴스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함되어 관리가 편리합니다.

✅ **태스크 완료**: 백업 계획이 생성되고 태그 기반으로 EC2 인스턴스가 백업 대상에 할당되었습니다.


## 태스크 4: 수동 백업 실행

> [!NOTE]
> 백업 계획은 설정된 스케줄에 따라 자동으로 실행되지만, 즉시 백업이 필요한 경우 수동(온디맨드) 백업을 실행할 수 있습니다. 이 태스크에서는 수동 백업을 실행하여 백업 프로세스를 직접 체험합니다.

41. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Protected resources**를 선택합니다.

42. [[Create on-demand backup]] 버튼을 클릭합니다.

43. **Resource type**에서 **EC2**를 선택합니다.

44. **Instance ID** 드롭다운에서 `CloudArchitect-Lab-TestInstance`의 인스턴스 ID를 선택합니다.

45. **Backup window**에서 **Create backup now**를 선택합니다 (기본값).

46. **Total retention period**를 `7` **Days**로 설정합니다.

47. **Backup vault** 드롭다운에서 `CloudArchitect-Lab-BackupVault`를 선택합니다.

48. **IAM role**에서 **Choose an IAM role**을 선택한 후 **Role name**에서 `CloudArchitect-Lab-BackupRole`을 선택합니다.

49. [[Create on-demand backup]] 버튼을 클릭합니다.

50. 왼쪽 메뉴에서 **Jobs**를 선택하고 **Backup jobs** 탭에서 백업 작업 상태를 확인합니다.

51. 백업 작업 상태가 "Completed"로 변경될 때까지 기다립니다.

> [!NOTE]
> EC2 인스턴스 백업에 약 10-15분이 소요됩니다. **Status** 열에서 "Created" → "Running" → "Completed" 순서로 진행됩니다. 페이지를 새로고침하여 상태를 확인합니다. 대기하는 동안 다음 태스크를 미리 읽어봅니다.

✅ **태스크 완료**: EC2 인스턴스의 수동 백업이 완료되었습니다.


## 태스크 5: 백업 복원 실습

> [!IMPORTANT]
> 태스크 4의 백업 작업이 "Completed" 상태여야 복원을 진행할 수 있습니다. Jobs 페이지에서 Status를 확인합니다.

51. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Protected resources**를 선택합니다.

52. 리소스 목록에서 `CloudArchitect-Lab-TestInstance`의 **Resource ID** 링크를 클릭합니다.

53. **Recovery points** 섹션에서 생성된 복구 시점의 라디오 버튼을 선택합니다.

54. [[Restore]] 버튼을 클릭합니다.

55. **Network settings** 섹션에서 다음 설정을 확인합니다:
- **Instance type**: `t3.micro` (원본과 동일)
- **VPC**: 원본 VPC 선택
- **Subnet**: 원본 서브넷 선택
- **Security groups**: 원본 보안 그룹 선택
- **Instance IAM role**: **Restore with original IAM role** 선택

56. **Restore role** 섹션에서 **Choose an IAM role**을 선택한 후 **Role name**에서 `CloudArchitect-Lab-BackupRole`을 선택합니다.

57. [[Restore backup]] 버튼을 클릭합니다.

> [!NOTE]
> EC2 인스턴스 복원에 약 5-10분이 소요됩니다. Jobs 페이지의 **Restore jobs** 탭에서 진행 상태를 확인합니다.

58. 복원이 완료되면 Amazon EC2 콘솔로 이동하여 새로 생성된 복원 인스턴스를 확인합니다.

> [!OUTPUT]
> ```
> EC2 인스턴스 목록에서 다음과 같이 두 개의 인스턴스가 표시됩니다:
>
> Name                              | Instance state | Instance type
> CloudArchitect-Lab-TestInstance   | Running        | t3.micro
> (복원된 인스턴스 - 이름 없음)       | Running        | t3.micro
> ```

59. 복원된 인스턴스의 **Public IPv4 address**를 복사합니다.

60. 새 브라우저 탭에서 `http://[복원된 인스턴스 IP]`로 접속합니다.

61. 원본 인스턴스와 동일한 웹 페이지가 표시되는지 확인합니다.

✅ **태스크 완료**: 백업에서 EC2 인스턴스가 성공적으로 복원되었습니다.

> [!TIP]
> AWS Backup 콘솔의 **Dashboard**에서 백업/복원 작업 현황과 성공률을 확인할 수 있습니다. 대시보드 데이터는 반영에 시간이 걸릴 수 있으므로, 즉시 작업 이력을 확인하려면 왼쪽 메뉴의 **Jobs**에서 **Backup jobs** / **Restore jobs** 탭을 활용합니다.


## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

> [!IMPORTANT]
> 정리 스크립트 실행 전에 AWS Backup 리소스를 먼저 삭제해야 합니다. 아래 순서대로 진행하세요.

**1단계: AWS Backup 리소스 삭제**

1. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

2. 왼쪽 메뉴에서 **Vaults**를 선택하고 `CloudArchitect-Lab-BackupVault`를 선택합니다.

3. **Recovery points** 목록에서 모든 복구 시점을 선택하고 **Actions** > **Delete**를 선택합니다.

4. 확인 창에서 [[Confirm]]을 클릭합니다.

5. 왼쪽 메뉴에서 **Backup plans**를 선택하고 `CloudArchitect-Lab-BackupPlan`을 선택합니다.

6. **Resource assignments** 섹션에서 `CloudArchitect-Lab-BackupSelection`을 선택하고 [[Delete]] 버튼을 클릭합니다.

7. 확인 필드에 `CloudArchitect-Lab-BackupSelection`을 입력하고 [[Delete resource assignment]]를 클릭합니다.

8. 우측 상단의 [[Delete]] 버튼을 클릭하고 확인 필드에 `CloudArchitect-Lab-BackupPlan`을 입력한 후 [[Delete plan]]을 클릭합니다.

9. 왼쪽 메뉴에서 **Vaults**를 선택하고 `CloudArchitect-Lab-BackupVault`를 선택합니다.

10. 우측 상단의 [[Delete vault]] 버튼을 클릭하고 확인 필드에 `confirm`을 입력한 후 [[Delete Backup vault]]를 클릭합니다.

> [!IMPORTANT]
> 태스크 5에서 복원한 EC2 인스턴스가 있다면 정리 스크립트 실행 전에 먼저 종료해야 합니다. EC2 콘솔에서 복원된 인스턴스를 선택하고 **Instance state** > **Terminate instance**를 실행합니다. 복원된 인스턴스가 VPC에 남아있으면 스크립트가 VPC를 삭제하지 못합니다.

**2단계: 정리 스크립트 실행**

10. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

11. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-12-3.sh
```

12. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

13. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - EC2 인스턴스 (`CloudArchitect-Lab-TestInstance`)
   - IAM 역할 (`CloudArchitect-Lab-BackupRole`)
   - Security Group, VPC 및 관련 리소스

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> AWS Backup 리소스는 복구 시점 → 백업 계획 → 백업 볼트 순서로 삭제해야 합니다.

#### 태스크 1: AWS Backup 복구 시점 삭제

1. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

2. 왼쪽 메뉴에서 **Vaults**를 선택합니다.

3. `CloudArchitect-Lab-BackupVault`를 선택합니다.

4. **Recovery points** 목록에서 모든 복구 시점을 선택하고 **Actions** > **Delete**를 선택합니다.

5. 확인 창에서 [[Confirm]]을 클릭합니다.

> [!NOTE]
> 복구 시점 삭제에는 약 1-2분이 소요될 수 있습니다.

#### 태스크 2: AWS Backup 계획 삭제

6. 왼쪽 메뉴에서 **Backup plans**를 선택합니다.

7. `CloudArchitect-Lab-BackupPlan`을 선택합니다.

8. **Resource assignments** 섹션에서 `CloudArchitect-Lab-BackupSelection`을 선택하고 [[Delete]] 버튼을 클릭합니다.

9. 확인 필드에 `CloudArchitect-Lab-BackupSelection`을 입력하고 [[Delete resource assignment]]를 클릭합니다.

10. 우측 상단의 [[Delete]] 버튼을 클릭하고 확인 필드에 `CloudArchitect-Lab-BackupPlan`을 입력한 후 [[Delete plan]]을 클릭합니다.

#### 태스크 3: AWS Backup 볼트 삭제

11. 왼쪽 메뉴에서 **Vaults**를 선택합니다.

12. `CloudArchitect-Lab-BackupVault`를 선택합니다.

13. 우측 상단의 [[Delete vault]] 버튼을 클릭하고 확인 필드에 `confirm`을 입력한 후 [[Delete Backup vault]]를 클릭합니다.

#### 태스크 4: Amazon EC2 인스턴스 종료

14. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

15. 왼쪽 메뉴에서 **Instances**를 선택합니다.

16. `CloudArchitect-Lab-TestInstance` 인스턴스와 복원된 인스턴스를 모두 선택합니다.

17. **Instance state** > **Terminate instance**를 선택합니다.

18. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 5: Security Group 및 Amazon VPC 삭제

19. EC2 인스턴스 종료 후, 왼쪽 메뉴의 **Security Groups**에서 `CloudArchitect-Lab-EC2-SG`를 삭제합니다.

20. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

21. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

22. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

23. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

24. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

25. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

26. [[Search resources]]를 클릭합니다.

27. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

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
