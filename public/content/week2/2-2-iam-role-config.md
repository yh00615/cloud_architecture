---
title: 'IAM 역할 구성'
week: 2
session: 2
awsServices:
  - AWS IAM
  - AWS STS
learningObjectives:
  - AWS IAM 역할의 개념과 다양한 유형을 이해할 수 있습니다.
  - AWS IAM 역할을 활용하여 서비스 간 안전한 접근을 구성할 수 있습니다.
  - AWS IAM 권한 경계(Permission Boundary)의 개념과 활용 방법을 이해할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **IAM 역할**을 생성하고 **EC2 인스턴스**에 연결하는 방법을 학습합니다. **Trust Policy**로 EC2 서비스가 역할을 사용할 수 있도록 허용하고, **Permission Policy**로 **S3**와 **CloudWatch Logs** 접근 권한을 부여합니다. **Instance Profile**을 통해 역할을 EC2에 연결한 후, 인스턴스 내부에서 액세스 키 없이 AWS 서비스에 접근합니다. 마지막으로 **권한 경계**를 설정하여 역할이 가질 수 있는 최대 권한을 제한합니다.

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다.

> [!CONCEPT] IAM 역할이란?
>
> IAM 역할은 AWS 서비스나 사용자가 **임시로 권한을 부여받는** 방식입니다.
>
> - **IAM 사용자**: 영구적인 액세스 키를 가진 개별 사용자 계정입니다
> - **IAM 역할**: 임시 자격 증명을 제공하며, 자동으로 만료되어 보안이 강화됩니다
> - **Trust Policy**: 누가 이 역할을 사용(assume)할 수 있는지 정의합니다
> - **Permission Policy**: 역할이 어떤 작업을 수행할 수 있는지 정의합니다
>
> 역할은 Trust Policy + Permission Policy 두 가지가 모두 있어야 작동합니다.

## 태스크 1: AWS IAM 역할 개념 이해

> [!CONCEPT] 역할의 두 가지 정책
>
> IAM 역할은 **Trust Policy**와 **Permission Policy** 두 가지 정책으로 구성됩니다.
>
> - **Trust Policy**: "누가" 이 역할을 assume할 수 있는지 정의합니다. `Principal` 요소에 AWS 서비스(예: `ec2.amazonaws.com`)나 사용자 ARN을 지정합니다.
> - **Permission Policy**: 역할이 assume된 후 "무엇을" 할 수 있는지 정의합니다. S3 읽기, DynamoDB 쓰기 등 구체적인 작업 권한을 부여합니다.
>
> Trust Policy가 없으면 아무도 역할을 사용할 수 없고, Permission Policy가 없으면 역할을 사용해도 아무 작업도 할 수 없습니다.

### 1.1 AWS IAM 역할 vs 사용자 차이점 확인

1. AWS Management Console에 로그인한 후 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

2. IAM 콘솔이 열리면 왼쪽 메뉴에서 **Access management** 섹션 아래의 **Users**를 선택하여 기존 사용자 목록을 확인합니다.

3. 왼쪽 메뉴에서 **Access management** 섹션 아래의 **Roles**를 선택하여 기존 역할 목록을 확인합니다.

4. 역할 목록에서 `AWSServiceRole`로 시작하는 AWS 서비스 역할들을 확인합니다.

> [!TIP]
> AWS 서비스 역할은 AWS가 자동으로 생성한 역할입니다. 예를 들어 `AWSServiceRoleForSupport`는 AWS Support 서비스가 사용하는 역할입니다. 이러한 역할은 삭제하지 않도록 주의합니다.

### 1.2 기존 역할의 구조 분석

5. 역할 목록에서 AWS 서비스 역할 중 하나를 선택합니다.

6. **Trust relationships** 탭을 선택하여 Trust Policy JSON을 확인합니다.

> [!NOTE]
> Trust Policy는 **"누가"** 이 역할을 사용할 수 있는지 정의합니다. Principal 요소에서 어떤 AWS 서비스나 계정이 이 역할을 assume할 수 있는지 확인할 수 있습니다. 이후 태스크에서 역할을 생성할 때 이 구조를 참고하게 됩니다.

7. **Permissions** 탭을 선택하여 연결된 Permission Policy를 확인합니다.

> [!NOTE]
> Permission Policy는 역할이 **"무엇을"** 할 수 있는지 정의합니다. 역할을 assume한 후 실제로 수행할 수 있는 AWS 작업들이 여기에 명시되어 있습니다. 이후 태스크에서 커스텀 정책을 생성하고 역할에 연결하게 됩니다.

✅ **태스크 완료**: IAM 역할의 구조(Trust Policy + Permission Policy)를 확인했습니다.


## 태스크 2: 커스텀 S3 정책 생성

> [!CONCEPT] IAM 정책 JSON 구조
>
> IAM 정책은 JSON 형식으로 작성되며, 다음 핵심 요소로 구성됩니다:
>
> - **Version**: 정책 언어 버전입니다. 항상 `"2012-10-17"`을 사용합니다
> - **Statement**: 하나 이상의 권한 규칙을 배열로 정의합니다
> - **Effect**: `Allow`(허용) 또는 `Deny`(거부)를 지정합니다
> - **Action**: 허용/거부할 AWS API 작업입니다 (예: `s3:GetObject`, `s3:PutObject`)
> - **Resource**: 정책이 적용되는 대상 리소스의 ARN입니다. `*`는 모든 리소스를 의미합니다
>
> 하나의 정책에 여러 Statement를 포함하여 복합적인 권한 규칙을 정의할 수 있습니다.

### 2.1 S3 읽기 전용 정책 생성

8. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **Policies**를 선택합니다.

9. [[Create policy]] 버튼을 클릭합니다.

10. **Policy editor** 섹션에서 **JSON** 탭을 선택합니다.

11. 기존 JSON 내용을 모두 삭제하고 다음 정책 문서를 입력합니다:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::cloudarchitect-lab-*",
                "arn:aws:s3:::cloudarchitect-lab-*/*"
            ]
        }
    ]
}
```

> [!NOTE]
> 이 정책은 `cloudarchitect-lab-`로 시작하는 S3 버킷에 대해서만 `GetObject`(객체 읽기)와 `ListBucket`(버킷 목록 조회) 권한을 부여합니다. 다른 버킷에는 접근할 수 없어 최소 권한 원칙을 따릅니다.

12. [[Next]] 버튼을 클릭합니다.

13. **Policy name** 필드에 `CloudArchitect-Lab-S3ReadOnly`를 입력합니다.

14. **Description** 필드에 `Lab S3 read-only policy`를 입력합니다.

15. [[Create policy]] 버튼을 클릭합니다.

✅ **정책 생성 완료**: CloudArchitect-Lab-S3ReadOnly 정책이 생성되었습니다.

### 2.2 S3 전체 접근 정책 생성

16. [[Create policy]] 버튼을 클릭합니다.

17. **JSON** 탭을 선택하고 다음 정책 문서를 입력합니다:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::cloudarchitect-lab-*",
                "arn:aws:s3:::cloudarchitect-lab-*/*"
            ]
        }
    ]
}
```

> [!NOTE]
> `s3:*`는 S3에 대한 모든 작업(읽기, 쓰기, 삭제 등)을 허용합니다. 단, Resource에서 `cloudarchitect-lab-*` 버킷으로 범위를 제한하고 있습니다.

18. [[Next]] 버튼을 클릭합니다.

19. **Policy name** 필드에 `CloudArchitect-Lab-S3FullAccess`를 입력합니다.

20. **Description** 필드에 `Lab S3 full access policy`를 입력합니다.

21. [[Create policy]] 버튼을 클릭합니다.

✅ **정책 생성 완료**: CloudArchitect-Lab-S3FullAccess 정책이 생성되었습니다.

### 2.3 CloudWatch 로그 정책 생성

22. [[Create policy]] 버튼을 클릭합니다.

23. **JSON** 탭을 선택하고 다음 정책 문서를 입력합니다:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

> [!NOTE]
> 이 정책은 Lambda 함수가 실행 로그를 CloudWatch Logs에 기록하기 위해 필요합니다. 로그 그룹 생성, 로그 스트림 생성, 로그 이벤트 기록 권한을 포함합니다.

24. [[Next]] 버튼을 클릭합니다.

25. **Policy name** 필드에 `CloudArchitect-Lab-CloudWatchLogs`를 입력합니다.

26. **Description** 필드에 `Lab CloudWatch logs policy`를 입력합니다.

27. [[Create policy]] 버튼을 클릭합니다.

✅ **태스크 완료**: 커스텀 정책 3개(S3ReadOnly, S3FullAccess, CloudWatchLogs)가 생성되었습니다.


## 태스크 3: Amazon EC2-S3 역할 생성

> [!CONCEPT] EC2 인스턴스와 IAM 역할
>
> EC2 인스턴스에서 S3에 접근하려면 IAM 역할을 연결해야 합니다. 역할을 연결하면 EC2 내부의 애플리케이션이 **액세스 키 없이** 자동으로 임시 자격 증명을 받아 S3에 접근할 수 있습니다. 이때 역할은 **Instance Profile**이라는 컨테이너를 통해 EC2에 연결됩니다.

### 3.1 Amazon EC2 역할 생성 시작

28. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **Roles**를 선택합니다.

29. [[Create role]] 버튼을 클릭합니다.

30. **Trusted entity type**에서 **AWS service**를 선택합니다.

31. **Service or use case** 드롭다운에서 **EC2**를 선택합니다.

32. **Use case**에서 **EC2**를 선택합니다.

33. [[Next]] 버튼을 클릭합니다.

> [!TIP]
> AWS service → EC2를 선택하면 자동으로 Trust Policy에 `"Service": "ec2.amazonaws.com"`이 설정됩니다. 이는 EC2 서비스만 이 역할을 assume할 수 있다는 의미입니다.

### 3.2 커스텀 정책 연결

34. **Add permissions** 페이지에서 검색창에 `CloudArchitect-Lab-S3ReadOnly`를 입력합니다.

35. **CloudArchitect-Lab-S3ReadOnly** 정책 옆의 체크박스를 체크합니다.

36. [[Next]] 버튼을 클릭합니다.

### 3.3 역할 이름 및 생성

37. **Role name** 필드에 `CloudArchitect-Lab-EC2-S3ReadOnly`를 입력합니다.

38. **Description** 필드에 `Lab EC2 S3 read-only role`을 입력합니다.

39. 설정을 검토한 후 [[Create role]] 버튼을 클릭합니다.

✅ **태스크 완료**: CloudArchitect-Lab-EC2-S3ReadOnly 역할이 생성되었습니다. EC2 인스턴스가 이 역할을 사용하여 S3에 읽기 접근할 수 있습니다.


## 태스크 4: AWS Lambda-S3 역할 생성

> [!CONCEPT] Lambda 함수와 IAM 역할
>
> Lambda 함수는 실행될 때마다 지정된 IAM 역할의 권한을 사용합니다. Lambda 역할에는 일반적으로 두 가지 권한이 필요합니다:
>
> - **비즈니스 로직 권한**: S3, DynamoDB 등 함수가 접근해야 하는 서비스 권한
> - **로깅 권한**: CloudWatch Logs에 실행 로그를 기록하는 권한 (디버깅에 필수)

### 4.1 AWS Lambda 역할 생성 시작

40. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **Roles**를 선택합니다.

41. [[Create role]] 버튼을 클릭합니다.

42. **Trusted entity type**에서 **AWS service**를 선택합니다.

43. **Use case**에서 **Lambda**를 선택합니다.

44. [[Next]] 버튼을 클릭합니다.

### 4.2 커스텀 정책 연결

45. 검색창에 `CloudArchitect-Lab-S3FullAccess`를 입력하고 체크박스를 체크합니다.

46. 검색창을 지우고 `CloudArchitect-Lab-CloudWatchLogs`를 입력하고 체크박스를 체크합니다.

47. 두 정책이 모두 선택되었는지 확인하고 [[Next]] 버튼을 클릭합니다.

### 4.3 AWS Lambda 역할 이름 및 생성

48. **Role name** 필드에 `CloudArchitect-Lab-Lambda-S3FullAccess`를 입력합니다.

49. **Description** 필드에 `Lab Lambda S3 full access role`을 입력합니다.

50. 설정을 검토한 후 [[Create role]] 버튼을 클릭합니다.

✅ **태스크 완료**: CloudArchitect-Lab-Lambda-S3FullAccess 역할이 생성되었습니다. Lambda 함수가 S3에 전체 접근하고 CloudWatch에 로그를 기록할 수 있습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: IAM 역할 삭제

1. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

2. 왼쪽 메뉴에서 **Roles**를 선택합니다.

3. 검색창에 `CloudArchitect-Lab`을 입력하여 실습에서 생성한 역할들을 필터링합니다.

4. **CloudArchitect-Lab-EC2-S3ReadOnly** 역할 옆의 체크박스를 체크합니다.

5. [[Delete]] 버튼을 클릭합니다.

6. 확인 창에 `CloudArchitect-Lab-EC2-S3ReadOnly`를 입력하고 [[Delete]] 버튼을 클릭합니다.

7. 검색창에 `CloudArchitect-Lab-Lambda-S3FullAccess`를 입력합니다.

8. **CloudArchitect-Lab-Lambda-S3FullAccess** 역할 옆의 체크박스를 체크합니다.

9. [[Delete]] 버튼을 클릭합니다.

10. 확인 창에 `CloudArchitect-Lab-Lambda-S3FullAccess`를 입력하고 [[Delete]] 버튼을 클릭합니다.

### 태스크 2: IAM 정책 삭제

11. 왼쪽 메뉴에서 **Policies**를 선택합니다.

12. **Filter by Type** 드롭다운을 클릭하고 **Customer managed**를 선택합니다.

13. 검색창에 `CloudArchitect-Lab-S3ReadOnly`를 입력합니다.

14. **CloudArchitect-Lab-S3ReadOnly** 정책 옆의 체크박스를 체크합니다.

15. [[Delete]] 버튼을 클릭합니다.

16. 확인 창에 `CloudArchitect-Lab-S3ReadOnly`를 입력하고 [[Delete]] 버튼을 클릭합니다.

17. 검색창에 `CloudArchitect-Lab-S3FullAccess`를 입력합니다.

18. **CloudArchitect-Lab-S3FullAccess** 정책 옆의 체크박스를 체크합니다.

19. [[Delete]] 버튼을 클릭합니다.

20. 확인 창에 `CloudArchitect-Lab-S3FullAccess`를 입력하고 [[Delete]] 버튼을 클릭합니다.

21. 검색창에 `CloudArchitect-Lab-CloudWatchLogs`를 입력합니다.

22. **CloudArchitect-Lab-CloudWatchLogs** 정책 옆의 체크박스를 체크합니다.

23. [[Delete]] 버튼을 클릭합니다.

24. 확인 창에 `CloudArchitect-Lab-CloudWatchLogs`를 입력하고 [[Delete]] 버튼을 클릭합니다.

✅ **리소스 정리 완료**: 모든 IAM 역할과 정책이 삭제되었습니다.


## 💡 핵심 포인트 정리

🎭
IAM 역할의 개념
IAM 사용자는 영구 자격 증명을 사용하지만, IAM 역할은 임시 자격 증명을 제공하여 보안성이 높습니다.

🔐
Trust Policy와 Permission Policy
Trust Policy는 "누가" 역할을 사용할 수 있는지, Permission Policy는 "무엇을" 할 수 있는지를 정의합니다.

🖥️
Instance Profile
EC2 인스턴스가 IAM 역할을 사용하려면 Instance Profile을 통해 역할을 연결해야 합니다.

🔄
역할 전환(Assume Role)
AWS STS(Security Token Service)를 통해 임시 자격 증명을 발급받아 역할을 사용합니다.

📏
권한 경계(Permission Boundary)
역할이 가질 수 있는 최대 권한을 제한하여, 실수로 과도한 권한이 부여되는 것을 방지합니다.

🛡️
서비스 간 안전한 접근
액세스 키를 코드에 하드코딩하지 않고 IAM 역할을 사용하여 AWS 서비스 간 안전하게 통신합니다.
