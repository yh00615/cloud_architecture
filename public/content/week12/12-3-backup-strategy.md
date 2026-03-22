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
chmod +x setup-12-3.sh cleanup-12-3.sh
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

### 1.1 Amazon EC2 인스턴스 확인

10. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

11. Amazon EC2 콘솔의 왼쪽 메뉴에서 **Instances** 섹션 아래의 **Instances**를 선택합니다.

12. `CloudArchitect-Lab-TestInstance` 인스턴스의 상태가 "Running"인지 확인합니다.

13. 인스턴스를 선택하고 하단 **Details** 탭에서 다음 정보를 메모장에 복사합니다 (태스크 5 복원 시 필요):
- **Public IPv4 address**: 웹 서버 접속 확인용
- **VPC ID**: `vpc-` 로 시작하는 값
- **Subnet ID**: `subnet-` 으로 시작하는 값

14. 하단의 **Security** 탭을 선택하여 **Security groups** 이름을 확인합니다:
- **CloudArchitect-Lab-EC2-SG** (`sg-` 로 시작하는 ID)

> [!TIP]
> VPC ID, Subnet ID, Security Group 정보는 태스크 5에서 백업을 복원할 때 동일한 네트워크 환경을 지정하기 위해 필요합니다. 지금 메모해두면 복원 시 빠르게 진행할 수 있습니다.

15. 하단의 **Tags** 탭을 선택하여 백업용 태그를 확인합니다:
- **Project**: `CloudArchitect`
- **Week**: `Week12-3`
- **Purpose**: `Backup-Test`

> [!NOTE]
> 이 태그들은 태스크 3에서 AWS Backup이 백업 대상 리소스를 자동으로 식별하는 데 사용됩니다. 태그 기반 선택을 사용하면 새 리소스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함됩니다.

### 1.2 웹 서버 동작 확인

16. 새 브라우저 탭을 열고 `http://[복사한 Public IP]`로 접속하여 웹 페이지가 표시되는지 확인합니다.

> [!OUTPUT]
> ```
> 브라우저에 백업 테스트용 웹 페이지가 표시됩니다.
> 이 페이지는 백업 후 복원된 인스턴스에서도 동일하게 표시되어야 합니다.
> ```

> [!TROUBLESHOOTING]
> 페이지가 로드되지 않는 경우:
> - 인스턴스 생성 후 2-3분 대기합니다 (웹서버 설치 및 시작 중)
> - 주소가 `https://`가 아닌 `http://`로 시작하는지 확인합니다
> - 인스턴스를 선택하고 **Security** 탭에서 보안 그룹을 클릭하여 **Inbound rules**에 HTTP(80) 규칙이 있는지 확인합니다

✅ **태스크 완료**: EC2 인스턴스와 웹 서버가 정상 작동하고 있습니다.


## 태스크 2: AWS Backup 볼트 생성

> [!CONCEPT] 백업 볼트(Backup Vault)란?
>
> 백업 볼트는 백업 데이터를 저장하는 **암호화된 컨테이너**입니다. 볼트를 별도로 생성하면 백업 데이터를 논리적으로 분리하여 관리할 수 있고, 볼트별로 다른 암호화 키와 접근 정책을 적용할 수 있습니다.
>
> - **기본 볼트**: AWS Backup은 `Default` 볼트를 제공하지만, 프로젝트별로 별도 볼트를 생성하는 것이 관리에 유리합니다
> - **암호화**: 볼트에 저장되는 모든 백업 데이터는 KMS 키로 암호화됩니다
> - **접근 정책**: 볼트별로 IAM 정책을 적용하여 백업 데이터에 대한 접근을 제어할 수 있습니다

17. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

18. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Vaults**를 선택합니다.

> [!NOTE]
> 기본적으로 `Default` 볼트가 이미 존재합니다. 이 실습에서는 프로젝트 전용 볼트를 새로 생성하여 백업 데이터를 분리 관리합니다.

19. [[Create backup vault]] 버튼을 클릭합니다.

20. 다음과 같이 설정합니다:
- **Vault name**: `CloudArchitect-Lab-BackupVault`
- **Vault type**: **Backup vault** (기본값 유지)
- **Encryption key** 섹션의 **Choose KMS key**: 기본 AWS 관리형 키 `(default) aws/backup` 유지

21. [[Create vault]] 버튼을 클릭합니다.

> [!OUTPUT]
> ```
> 볼트 생성이 완료되면 볼트 상세 페이지로 이동합니다.
> 
> Vault name: CloudArchitect-Lab-BackupVault
> Vault type: Backup vault
> Encryption key: aws/backup
> Recovery points: 0 (아직 백업이 없음)
> ```

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

22. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Backup plans**를 선택합니다.

23. [[Create backup plan]] 버튼을 클릭합니다.

24. **Start options** 섹션에서 **Build a new plan**을 선택합니다.

25. **Backup plan name**에 `CloudArchitect-Lab-BackupPlan`을 입력합니다.

### 3.2 백업 규칙 설정

26. **Backup rule configuration** 섹션에서 다음과 같이 설정합니다:
- **Backup rule name**: `DailyBackups`
- **Backup vault**: 드롭다운에서 `CloudArchitect-Lab-BackupVault` 선택

27. **Backup frequency**를 `Daily`로 설정합니다.

28. **Backup window** 섹션에서 **Start time**은 기본값을 유지합니다.

> [!NOTE]
> Backup window는 백업이 시작되는 시간대를 지정합니다. 기본값은 UTC 기준으로 설정되어 있으며, 프로덕션 환경에서는 트래픽이 적은 시간대로 설정하는 것이 좋습니다.

29. **Lifecycle** 섹션에서 **Total retention period**를 `7 days`로 설정합니다.

> [!TIP]
> 보존 기간(Retention period)은 백업 데이터를 유지하는 기간입니다. 7일로 설정하면 7일이 지난 백업은 자동으로 삭제되어 스토리지 비용을 절약할 수 있습니다. 프로덕션 환경에서는 규정 준수 요구사항에 따라 30일, 90일 등으로 설정합니다.

30. [[Create plan]] 버튼을 클릭합니다.

### 3.3 리소스 할당

> [!NOTE]
> 백업 계획이 생성되면 자동으로 백업 계획 상세 페이지로 이동합니다. 이제 이 백업 계획에 어떤 리소스를 백업할지 지정해야 합니다.

31. 백업 계획 상세 페이지의 **Resource assignments** 섹션에서 [[Assign resources]] 버튼을 클릭합니다.

32. **Resource assignment name**에 `CloudArchitect-Lab-BackupSelection`을 입력합니다.

33. **IAM role** 섹션에서 **Choose an IAM role**을 선택합니다. 드롭다운에서 `CloudArchitect-Lab-BackupRole`을 선택합니다.

> [!NOTE]
> IAM 역할은 AWS Backup 서비스가 EC2 인스턴스에 접근하여 백업을 수행할 수 있는 권한을 부여합니다. 사전 구축 스크립트에서 이미 생성되어 있습니다.

34. **Define resource selection** 섹션에서 **Include specific resource types**를 선택합니다.

35. **Select specific resource types** 섹션이 나타나면, **Select resource types** 드롭다운을 클릭하고 **EC2**를 선택합니다.

36. **Refine selection using tags** 섹션에서 [[Add condition]] 버튼을 클릭합니다.

37. 첫 번째 태그 조건을 다음과 같이 설정합니다:
- **Key**: `Project`
- **Condition for value**: **Equals**
- **Value**: `CloudArchitect`

38. [[Add condition]] 버튼을 다시 클릭하여 두 번째 태그 조건을 추가합니다:
- **Key**: `Week`
- **Condition for value**: **Equals**
- **Value**: `Week12-3`

39. [[Assign resources]] 버튼을 클릭합니다.

> [!NOTE]
> 두 태그 조건은 AND 조건으로 동작합니다. `Project=CloudArchitect`와 `Week=Week12-3` 태그를 모두 가진 EC2 인스턴스만 백업 대상으로 선택됩니다. 이 방식을 사용하면 새 인스턴스에 동일한 태그만 추가하면 자동으로 백업 대상에 포함되어 관리가 편리합니다.

40. 리소스 할당이 완료되면 백업 계획 상세 페이지로 돌아갑니다. **Resource assignments** 섹션에 `CloudArchitect-Lab-BackupSelection`이 표시되는지 확인합니다.

✅ **태스크 완료**: 백업 계획이 생성되고 태그 기반으로 EC2 인스턴스가 백업 대상에 할당되었습니다.


## 태스크 4: 수동 백업 실행

> [!CONCEPT] 온디맨드 백업 vs 예약 백업
>
> AWS Backup은 두 가지 방식으로 백업을 실행할 수 있습니다:
>
> - **예약 백업**: 백업 계획에 설정된 스케줄에 따라 자동으로 실행됩니다 (태스크 3에서 설정한 Daily 백업)
> - **온디맨드 백업**: 즉시 백업이 필요한 경우 수동으로 실행합니다 (예: 중요한 변경 전 백업)
>
> 이 태스크에서는 온디맨드 백업을 실행하여 백업 프로세스를 직접 체험합니다. 예약 백업은 설정된 시간까지 기다려야 하므로, 실습에서는 온디맨드 백업을 사용합니다.

41. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Protected resources**를 선택합니다.

42. [[Create on-demand backup]] 버튼을 클릭합니다.

43. **Resource type** 드롭다운에서 **EC2**를 선택합니다.

44. **Instance ID** 드롭다운을 클릭하면 현재 리전의 EC2 인스턴스 목록이 표시됩니다. `CloudArchitect-Lab-TestInstance`를 선택합니다.

> [!NOTE]
> Instance ID 드롭다운에 인스턴스가 표시되지 않는 경우, Resource type이 **EC2**로 올바르게 선택되었는지 확인합니다. 또한 EC2 인스턴스가 "Running" 상태인지 EC2 콘솔에서 확인합니다.

45. **Backup window** 섹션에서 **Create backup now**가 선택되어 있는지 확인합니다.

46. **Total retention period**를 `7` **Days**로 설정합니다.

47. **Backup vault** 드롭다운에서 `CloudArchitect-Lab-BackupVault`를 선택합니다.

48. **IAM role** 섹션에서 **Choose an IAM role**을 선택한 후 `CloudArchitect-Lab-BackupRole`을 선택합니다.

49. [[Create on-demand backup]] 버튼을 클릭합니다.

### 4.1 백업 작업 모니터링

50. 백업이 시작되면 자동으로 **Jobs** 페이지로 이동합니다. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Jobs**를 선택하여 이동할 수도 있습니다.

51. **Backup jobs** 탭에서 방금 생성한 백업 작업을 확인합니다.

> [!OUTPUT]
> ```
> Backup jobs 탭에서 다음과 같은 정보가 표시됩니다:
>
> Backup job ID    | Status   | Resource type | Resource ID                      | Backup vault
> xxxxxxxx-xxxx... | Running  | EC2           | i-0abc1234def56789               | CloudArchitect-Lab-BackupVault
>
> Status 변화 순서: Created → Running → Completed
> ```

52. 백업 작업 상태가 "Completed"로 변경될 때까지 기다립니다. 페이지 우측 상단의 새로고침 아이콘(🔄)을 주기적으로 클릭하여 상태를 확인합니다.

> [!IMPORTANT]
> EC2 인스턴스 백업에 약 10-15분이 소요됩니다. **Status**가 "Completed"로 변경되어야 태스크 5의 복원을 진행할 수 있습니다. 대기하는 동안 태스크 5의 내용을 미리 읽어봅니다.

> [!TROUBLESHOOTING]
> 백업 작업이 "Failed" 상태인 경우:
> - **IAM role** 권한 문제: `CloudArchitect-Lab-BackupRole`이 올바르게 선택되었는지 확인합니다
> - **EC2 인스턴스 상태**: 인스턴스가 "Running" 상태인지 EC2 콘솔에서 확인합니다
> - 백업 작업의 **Status message**를 클릭하여 상세 오류 메시지를 확인합니다

✅ **태스크 완료**: EC2 인스턴스의 수동 백업이 완료되었습니다.


## 태스크 5: 백업 복원 실습

> [!IMPORTANT]
> 태스크 4의 백업 작업이 "Completed" 상태여야 복원을 진행할 수 있습니다. 왼쪽 메뉴의 **Jobs** > **Backup jobs** 탭에서 Status가 "Completed"인지 반드시 확인합니다.

### 5.1 복구 시점 선택

53. AWS Backup 콘솔의 왼쪽 메뉴에서 **My account** 섹션 아래의 **Vaults**를 선택합니다.

54. `CloudArchitect-Lab-BackupVault`를 선택합니다.

55. **Recovery points** 섹션에서 생성된 복구 시점이 표시되는지 확인합니다. 복구 시점의 **Recovery point ID**를 클릭합니다.

56. 복구 시점 상세 페이지에서 **Backup status**가 "Completed"인지 확인한 후 [[Restore]] 버튼을 클릭합니다.

### 5.2 복원 설정

> [!NOTE]
> 복원 설정에서는 원본 인스턴스와 동일한 네트워크 환경(VPC, 서브넷, 보안 그룹)을 지정해야 합니다. 태스크 1에서 메모한 정보를 사용합니다.

57. **Network settings** 섹션에서 다음과 같이 설정합니다:
- **Instance type**: `t3.micro` (원본과 동일한 값이 자동 선택되어 있는지 확인)
- **VPC**: 드롭다운에서 `CloudArchitect-Lab-VPC`를 선택합니다 (태스크 1에서 메모한 VPC ID 참고)
- **Subnet**: 드롭다운에서 `CloudArchitect-Lab-Public-Subnet`을 선택합니다 (태스크 1에서 메모한 Subnet ID 참고)
- **Security groups**: 드롭다운에서 `CloudArchitect-Lab-EC2-SG`를 선택합니다 (태스크 1에서 메모한 Security Group ID 참고)

> [!TIP]
> 드롭다운에서 리소스를 찾기 어려운 경우, 태스크 1에서 메모한 ID 값(예: `vpc-0abc1234`, `subnet-0def5678`)을 검색 필드에 입력하면 빠르게 찾을 수 있습니다.

58. **Restore role** 섹션에서 **Choose an IAM role**을 선택한 후 `CloudArchitect-Lab-BackupRole`을 선택합니다.

59. 나머지 설정은 기본값을 유지하고 [[Restore backup]] 버튼을 클릭합니다.

### 5.3 복원 작업 모니터링

60. 복원이 시작되면 왼쪽 메뉴에서 **My account** 섹션 아래의 **Jobs**를 선택합니다.

61. **Restore jobs** 탭을 선택하여 복원 작업의 진행 상태를 확인합니다.

> [!OUTPUT]
> ```
> Restore jobs 탭에서 다음과 같은 정보가 표시됩니다:
>
> Restore job ID   | Status   | Resource type | Created resource ID
> xxxxxxxx-xxxx... | Running  | EC2           | (완료 후 표시됨)
>
> Status 변화 순서: Running → Completed
> ```

> [!NOTE]
> EC2 인스턴스 복원에 약 5-10분이 소요됩니다. 페이지 우측 상단의 새로고침 아이콘(🔄)을 주기적으로 클릭하여 상태를 확인합니다.

### 5.4 복원된 인스턴스 확인

62. 복원 작업 상태가 "Completed"로 변경되면, 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

63. 왼쪽 메뉴에서 **Instances** 섹션 아래의 **Instances**를 선택합니다.

> [!OUTPUT]
> ```
> EC2 인스턴스 목록에서 다음과 같이 두 개의 인스턴스가 표시됩니다:
>
> Name                              | Instance state | Instance type
> CloudArchitect-Lab-TestInstance   | Running        | t3.micro
> (복원된 인스턴스 - 이름 없음)       | Running        | t3.micro
> ```

64. 복원된 인스턴스 (이름이 없는 인스턴스)를 선택하고 하단 **Details** 탭에서 **Public IPv4 address**를 복사합니다.

> [!TROUBLESHOOTING]
> 복원된 인스턴스에 Public IP가 없는 경우:
> - 복원 시 **Subnet**을 퍼블릭 서브넷(`CloudArchitect-Lab-Public-Subnet`)으로 선택했는지 확인합니다
> - 인스턴스를 선택하고 **Actions** > **Networking** > **Manage IP addresses**에서 퍼블릭 IP 자동 할당을 확인합니다
> - 퍼블릭 IP가 할당되지 않은 경우, **Actions** > **Networking** > **Allocate Elastic IP address**로 탄력적 IP를 할당할 수 있습니다

65. 새 브라우저 탭에서 `http://[복원된 인스턴스 IP]`로 접속합니다.

66. 원본 인스턴스와 동일한 웹 페이지가 표시되는지 확인합니다.

> [!TIP]
> 원본 인스턴스(`http://[원본 IP]`)와 복원된 인스턴스(`http://[복원 IP]`)를 나란히 열어 동일한 콘텐츠가 표시되는지 비교해보세요. 백업 시점의 데이터가 정확히 복원되었음을 확인할 수 있습니다.

✅ **태스크 완료**: 백업에서 EC2 인스턴스가 성공적으로 복원되었습니다.


## 태스크 6: AWS Backup 대시보드 확인

> [!NOTE]
> AWS Backup 대시보드는 백업/복원 작업의 전체 현황을 한눈에 파악할 수 있는 모니터링 화면입니다. 프로덕션 환경에서는 이 대시보드를 주기적으로 확인하여 백업 실패 여부를 모니터링합니다.

67. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

68. AWS Backup 콘솔의 왼쪽 메뉴에서 **Dashboard**를 선택합니다.

### 6.1 백업 작업 현황 확인

69. **Backup jobs summary** 섹션에서 다음 항목을 확인합니다:
- **Completed**: 성공적으로 완료된 백업 작업 수 (최소 1개 이상)
- **Failed**: 실패한 백업 작업 수 (0이어야 정상)

70. **Restore jobs summary** 섹션에서 복원 작업 현황을 확인합니다:
- **Completed**: 성공적으로 완료된 복원 작업 수 (최소 1개 이상)

> [!OUTPUT]
> ```
> Dashboard에서 다음과 같은 요약 정보가 표시됩니다:
>
> Backup jobs summary:
>   Completed: 1 (태스크 4에서 실행한 온디맨드 백업)
>   Failed: 0
>
> Restore jobs summary:
>   Completed: 1 (태스크 5에서 실행한 복원)
> ```

### 6.2 보호된 리소스 확인

71. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Protected resources**를 선택합니다.

72. `CloudArchitect-Lab-TestInstance`가 보호된 리소스 목록에 표시되는지 확인합니다.

73. 해당 리소스를 선택하여 **Recovery points** 섹션에서 생성된 복구 시점의 **Status**가 "Available"인지 확인합니다.

> [!TIP]
> 프로덕션 환경에서는 AWS Backup 대시보드와 함께 다음과 같은 모니터링을 설정합니다:
> - **CloudWatch 연동**: 백업 실패 시 자동으로 SNS 알림을 받을 수 있습니다
> - **AWS Backup Audit Manager**: 백업 정책 준수 여부를 자동으로 감사합니다
> - **크로스 리전 백업**: 재해 복구를 위해 다른 리전에 백업을 복제할 수 있습니다

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

> [!IMPORTANT]
> 정리 스크립트는 사전 구축 스크립트로 생성한 리소스만 삭제합니다. 다음 리소스는 **수동으로 삭제**해야 합니다:
> - **복원된 EC2 인스턴스**: 태스크 5에서 복원한 인스턴스 (이름 없음)
> - **AWS Backup 리소스**: 백업 볼트, 백업 계획, 복구 시점
>
> 아래 수동 삭제 단계를 반드시 확인하세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> AWS Backup 리소스는 복구 시점 → 백업 계획 → 백업 볼트 순서로 삭제해야 합니다.

#### 태스크 1: AWS Backup 복구 시점 삭제

1. 상단 검색창에서 `AWS Backup`을 검색하고 **AWS Backup**을 선택합니다.

2. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Vaults**를 선택합니다.

3. `CloudArchitect-Lab-BackupVault`를 선택합니다.

4. **Recovery points** 목록에서 모든 복구 시점을 선택하고 **Actions** > **Delete**를 선택합니다.

5. 확인 필드에 `delete`를 입력하고 [[Delete recovery points]]를 클릭합니다.

> [!NOTE]
> 복구 시점 삭제에는 약 1-2분이 소요될 수 있습니다.

#### 태스크 2: AWS Backup 계획 삭제

6. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Backup plans**를 선택합니다.

7. `CloudArchitect-Lab-BackupPlan`을 선택합니다.

8. **Resource assignments** 섹션에서 `CloudArchitect-Lab-BackupSelection`의 체크박스를 선택하고 [[Delete]] 버튼을 클릭합니다.

> [!NOTE]
> 백업 계획을 삭제하기 전에 리소스 할당을 먼저 삭제해야 합니다. 리소스 할당이 남아있으면 백업 계획을 삭제할 수 없습니다.

9. 리소스 할당 삭제 후, 페이지 상단의 [[Delete]] 버튼을 클릭합니다.

10. 확인 필드에 백업 계획 이름 `CloudArchitect-Lab-BackupPlan`을 입력하고 [[Delete plan]]을 클릭합니다.

#### 태스크 3: AWS Backup 볼트 삭제

11. 왼쪽 메뉴에서 **My account** 섹션 아래의 **Vaults**를 선택합니다.

12. `CloudArchitect-Lab-BackupVault`를 선택합니다.

13. **Delete** 버튼을 클릭합니다.

14. 확인 필드에 `CloudArchitect-Lab-BackupVault`를 입력하고 [[Delete backup vault]]를 클릭합니다.

#### 태스크 4: Amazon EC2 인스턴스 종료

15. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

16. 왼쪽 메뉴에서 **Instances**를 선택합니다.

17. 다음 인스턴스를 모두 선택합니다:
- `CloudArchitect-Lab-TestInstance` (원본 인스턴스)
- 이름이 없는 인스턴스 (태스크 5에서 복원한 인스턴스)

> [!IMPORTANT]
> 복원된 인스턴스는 이름이 지정되어 있지 않으므로, Instance type이 `t3.micro`이고 최근에 생성된 인스턴스를 확인합니다. **Launch time** 열을 확인하여 복원 시점과 일치하는 인스턴스를 선택합니다.

18. **Instance state** > **Terminate instance**를 선택합니다.

19. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 5: Security Group 및 Amazon VPC 삭제

20. EC2 인스턴스 종료 후, 왼쪽 메뉴의 **Network & Security** 섹션 아래의 **Security Groups**에서 `CloudArchitect-Lab-EC2-SG`를 삭제합니다.

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
