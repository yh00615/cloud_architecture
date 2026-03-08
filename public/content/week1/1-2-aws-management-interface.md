---
title: 'AWS 관리 인터페이스'
week: 1
session: 2
awsServices:
  - AWS CloudShell
  - AWS IAM
learningObjectives:
  - AWS Management Console의 기본 구성과 계정/리전 정보를 확인할 수 있습니다.
  - AWS CloudShell 환경을 활용하여 파일 업로드 및 CLI 명령을 실행할 수 있습니다.
  - AWS CLI의 기본 명령어를 사용하여 계정 정보를 조회하고 콘솔 결과와 비교할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **AWS**를 관리하는 두 가지 방법을 학습합니다. 먼저 웹 브라우저 기반의 **AWS Management Console**에서 **리전**을 확인하고 **계정 정보**를 조회합니다. 그 다음 **AWS CloudShell**에서 **CLI 명령어**를 실행하여 동일한 정보를 확인합니다. 마지막으로 **--output**과 **--query** 옵션을 사용하여 출력 형식을 제어하고 필요한 데이터만 추출하는 방법을 익힙니다. 리소스를 생성하지 않으므로 비용이 발생하지 않습니다.

> [!DOWNLOAD]
> [week1-2-aws-management-interface.zip](/files/week1/week1-2-aws-management-interface.zip)
>
> - `setup-1-2.sh` - AWS 환경 정보 확인 스크립트 (계정 정보, 리전, 가용 영역 조회)
> - 태스크 0: CloudShell에서 스크립트 업로드

> [!CONCEPT] AWS 관리 인터페이스란?
>
> AWS는 클라우드 리소스를 관리하기 위해 세 가지 주요 인터페이스를 제공합니다.
>
> - **AWS Management Console**: 웹 브라우저에서 GUI로 AWS 서비스를 관리하는 인터페이스입니다
> - **AWS CLI(Command Line Interface)**: 터미널에서 명령어로 AWS 서비스를 제어하는 도구입니다
> - **AWS CloudShell**: 브라우저 내에서 AWS CLI가 사전 설치된 터미널 환경을 제공합니다
>
> 이 실습에서는 Console과 CloudShell(CLI)을 함께 사용하여 동일한 정보를 두 가지 방식으로 확인합니다.

## 태스크 0: 실습 파일 준비

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week1-2-aws-management-interface.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인합니다.

3. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

4. CloudShell이 처음 실행되는 경우 환경 초기화를 기다립니다.

> [!NOTE]
> CloudShell 첫 실행 시 환경 초기화에 약 1-2분이 소요됩니다. "Waiting for environment to run..." 메시지가 표시되며, 완료되면 명령어 프롬프트가 나타납니다.

5. CloudShell 상단의 **Actions** → **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

> [!NOTE]
> CloudShell의 **Actions** 메뉴는 터미널 오른쪽 상단에 있습니다. Upload file을 선택하면 로컬 파일을 CloudShell 홈 디렉토리(`/home/cloudshell-user`)로 업로드할 수 있습니다.

6. 업로드가 완료되면 다음 명령어를 실행합니다:

```bash
unzip week1-2-aws-management-interface.zip
```

7. 압축 해제된 파일이 존재하는지 확인합니다:

```bash
ls -la setup-1-2.sh
```

> [!OUTPUT]
> ```
> -rw-r--r-- 1 cloudshell-user cloudshell-user 828 ... setup-1-2.sh
> ```

8. 스크립트에 실행 권한을 부여합니다:

```bash
chmod +x setup-1-2.sh
```

✅ **태스크 완료**: 실습 파일이 CloudShell에 업로드되고 실행 준비가 완료되었습니다.


## 태스크 1: AWS 콘솔에서 기본 정보 확인

> [!CONCEPT] AWS 계정 구조
>
> - **AWS 계정**: AWS 서비스를 사용하는 최상위 단위로, 12자리 숫자 ID로 식별됩니다. 모든 리소스와 비용이 이 계정에 귀속됩니다.
> - **IAM 사용자**: 계정 내에서 생성된 개별 사용자로, 특정 권한을 가지고 AWS 서비스에 접근합니다.
> - **Federated user**: SSO나 외부 자격 증명 공급자를 통해 임시로 로그인한 사용자입니다.
>
> 하나의 AWS 계정 안에 여러 IAM 사용자와 역할을 생성하여 팀원별로 다른 권한을 부여할 수 있습니다.

### 1.1 콘솔 언어 설정

9. 상단 내비게이션 바에서 톱니바퀴(⚙) 아이콘을 선택합니다.

10. **Language** 항목에서 드롭다운을 선택하고 **English (US)**를 선택합니다.

11. 콘솔 인터페이스가 영어로 변경되는 것을 확인합니다.

> [!TIP]
> AWS 콘솔을 영어로 설정하면 공식 문서, 블로그, 커뮤니티 자료와 메뉴명이 일치하여 학습 효율이 높아집니다. 실무에서도 영어 인터페이스 사용을 권장합니다.

### 1.2 계정 및 사용자 정보 확인

12. 내비게이션 바 오른쪽 상단에서 현재 로그인한 **계정 이름 또는 번호**를 선택합니다.

13. 드롭다운 메뉴에서 다음 정보를 확인합니다:
- **Account ID**: 12자리 숫자 (예: `1234-5678-9012`)
- **Account name**: 계정 이름
- **Federated user** 또는 **IAM user**: 현재 로그인한 사용자 정보

14. 드롭다운 하단의 **Account**를 선택하여 계정 상세 정보 페이지로 이동합니다.

15. 계정 설정 페이지에서 계정 이름, 연락처 정보 등을 확인합니다.

### 1.3 리전 확인 및 변경

16. 내비게이션 바에서 현재 표시된 **리전 이름**을 선택합니다.

17. 드롭다운에서 사용 가능한 AWS 리전 목록을 확인합니다.

18. **Asia Pacific (Seoul) ap-northeast-2**를 선택합니다.

> [!IMPORTANT]
> 리전 설정은 매우 중요합니다. 리전이 다르면 생성한 리소스가 보이지 않을 수 있습니다. 실습 전 항상 **Asia Pacific (Seoul) ap-northeast-2** 리전이 선택되어 있는지 확인합니다.

### 1.4 IAM 사용자 정보 확인

19. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

20. AWS IAM 콘솔이 열리면 왼쪽 메뉴에서 **Access management** 섹션 아래의 **Users**를 선택합니다.

21. 현재 로그인한 사용자가 목록에 있는지 확인합니다.

22. 사용자명을 선택하여 상세 정보 페이지로 이동합니다.

23. **Summary** 섹션에서 다음 정보를 확인합니다:
- **User ARN**: 사용자의 고유 식별자 (예: `arn:aws:iam::123456789012:user/사용자명`)
- **Console access**: 콘솔 접근 권한 및 MFA 활성화 여부
- **Access key**: 생성된 액세스 키 개수 및 상태
- **Created**: 사용자 생성 일시
- **Last console sign-in**: 마지막 콘솔 로그인 시간

> [!TIP]
> IAM 사용자로 로그인한 경우 **Users** 목록에서 확인 가능하고, IAM 역할로 로그인한 경우 왼쪽 메뉴의 **Access management** 섹션 아래의 **Roles** 메뉴에서 확인할 수 있습니다. 현재 로그인 방식에 따라 확인 위치가 다릅니다.

✅ **태스크 완료**: AWS 콘솔에서 계정 정보, 리전 설정, IAM 사용자 정보를 확인했습니다.


## 태스크 2: AWS CloudShell에서 CLI 명령어 실행

> [!CONCEPT] AWS CloudShell이란?
>
> AWS CloudShell은 브라우저에서 바로 사용할 수 있는 터미널 환경입니다.
>
> - AWS CLI가 **사전 설치**되어 있어 별도 설치가 필요 없습니다
> - 로그인한 사용자의 **자격 증명이 자동 설정**되어 별도 인증이 불필요합니다
> - 홈 디렉토리(`/home/cloudshell-user`)에 최대 1GB까지 파일을 저장할 수 있습니다
> - Python, Node.js, Git 등 개발 도구도 사전 설치되어 있습니다
>
> 로컬 PC에 AWS CLI를 설치하지 않아도 CloudShell에서 바로 AWS 리소스를 관리할 수 있어 실습 환경에 적합합니다.

### 2.1 실습 스크립트 실행

24. CloudShell 터미널에서 태스크 0에서 업로드한 스크립트를 실행합니다:

```bash
./setup-1-2.sh
```

> [!TIP]
> CloudShell은 리전별로 독립적인 환경을 제공합니다. 태스크 0에서 파일을 업로드한 후 리전을 변경했다면, 현재 리전의 CloudShell에는 파일이 없을 수 있습니다. 이 경우 현재 리전에서 CloudShell을 다시 열고 파일을 재업로드해야 합니다.

> [!OUTPUT]
> ```
> ============================================
>  CloudArchitect Lab01 - AWS 환경 정보 확인
> ============================================
>
> [1] 기본 리전: ap-northeast-2 (서울) 설정 완료
>
> [2] 계정 정보:
> {
>     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
>     "Account": "123456789012",
>     "Arn": "arn:aws:iam::123456789012:user/사용자명"
> }
>
> [3] 현재 리전:
> ap-northeast-2
>
> [4] 사용 가능한 리전 목록:
> (리전 목록 테이블)
>
> ============================================
>  환경 정보 확인 완료
> ============================================
> ```

25. 출력 결과에서 다음 정보를 확인합니다:
- **Account**: 12자리 AWS 계정 ID (태스크 1에서 콘솔로 확인한 값과 동일)
- **Arn**: 현재 로그인한 사용자/역할의 ARN
- **Region**: ap-northeast-2 (서울)

> [!TIP]
> 콘솔에서 확인한 계정 ID와 CLI 출력의 Account 값이 동일한지 비교합니다. 동일한 AWS 계정에 대해 콘솔과 CLI 두 가지 방식으로 접근하고 있음을 확인할 수 있습니다.

### 2.2 출력 형식 비교

26. JSON 형식으로 계정 정보를 확인합니다:

```bash
aws sts get-caller-identity --output json
```

> [!OUTPUT]
> ```json
> {
>     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
>     "Account": "123456789012",
>     "Arn": "arn:aws:iam::123456789012:user/사용자명"
> }
> ```

27. 테이블 형식으로 동일한 정보를 확인합니다:

```bash
aws sts get-caller-identity --output table
```

> [!OUTPUT]
> ```
> ---------------------------------------------------------
> |                   GetCallerIdentity                    |
> +-----------+---------------------+----------------------+
> |  Account  |        Arn          |       UserId         |
> +-----------+---------------------+----------------------+
> | 123456789012 | arn:aws:iam::...  | AIDAXXXXXXXX...     |
> +-----------+---------------------+----------------------+
> ```

28. 텍스트 형식으로 동일한 정보를 확인합니다:

```bash
aws sts get-caller-identity --output text
```

> [!OUTPUT]
> ```
> 123456789012    arn:aws:iam::123456789012:user/사용자명    AIDAXXXXXXXXXXXXXXXXX
> ```

> [!NOTE]
> AWS CLI는 세 가지 출력 형식을 지원합니다: `json`(구조화된 데이터, 기본값), `table`(사람이 읽기 쉬운 표), `text`(셸 스크립트 처리용). 용도에 따라 `--output` 옵션으로 선택합니다. 자동화 스크립트에서는 `text`나 `json`이, 수동 확인에는 `table`이 편리합니다.

### 2.3 쿼리 필터링

> [!NOTE]
> `--query` 옵션을 사용하면 AWS CLI 응답에서 필요한 정보만 추출할 수 있습니다. 복잡한 JSON 응답 전체를 읽지 않아도 되므로 자동화 스크립트 작성 시 매우 유용합니다.

29. `--query` 옵션으로 계정 ID만 추출합니다:

```bash
aws sts get-caller-identity --query 'Account' --output text
```

> [!OUTPUT]
> ```
> 123456789012
> ```

30. 현재 리전의 가용 영역을 확인합니다:

```bash
aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output table
```

> [!OUTPUT]
> ```
> ----------------------------
> |DescribeAvailabilityZones |
> +--------------------------+
> |  ap-northeast-2a         |
> |  ap-northeast-2b         |
> |  ap-northeast-2c         |
> |  ap-northeast-2d         |
> +--------------------------+
> ```

> [!TIP]
> `--query` 옵션은 JMESPath 문법을 사용합니다. 복잡한 JSON 응답에서 필요한 정보만 추출할 때 유용합니다. 예를 들어 `--query 'Reservations[].Instances[].InstanceId'`로 인스턴스 ID만 추출할 수 있습니다.

✅ **태스크 완료**: AWS CLI의 다양한 출력 형식과 쿼리 필터링을 사용하여 콘솔과 동일한 정보를 확인했습니다.

## 💡 핵심 포인트 정리

🖥️
AWS Management Console
웹 브라우저에서 GUI로 AWS 서비스를 관리하는 인터페이스로, 직관적으로 리소스를 생성하고 설정할 수 있습니다.

☁️
AWS CloudShell
브라우저 기반 셸 환경으로 AWS CLI가 사전 설치되어 있어 별도 설정 없이 바로 명령어를 실행할 수 있습니다.

🔄
콘솔과 CLI의 관계
동일한 AWS 계정에 대해 콘솔(GUI)과 CLI(명령어) 두 가지 방식으로 접근할 수 있으며, 동일한 결과를 확인할 수 있습니다.

📋
출력 형식 제어
--output 옵션으로 json, table, text 형식을 선택하여 데이터를 다양한 방식으로 확인할 수 있습니다.

🔍
JMESPath 쿼리
--query 옵션으로 JSON 응답에서 필요한 데이터만 필터링하여 추출할 수 있습니다.

🌐
리전 개념
AWS 서비스는 전 세계 여러 리전에 분산되어 있으며, 리소스는 특정 리전에 생성되므로 올바른 리전 선택이 중요합니다.

