---
title: 'IAM 사용자 및 정책 관리'
week: 2
session: 1
awsServices:
  - AWS IAM
learningObjectives:
  - AWS IAM 사용자와 그룹을 생성하고 관리할 수 있습니다.
  - AWS IAM 정책의 기본 구조(Effect, Action, Resource)를 이해하고 작성할 수 있습니다.
  - 자격 증명 기반 정책과 리소스 기반 정책의 차이를 구분할 수 있습니다.
---

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다.

> [!NOTE]
> 이 실습에서는 IAM 사용자, 그룹, 정책을 직접 생성하고 관리하여 AWS 보안 모델을 학습합니다. IAM 리소스는 비용이 발생하지 않습니다.

> [!CONCEPT] IAM(Identity and Access Management)이란?
>
> AWS IAM은 AWS 리소스에 대한 접근을 안전하게 제어하는 서비스입니다.
>
> - **사용자(User)**: 개별 사용자를 위한 AWS 자격 증명입니다. 콘솔 로그인용 비밀번호와 프로그래밍용 액세스 키를 제공합니다.
> - **그룹(Group)**: 여러 사용자를 묶어서 권한을 효율적으로 관리합니다. 그룹에 정책을 연결하면 모든 멤버에게 자동 적용됩니다.
> - **정책(Policy)**: JSON 형식의 권한 문서로, 누가 어떤 리소스에 어떤 작업을 할 수 있는지 정의합니다.
> - **최소 권한 원칙**: 작업 수행에 필요한 최소한의 권한만 부여하는 보안 원칙입니다.

## 태스크 1: AWS IAM 사용자 생성

> [!CONCEPT] IAM 사용자란?
>
> IAM 사용자는 AWS 계정 내에서 개별적으로 생성되는 자격 증명입니다. 각 사용자에게 고유한 로그인 정보와 권한을 부여할 수 있어, 팀원별로 필요한 리소스에만 접근하도록 제어할 수 있습니다.
>
> - **루트 사용자**: 계정 생성 시 만들어지는 최고 권한 사용자입니다. 일상 작업에는 사용하지 않는 것이 보안 모범 사례입니다
> - **IAM 사용자**: 특정 권한만 부여받은 개별 사용자입니다. 콘솔 로그인과 프로그래밍 방식 접근이 가능합니다
> - **최소 권한 원칙**: 작업 수행에 필요한 최소한의 권한만 부여하여 보안 위험을 줄입니다

1. AWS Management Console에 로그인한 후 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

2. IAM 콘솔이 열리면 왼쪽 메뉴에서 **Access management** 섹션 아래의 **Users**를 선택합니다.

3. [[Create user]] 버튼을 클릭합니다.

4. **User name** 필드에 `CloudArchitect-Lab-DeveloperUser`를 입력합니다.

5. **Provide user access to the AWS Management Console** 체크박스를 체크합니다.

6. **I want to create an IAM user**를 선택합니다.

7. [[Next]] 버튼을 클릭합니다.

8. **Permissions options**에서 **Attach policies directly**를 선택합니다.

9. 검색창에 `ReadOnlyAccess`를 입력하고 해당 정책 옆의 체크박스를 체크합니다.

> [!NOTE]
> **ReadOnlyAccess**는 AWS 관리형 정책으로, 거의 모든 AWS 서비스에 대한 읽기 전용 권한을 제공합니다. 리소스를 조회할 수 있지만 생성, 수정, 삭제는 할 수 없습니다.

10. [[Next]] 버튼을 클릭합니다.

11. 설정을 검토한 후 [[Create user]] 버튼을 클릭합니다.

12. 사용자 생성이 완료되면 **Console sign-in details** 페이지가 표시됩니다.

13. **Console sign-in URL**과 **Username**을 복사하여 메모장에 저장합니다.

> [!IMPORTANT]
> Console sign-in URL은 이 페이지를 벗어나면 다시 확인하기 어렵습니다. 반드시 메모장에 저장합니다.

14. [[Return to users list]] 버튼을 클릭합니다.

✅ **태스크 완료**: CloudArchitect-Lab-DeveloperUser 사용자가 ReadOnlyAccess 권한과 함께 생성되었습니다.


## 태스크 2: AWS IAM 그룹 생성

> [!CONCEPT] 그룹 기반 권한 관리
>
> IAM에서는 개별 사용자에게 직접 정책을 연결하는 것보다 **그룹을 통해 권한을 관리**하는 것이 모범 사례입니다.
>
> - 사용자가 그룹에 추가되면 그룹의 모든 정책을 자동으로 상속받습니다
> - 권한 변경 시 그룹 정책만 수정하면 모든 멤버에게 즉시 반영됩니다
> - 사용자가 그룹에서 제거되면 그룹 권한이 자동으로 해제됩니다

### 2.1 그룹 생성 시작

15. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **User groups**를 선택합니다.

16. [[Create group]] 버튼을 클릭합니다.

17. **Group name** 필드에 `CloudArchitect-Lab-Developers`를 입력합니다.

> [!TIP]
> 그룹 이름은 계정 내에서 고유해야 합니다. 팀이나 역할 기반으로 이름을 지정하면 관리가 편리합니다 (예: Developers, Admins, ReadOnly-Users).

### 2.2 정책 연결

18. **Attach permissions policies** 섹션에서 검색창에 `ReadOnlyAccess`를 입력합니다.

19. `ReadOnlyAccess` 정책 옆의 체크박스를 체크합니다.

20. [[Create user group]] 버튼을 클릭합니다.

### 2.3 사용자를 그룹에 추가

21. 생성된 그룹 목록에서 **CloudArchitect-Lab-Developers**를 선택합니다.

22. **Users** 탭을 선택합니다.

23. [[Add users]] 버튼을 클릭합니다.

24. **CloudArchitect-Lab-DeveloperUser** 사용자를 체크합니다.

25. [[Add users]] 버튼을 클릭합니다.

✅ **태스크 완료**: 사용자가 그룹에 추가되었습니다. 이제 사용자는 그룹의 권한을 상속받습니다.


## 태스크 3: 고객 관리형 정책 생성

> [!CONCEPT] AWS 관리형 정책 vs 고객 관리형 정책
>
> - **AWS 관리형 정책**: AWS가 미리 만들어 제공하는 정책입니다 (예: ReadOnlyAccess, AmazonS3FullAccess). 편리하지만 세밀한 제어가 어렵습니다.
> - **고객 관리형 정책**: 사용자가 직접 JSON으로 작성하는 정책입니다. 특정 리소스에 대한 세밀한 권한 제어가 가능합니다.
>
> 실무에서는 최소 권한 원칙에 따라 고객 관리형 정책을 작성하여 필요한 리소스에만 접근을 허용합니다.

### 3.1 정책 생성

26. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **Policies**를 선택합니다.

27. [[Create policy]] 버튼을 클릭합니다.

28. 상단의 **JSON** 탭을 선택합니다.

29. 기존 JSON 내용을 모두 삭제하고 다음 정책 문서를 입력합니다:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::cloudarchitect-lab-*/*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::cloudarchitect-lab-*"
    }
  ]
}
```

> [!NOTE]
> 이 정책의 구조를 살펴보면:
>
> - **Version**: 정책 언어 버전입니다. 항상 `"2012-10-17"`을 사용합니다.
> - **Effect**: `Allow`(허용) 또는 `Deny`(거부)를 지정합니다.
> - **Action**: 허용할 AWS API 작업을 지정합니다 (`s3:GetObject`, `s3:PutObject`, `s3:ListBucket`).
> - **Resource**: 정책이 적용되는 대상 리소스의 ARN입니다. `cloudarchitect-lab-*`로 시작하는 버킷에만 적용됩니다.

30. [[Next]] 버튼을 클릭합니다.

31. **Policy name** 필드에 `CloudArchitect-Lab-S3-Limited-Access`를 입력합니다.

32. **Description** 필드에 `Lab practice - Limited S3 access policy`를 입력합니다.

33. [[Create policy]] 버튼을 클릭합니다.

✅ **정책 생성 완료**: CloudArchitect-Lab-S3-Limited-Access 정책이 생성되었습니다.

### 3.2 그룹에 정책 연결

34. IAM 콘솔에서 왼쪽 메뉴의 **Access management** 섹션 아래의 **User groups**를 선택합니다.

35. **CloudArchitect-Lab-Developers** 그룹을 선택합니다.

36. **Permissions** 탭을 선택합니다.

37. [[Add permissions]] 버튼을 클릭한 후 드롭다운에서 **Attach policies**를 선택합니다.

> [!NOTE]
> **Add permissions** 버튼은 **Permissions** 탭 오른쪽 상단에 있습니다. 클릭하면 "Attach policies", "Create inline policy" 등의 옵션이 표시됩니다.

38. 검색창에 `CloudArchitect-Lab-S3-Limited-Access`를 입력합니다.

39. 생성한 정책 옆의 체크박스를 체크합니다.

40. [[Attach policies]] 버튼을 클릭합니다.

> [!TIP]
> 그룹의 **Permissions** 탭에서 현재 연결된 정책 목록을 확인할 수 있습니다. ReadOnlyAccess와 CloudArchitect-Lab-S3-Limited-Access 두 개의 정책이 표시되어야 합니다.

✅ **태스크 완료**: 그룹에 고객 관리형 정책이 추가로 연결되었습니다. 이제 그룹 멤버는 ReadOnlyAccess + S3 제한된 쓰기 권한을 가집니다.


## 태스크 4: 권한 테스트 및 검증

> [!CONCEPT] IAM 정책 시뮬레이터
>
> 정책 시뮬레이터는 실제 리소스에 영향을 주지 않고 IAM 정책의 효과를 테스트할 수 있는 도구입니다. 특정 사용자가 특정 리소스에 대해 특정 작업을 수행할 수 있는지 미리 검증할 수 있어, 정책 배포 전 안전하게 테스트할 수 있습니다.

### 4.1 정책 시뮬레이터 사용

41. 새 브라우저 탭을 열고 주소창에 `https://policysim.aws.amazon.com/`을 입력하고 Enter를 누릅니다.

42. 정책 시뮬레이터가 열리면 왼쪽 **Users, Groups, and Roles** 패널에서 **Users**를 확장합니다.

43. `CloudArchitect-Lab-DeveloperUser` 사용자를 선택합니다.

44. 선택된 사용자에게 연결된 정책들이 오른쪽 **Policies** 패널에 표시되는 것을 확인합니다:
- **AWS Managed Policies**: ReadOnlyAccess
- **Customer Managed Policies**: CloudArchitect-Lab-S3-Limited-Access

### 4.2 허용되는 작업 테스트

45. **Policy Simulator** 섹션에서 **Select service** 드롭다운을 선택하고 `Amazon S3`를 선택합니다.

46. **Select actions** 드롭다운을 선택하고 `GetObject` 액션을 선택합니다.

47. 선택된 액션이 **Action Settings and Results** 목록에 나타나고 **Permission** 열에 "Not simulated"가 표시되는 것을 확인합니다.

48. GetObject 행의 왼쪽 화살표를 선택하여 행을 확장합니다.

49. **Resource ARN** 필드에 다음 ARN을 입력합니다:

```text
arn:aws:s3:::cloudarchitect-lab-test-bucket/test-file.txt
```

50. 오른쪽 상단의 [[Run Simulation]] 버튼을 클릭합니다.

51. 시뮬레이션 완료 후 GetObject 행의 **Permission** 열이 **allowed**로 표시되는 것을 확인합니다.

> [!OUTPUT]
> ```
> Action: s3:GetObject
> Resource: arn:aws:s3:::cloudarchitect-lab-test-bucket/test-file.txt
> Permission: allowed
> ```

52. **allowed** 옆의 **matching statement(s)** 링크를 선택하여 어떤 정책이 이 액션을 허용했는지 확인합니다.

### 4.3 거부되는 작업 테스트

53. GetObject 행을 확장하고 **Resource ARN** 필드의 내용을 지운 후 다음 ARN을 입력합니다:

```text
arn:aws:s3:::other-bucket/test-file.txt
```

54. [[Run Simulation]] 버튼을 클릭합니다.

55. 시뮬레이션 완료 후 GetObject 행의 **Permission** 열이 **implicitDeny**로 표시되는 것을 확인합니다.

> [!OUTPUT]
> ```
> Action: s3:GetObject
> Resource: arn:aws:s3:::other-bucket/test-file.txt
> Permission: implicitDeny
> ```

> [!NOTE]
> `cloudarchitect-lab-*` 패턴에 맞지 않는 S3 버킷에 대한 접근은 **implicitDeny**(암시적 거부)로 거부됩니다. 어떤 정책도 해당 리소스에 대한 명시적 허용을 제공하지 않기 때문이며, 이것이 최소 권한 원칙의 실제 적용입니다.

### 4.4 사용자 권한 확인

56. IAM 콘솔로 이동합니다.

57. 왼쪽 메뉴에서 **Users**를 선택합니다.

58. **CloudArchitect-Lab-DeveloperUser** 사용자를 선택합니다.

59. **Permissions** 탭에서 사용자에게 적용된 모든 권한을 확인합니다.

60. **Groups** 탭에서 그룹 멤버십을 확인합니다.

> [!TIP]
> **Permissions** 탭에서 정책 이름 옆에 "Attached from group: CloudArchitect-Lab-Developers"라고 표시됩니다. 이는 해당 권한이 그룹을 통해 상속된 것임을 나타냅니다.

✅ **태스크 완료**: 정책 시뮬레이터로 허용/거부 동작을 검증하고, 사용자의 권한 상속 구조를 확인했습니다.

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

📋
IAM 정책
JSON 형식의 권한 문서로, Effect(Allow/Deny), Action(작업), Resource(대상 리소스)를 정의합니다.

🔒
최소 권한 원칙
사용자에게 작업 수행에 필요한 최소한의 권한만 부여하여 보안 위험을 최소화합니다.

🧪
정책 시뮬레이터
실제 리소스에 영향을 주지 않고 정책의 효과를 테스트하여 권한 설정 전 미리 검증할 수 있습니다.
