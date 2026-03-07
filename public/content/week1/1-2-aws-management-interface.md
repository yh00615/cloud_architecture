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

> [!DOWNLOAD]
> [week1-2-aws-management-interface.zip](/files/week1/week1-2-aws-management-interface.zip)
>
> - `lab01-check.sh` - AWS 환경 정보 확인 스크립트 (계정 정보, 리전, 가용 영역 조회)
> - 태스크 0: CloudShell에서 스크립트 업로드

> [!NOTE]
> 이 실습은 AWS Management Console과 AWS CLI 사용법을 학습합니다. 콘솔 기본 사용법, CLI 기본 명령어 체험, 콘솔과 CLI의 차이점을 이해합니다. 리소스를 생성하지 않으므로 비용이 발생하지 않습니다.

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

1. 위 DOWNLOAD 섹션에서 `week1-2-aws-management-interface.zip` 파일을 다운로드합니다.

2. 다운로드한 `week1-2-aws-management-interface.zip` 파일의 압축을 해제합니다.

3. AWS Management Console에 로그인합니다.

4. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

5. CloudShell이 처음 실행되는 경우 환경 초기화를 기다립니다.

> [!NOTE]
> CloudShell 첫 실행 시 환경 초기화에 약 1-2분이 소요됩니다. "Waiting for environment to run..." 메시지가 표시되며, 완료되면 명령어 프롬프트(`$`)가 나타납니다.

6. CloudShell 상단의 **Actions** > `Upload file`을 선택하여 압축 해제한 `lab01-check.sh` 파일을 업로드합니다.

> [!NOTE]
> CloudShell의 **Actions** 메뉴는 터미널 오른쪽 상단에 있습니다. Upload file을 선택하면 로컬 파일을 CloudShell 홈 디렉토리(`/home/cloudshell-user`)로 업로드할 수 있습니다.

7. 업로드가 완료되면 파일이 존재하는지 확인합니다:

```bash
ls -la lab01-check.sh
```

> [!OUTPUT]
> ```
> -rw-r--r-- 1 cloudshell-user cloudshell-user 612 ... lab01-check.sh
> ```

8. 스크립트에 실행 권한을 부여합니다:

```bash
chmod +x lab01-check.sh
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

10. **Language** 항목에서 드롭다운을 선택하고 `English (US)`를 선택합니다.

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

18. `Asia Pacific (Seoul) ap-northeast-2`를 선택합니다.

> [!IMPORTANT]
> 리전 설정은 매우 중요합니다. 리전이 다르면 생성한 리소스가 보이지 않을 수 있습니다. 실습 전 항상 **Asia Pacific (Seoul) ap-northeast-2** 리전이 선택되어 있는지 확인합니다.

### 1.4 IAM 사용자 정보 확인

19. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

20. AWS IAM 콘솔이 열리면 왼쪽 메뉴에서 **Access management** 섹션 아래의 **Users**를 선택합니다.

21. 현재 로그인한 사용자가 목록에 있는지 확인합니다.

22. 사용자명을 선택하여 상세 정보 페이지로 이동합니다.

23. **Summary** 섹션에서 다음 정보를 확인합니다:
- **User ARN**: 사용자의 고유 식별자 (예: `arn:aws:iam::123456789012:user/사용자명`)
- **Creation time**: 사용자 생성 일시
- **Last activity**: 마지막 활동 시간

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
./lab01-check.sh
```

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

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: AWS IAM 리소스 삭제

1. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

2. 왼쪽 메뉴에서 **Roles**를 선택합니다.

3. 실습에서 생성한 역할을 선택합니다.

4. **Delete** 버튼을 클릭합니다.

5. 확인 창에 역할 이름을 입력하고 [[Delete]] 버튼을 클릭합니다.

6. 왼쪽 메뉴에서 **Policies**를 선택합니다.

7. 실습에서 생성한 정책을 선택합니다.

8. **Actions** > **Delete**를 선택합니다.

9. 확인 창에 정책 이름을 입력하고 [[Delete]] 버튼을 클릭합니다.

10. 왼쪽 메뉴에서 **Users**를 선택합니다.

11. 실습에서 생성한 사용자를 선택합니다.

12. 사용자에 연결된 정책을 먼저 제거합니다:
   - **Permissions** 탭 선택
   - 정책 선택 후 **Remove** 클릭

13. **Delete user** 버튼을 클릭합니다.

14. 확인 창에 사용자 이름을 입력하고 [[Delete]] 버튼을 클릭합니다.

### 태스크 2: 최종 확인

1. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

2. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

3. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

4. [[Search resources]]를 클릭합니다.

5. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

6. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🖥️
AWS Management Console
웹 브라우저에서 GUI로 AWS 서비스를 관리하는 인터페이스입니다. 리전 설정, 계정 정보 확인 등 기본 작업을 수행합니다.

🔄
콘솔과 CLI의 관계
동일한 AWS 계정에 대해 콘솔(GUI)과 CLI(명령어) 두 가지 방식으로 접근할 수 있으며, 동일한 결과를 확인할 수 있습니다.
