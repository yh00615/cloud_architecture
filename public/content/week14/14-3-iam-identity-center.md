---
title: 'IAM Identity Center 통합 인증'
week: 14
session: 3
awsServices:
  - AWS IAM Identity Center
learningObjectives:
  - 다중 계정 환경에서의 액세스 관리 과제와 해결 방안을 이해할 수 있습니다.
  - AWS IAM Identity Center의 주요 기능과 중앙 집중식 ID 관리 메커니즘을 파악할 수 있습니다.
  - AWS IAM Identity Center를 활용하여 SSO(Single Sign-On)를 구성할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **AWS IAM Identity Center**의 개념을 학습하고, **AWS Builder ID**를 사용하여 **Amazon Q Developer**를 IDE에 연동하는 실용적인 실습을 진행합니다. IAM Identity Center를 활성화하고 **사용자와 그룹**을 생성하여 **중앙 집중식 사용자 관리**를 체험합니다. 이어서 Amazon Q Developer를 **VS Code**에 설치하고, **코드 자동완성**, **AI 채팅**, **에이전트 코딩** 등 다양한 AI 코딩 어시스턴트 기능을 활용합니다.

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다

## 태스크 1: AWS IAM Identity Center 활성화

> [!CONCEPT] AWS IAM Identity Center란?
>
> AWS IAM Identity Center는 여러 AWS 계정과 애플리케이션에 대한 사용자 접근을 **중앙에서 관리**하는 서비스입니다.
>
> - **Single Sign-On(SSO)**: 한 번의 로그인으로 여러 AWS 계정과 애플리케이션에 접근합니다.
> - **중앙 집중식 사용자 관리**: 사용자와 그룹을 한 곳에서 생성하고 권한을 할당합니다.
> - **권한 세트(Permission Set)**: AWS 관리형 정책이나 사용자 정의 정책을 조합하여 접근 권한을 정의합니다.
>
> 기업 환경에서 계정별로 IAM 사용자를 개별 생성하는 대신, IAM Identity Center로 통합 관리하면 보안과 운영 효율성을 높일 수 있습니다.

1. AWS Management Console에 로그인한 후 상단 검색창에서 `IAM Identity Center`를 검색하고 **IAM Identity Center**를 선택합니다.

2. IAM Identity Center 콘솔이 열리면 중앙에 **Enable IAM Identity Center** 섹션이 표시됩니다. 설명을 확인한 후 [[Enable]] 버튼을 클릭합니다.

3. 활성화가 완료되면 IAM Identity Center 대시보드가 표시됩니다. 왼쪽 메뉴에 **Users**, **Groups**, **Permission sets** 등의 항목이 나타나는지 확인합니다.

> [!NOTE]
> IAM Identity Center 활성화 시 AWS Organizations가 함께 활성화됩니다. 이미 Organizations가 구성된 계정에서는 관리 계정에서만 활성화할 수 있습니다. 활성화는 한 번만 수행하면 되며, 이후에는 대시보드가 바로 표시됩니다.

> [!TROUBLESHOOTING]
> **Enable 버튼이 표시되지 않는 경우:**
> - 이미 IAM Identity Center가 활성화된 상태일 수 있습니다. 대시보드가 바로 표시되면 정상입니다.
> - "You must be signed in as the management account" 오류가 표시되면 현재 계정이 Organizations의 관리 계정이 아닙니다. 관리 계정으로 로그인하여 다시 시도합니다.
> - "AWS Organizations is already configured" 메시지가 표시되면 기존 Organizations 설정과 충돌할 수 있습니다. 강사에게 문의합니다.

✅ **태스크 완료**: IAM Identity Center가 활성화되었습니다.


## 태스크 2: AWS IAM Identity Center 사용자 및 그룹 관리

> [!CONCEPT] 사용자와 그룹 기반 접근 관리
>
> AWS IAM Identity Center에서는 **사용자(User)**와 **그룹(Group)**을 통해 접근 권한을 관리합니다.
>
> - **사용자**: 개별 로그인 계정으로, 이메일 주소를 기반으로 생성합니다.
> - **그룹**: 동일한 권한이 필요한 사용자들을 묶어 관리합니다 (예: Developers, Admins).
> - **권한 할당**: 그룹 단위로 권한을 할당하면 사용자 추가/제거 시 개별 권한 설정이 불필요합니다.
>
> 실무에서는 직무별 그룹을 생성하고 그룹에 권한을 할당하는 방식을 권장합니다.

### 2.1 사용자 생성

4. IAM Identity Center 콘솔의 왼쪽 메뉴에서 **Users**를 선택합니다.

5. 사용자 목록 페이지 오른쪽 상단의 [[Add user]] 버튼을 클릭합니다.

6. **Specify user details** 페이지에서 사용자 정보를 입력합니다:

   - **Username**: `test-developer`
   - **Email address**: 개인 이메일 주소 입력
   - **Confirm email address**: 동일한 이메일 주소를 한 번 더 입력
   - **First name**: `Test`
   - **Last name**: `Developer`

7. [[Next]] 버튼을 클릭합니다.

8. **Add user to groups** 단계에서 그룹을 선택하지 않고 [[Next]] 버튼을 클릭합니다.

> [!NOTE]
> 아직 그룹을 생성하지 않았으므로 이 단계에서는 건너뜁니다. 다음 단계에서 그룹을 생성한 후 사용자를 할당합니다.

9. **Review and add user** 페이지에서 입력한 정보를 확인한 후 [[Add user]] 버튼을 클릭합니다.

### 2.2 그룹 생성 및 사용자 할당

10. 왼쪽 메뉴에서 **Groups**를 선택합니다.

11. 그룹 목록 페이지 오른쪽 상단의 [[Create group]] 버튼을 클릭합니다.

12. **Create group** 페이지에서 그룹 정보를 입력합니다:

   - **Group name**: `Developers`
   - **Description**: `Development team group`

13. **Add users to group** 섹션에서 `test-developer` 사용자를 체크하여 그룹에 바로 추가할 수 있습니다.

14. [[Create group]] 버튼을 클릭하여 그룹을 생성합니다.

> [!TIP]
> 그룹 생성 페이지에서 바로 사용자를 추가할 수 있으므로, 별도로 그룹 상세 페이지에서 추가할 필요가 없습니다.

15. 생성된 `Developers` 그룹을 선택하고 **Users** 탭에서 `test-developer`가 할당되어 있는지 확인합니다.

> [!SUCCESS]
> Developers 그룹이 생성되고 test-developer 사용자가 할당되었습니다. 그룹을 통해 여러 사용자의 권한을 효율적으로 관리할 수 있습니다.

✅ **태스크 완료**: IAM Identity Center에서 사용자와 그룹을 생성하고 할당했습니다.


## 태스크 3: Amazon Q Developer 연결 방법 및 Builder ID 선택

> [!CONCEPT] Amazon Q Developer 접근 방식
>
> Amazon Q Developer에 접근하는 방법은 두 가지입니다.
>
> - **조직 환경**: IAM Identity Center를 통해 Amazon Q Business/Developer Pro를 구독하고 팀 전체를 중앙에서 관리합니다.
> - **개인 환경**: AWS Builder ID로 Amazon Q Developer에 무료로 접근하여 핵심 기능을 체험합니다.
>
> 이 실습에서는 무료인 Builder ID 방식을 사용합니다. 두 방식 모두 동일한 AI 코딩 어시스턴트 기능을 제공합니다.

16. AWS Builder ID는 개발자를 위한 개인 프로필로, Amazon Q Developer, AWS 교육 리소스, 커뮤니티 등에 접근할 수 있는 무료 계정입니다.

> [!NOTE]
> Builder ID의 주요 특징:
>
> - **무료 사용**: Builder ID는 무료로 생성하고 사용할 수 있습니다.
> - **개인 전용**: 사용자 본인만 사용 가능하며, 다른 사용자와 공유할 수 없습니다.
> - **IDE 및 터미널 전용**: AWS Management Console에서는 사용할 수 없습니다.
> - **사용량 제한**: 프리 티어에서는 사용량 제한이 적용됩니다.

> [!TIP]
> Builder ID 생성은 VS Code에서 Amazon Q 확장을 설치할 때 함께 진행됩니다. 별도로 미리 생성할 필요가 없습니다.

✅ **태스크 완료**: Amazon Q Developer 접근 방식을 이해하고 Builder ID 방식을 선택했습니다.


## 태스크 4: VS Code 및 Amazon Q Developer 확장 설치

> [!CONCEPT] Amazon Q Developer란?
>
> Amazon Q Developer는 AWS가 제공하는 **AI 기반 코딩 어시스턴트**입니다.
>
> - **코드 자동완성**: 주석이나 코드 컨텍스트를 기반으로 코드를 자동 생성합니다.
> - **AI 채팅**: 코드 설명, 디버깅, 최적화 등 개발 관련 질문에 답변합니다.
> - **코드 변환**: 다른 프로그래밍 언어로 코드를 변환합니다.
>
> VS Code 확장으로 설치하면 IDE 내에서 바로 AI 지원을 받을 수 있습니다.

17. VS Code가 설치되어 있지 않은 경우 VS Code 공식 사이트에서 다운로드하고 설치합니다.

18. VS Code를 실행하고 왼쪽 사이드바의 **Extensions** 아이콘(사각형 4개 모양)을 선택합니다.

19. Extensions 검색창에 `Amazon Q`를 입력합니다.

20. 검색 결과에서 **Amazon Q** 확장 (게시자: Amazon Web Services)을 찾아 [[Install]] 버튼을 클릭합니다.

> [!IMPORTANT]
> 여러 Amazon Q 관련 확장이 표시될 수 있습니다. 반드시 게시자가 "Amazon Web Services"인 공식 확장을 선택합니다. 게시자 이름은 확장 이름 아래에 표시됩니다.

21. 설치가 완료되면 VS Code를 재시작합니다.

22. 왼쪽 사이드바에서 Amazon Q 아이콘이 표시되는지 확인합니다.

> [!TROUBLESHOOTING]
> **Amazon Q 아이콘이 사이드바에 표시되지 않는 경우:**
> - VS Code를 완전히 종료한 후 다시 실행합니다.
> - Extensions 탭에서 Amazon Q가 "Enabled" 상태인지 확인합니다. "Disabled"로 표시되면 [[Enable]] 버튼을 클릭합니다.
> - VS Code 버전이 1.83.0 이상인지 확인합니다. **Help** > **About**에서 버전을 확인하고, 오래된 버전이면 업데이트합니다.

✅ **태스크 완료**: VS Code에 Amazon Q Developer 확장이 설치되었습니다.


## 태스크 5: Amazon Q Developer 인증 및 활성화

### 5.1 Builder ID로 인증

23. VS Code에서 왼쪽 사이드바의 **Amazon Q 아이콘**을 선택합니다.

24. Amazon Q 패널에서 [[Start]] 버튼을 클릭합니다.

25. 인증 방법 선택 화면에서 **Personal account - Free to start with a Builder ID**를 선택합니다.

26. 브라우저가 자동으로 열리면서 Builder ID 로그인 페이지가 표시됩니다.

27. Builder ID가 이미 있는 경우 이메일 주소를 입력하고 로그인합니다.

28. Builder ID가 없는 경우 [[Create AWS Builder ID]] 버튼을 클릭하여 다음 정보를 입력합니다:

   - 이메일 주소 입력
   - 이메일로 전송된 인증 코드 입력
   - 이름 입력
   - 비밀번호 설정 (8자 이상, 대소문자, 숫자, 특수문자 포함)

> [!TIP]
> Builder ID 생성 시 개인 이메일 사용을 권장합니다. 회사 이메일은 퇴사 시 접근이 불가능할 수 있습니다. Builder ID는 영구 무료이며 신용카드 등록이 불필요합니다.

### 5.2 VS Code 연동 승인

29. 브라우저에서 권한 승인 단계가 나타나면 [[Open]] 버튼을 클릭하여 VS Code 연동을 허용합니다.

30. 로그인 후 브라우저 창에서 액세스 허용을 선택합니다.

31. VS Code로 돌아가면 Amazon Q 패널에 "Connected" 상태가 표시됩니다. 채팅 입력창이 활성화되어 있는지 확인합니다.

> [!TROUBLESHOOTING]
> **브라우저가 자동으로 열리지 않는 경우:**
> - VS Code 하단 알림 영역에 표시된 인증 URL을 직접 복사하여 브라우저에 붙여넣습니다.
> - 팝업 차단이 활성화되어 있으면 브라우저 설정에서 팝업을 허용합니다.
>
> **"Connected" 상태가 표시되지 않는 경우:**
> - 브라우저에서 액세스 허용을 완료했는지 확인합니다. 브라우저 탭이 닫히지 않고 남아있다면 허용 버튼을 다시 클릭합니다.
> - VS Code를 재시작한 후 Amazon Q 패널에서 다시 로그인을 시도합니다.
> - 회사/학교 네트워크에서 특정 포트가 차단되어 있을 수 있습니다. 개인 네트워크(모바일 핫스팟 등)로 전환하여 시도합니다.

> [!SUCCESS]
> Amazon Q Developer가 Builder ID로 인증되어 활성화되었습니다. 이제 코드 자동완성과 AI 채팅 기능을 사용할 수 있습니다.

✅ **태스크 완료**: Builder ID로 Amazon Q Developer 인증이 완료되었습니다.


## 태스크 6: Amazon Q Developer 기능 체험

### 6.1 코드 자동완성

32. VS Code에서 새 파일을 생성하고 `hello.py`로 저장합니다.

33. 파일에 다음 주석을 입력합니다:

```python
# Create a function to calculate fibonacci numbers
# This function should return the nth fibonacci number
```

34. **Enter**를 눌러 새 줄로 이동하고 약 3-5초간 기다립니다. Amazon Q가 자동으로 코드를 제안합니다.

35. 제안된 코드가 회색으로 표시되면 **Tab** 키를 눌러 수락합니다. 추가 제안이 나타나면 계속 **Tab** 키로 수락합니다.

> [!TROUBLESHOOTING]
> **코드 제안이 나타나지 않는 경우:**
> - Amazon Q 패널에서 연결 상태가 "Connected"인지 확인합니다.
> - VS Code 우측 하단 상태 표시줄에서 Amazon Q 아이콘에 ⏸(일시정지) 표시가 있으면 클릭하여 자동완성을 활성화합니다.
> - 파일이 저장되어 있는지 확인합니다. 저장되지 않은 "Untitled" 파일에서는 자동완성이 작동하지 않을 수 있습니다.
> - 주석 입력 후 **Enter**를 눌러 빈 줄로 이동한 뒤 3-5초 기다립니다.

> [!OUTPUT]
> ```python
> def fibonacci(n):
>     if n <= 0:
>         return 0
>     elif n == 1:
>         return 1
>     else:
>         return fibonacci(n-1) + fibonacci(n-2)
> ```
>
> 실제 생성되는 코드는 다를 수 있습니다. Amazon Q는 컨텍스트에 따라 다양한 구현 방식을 제안합니다.

> [!TIP]
> 자동완성 단축키: **Tab**(수락), **Esc**(거부), **Alt+]**(다음 제안). 상세한 주석일수록 더 정확한 코드가 생성됩니다.

### 6.2 AI 채팅 기능

36. VS Code 왼쪽 사이드바의 **Amazon Q 아이콘**을 선택하여 채팅 패널을 엽니다.

37. 생성된 피보나치 함수 코드를 전체 선택하여 복사합니다.

38. Amazon Q 채팅창에 `이 코드를 설명해주세요`라고 입력하고 **Enter**를 누릅니다.

39. AI의 설명을 확인한 후, `이 코드를 더 효율적으로 만들어주세요`라고 요청합니다.

40. 다른 언어로도 테스트합니다: `이 함수를 JavaScript로 변환해주세요`

> [!SUCCESS]
> Amazon Q Developer의 코드 자동완성과 AI 채팅 기능을 체험했습니다. 코드 설명, 오류 탐지, 최적화, 언어 변환 등 다양한 개발 지원 기능을 활용할 수 있습니다.

✅ **태스크 완료**: Amazon Q Developer의 코드 자동완성과 AI 채팅 기능을 체험했습니다.


## 태스크 7: 실무 활용 시나리오

### 7.1 API 호출 코드 생성

41. 새 파일을 생성하고 `api_test.py`로 저장합니다.

42. Amazon Q 채팅창에 다음과 같이 요청합니다: `REST API를 호출하는 Python 코드를 작성해주세요. requests 라이브러리를 사용하고, GET과 POST 메서드 예시를 포함해주세요.`

43. 생성된 코드를 복사하여 파일에 붙여넣고 저장합니다.

44. 추가로 `에러 처리와 타임아웃 설정도 추가해주세요`라고 요청하여 더 완성도 높은 코드를 받아봅니다.

### 7.2 테스트 코드 생성

45. 앞서 생성한 피보나치 함수 코드를 복사합니다.

46. Amazon Q에게 `다음 함수에 대한 pytest 단위 테스트 코드를 작성해주세요`라고 요청하고 함수 코드를 붙여넣습니다.

47. 새 파일 `test_fibonacci.py`를 생성하고 생성된 테스트 코드를 저장합니다.

### 7.3 코드 리뷰 및 최적화

48. 작성한 코드 중 하나를 선택하여 전체 코드를 복사합니다.

49. Amazon Q에게 `다음 코드를 리뷰해주세요. 개선점과 모범 사례를 제안해주세요`라고 요청합니다.

50. AI의 제안을 확인한 후, `이 코드에 주석을 추가하고 docstring을 작성해주세요`라고 요청하여 문서화도 개선합니다.

> [!TIP]
> Amazon Q에게 구체적으로 요청할수록 더 정확한 결과를 얻을 수 있습니다. "코드를 작성해주세요"보다 "requests 라이브러리를 사용하여 에러 처리가 포함된 REST API 호출 코드를 작성해주세요"처럼 상세하게 요청합니다.

✅ **태스크 완료**: API 호출, 테스트 코드 생성, 코드 리뷰 등 실무 활용 시나리오를 체험했습니다.


## 태스크 8: 에이전트 코딩 (Vibe Coding) 체험

> [!CONCEPT] 에이전트 코딩이란?
>
> 에이전트 코딩은 Amazon Q가 코딩 파트너 역할을 하여 개발 과정에서 사용자와 채팅하며 파일을 직접 수정하는 기능입니다.
>
> - **자동 파일 수정**: 코드 개선을 요청하면 Amazon Q가 파일을 직접 업데이트합니다.
> - **실시간 협업**: Amazon Q가 작업하는 동안에도 계속 지침을 추가할 수 있습니다.
> - **변경 사항 검토**: diff 뷰에서 변경 사항을 확인하고 실행 취소할 수 있습니다.
>
> 에이전트 코딩은 IDE에서 기본적으로 켜져 있으며, 채팅 패널 하단의 `</>` 아이콘으로 켜거나 끌 수 있습니다.

### 8.1 에이전트 코딩 활성화 확인

51. VS Code에서 Amazon Q 채팅 패널을 엽니다.

52. 채팅 패널 하단에 `</>` 아이콘이 활성화되어 있는지 확인합니다. 비활성화되어 있다면 클릭하여 활성화합니다.

> [!NOTE]
> 에이전트 코딩이 활성화되면 Amazon Q가 파일을 직접 수정할 수 있습니다. 비활성화하면 코드 제안만 제공하고 파일을 수정하지 않습니다.

### 8.2 스도쿠 게임 생성

53. 바탕화면이나 원하는 위치에 `sudoku-game` 폴더를 생성합니다. VS Code에서 **File** > **Open Folder**를 선택하여 생성한 `sudoku-game` 폴더를 엽니다.

> [!NOTE]
> 에이전트 코딩은 현재 열려 있는 폴더 내에서 파일을 생성하고 수정합니다. 빈 폴더를 새로 열어야 기존 실습 파일과 섞이지 않습니다.

54. Amazon Q 채팅창에 다음과 같이 요청합니다:

```
스도쿠 게임을 만들어주세요.
- 9x9 그리드로 구성
- 일부 숫자는 미리 채워져 있고, 나머지는 사용자가 입력
- 숫자 입력 시 유효성 검사 (1-9만 입력 가능, 같은 행/열/3x3 박스에 중복 불가)
- "새 게임" 버튼으로 새로운 퍼즐 생성
- "정답 확인" 버튼으로 완성 여부 확인
- 깔끔한 UI 디자인 (그리드 선, 색상 구분)
```

55. Amazon Q가 작업을 시작하면 진행 상황을 확인합니다. Amazon Q는 자동으로 파일을 생성하고 코드를 작성합니다.

> [!TROUBLESHOOTING]
> **Amazon Q가 파일을 생성하지 않는 경우:**
> - 채팅 패널 하단의 `</>` 아이콘이 활성화되어 있는지 다시 확인합니다. 비활성화 상태에서는 코드 제안만 제공하고 파일을 직접 생성하지 않습니다.
> - VS Code에서 폴더가 열려 있는지 확인합니다. **File** > **Open Folder**로 `sudoku-game` 폴더를 열어야 합니다. 폴더 없이 단일 파일만 열려 있으면 에이전트 코딩이 작동하지 않습니다.
> - "I can't create files" 메시지가 표시되면 VS Code를 재시작한 후 다시 시도합니다.

56. 생성된 파일들을 열어 코드를 확인합니다.

> [!OUTPUT]
> Amazon Q가 생성한 파일 예시:
> - `index.html`: HTML 구조와 스도쿠 그리드
> - `style.css`: 그리드 레이아웃 및 스타일링 (또는 HTML 내 `<style>` 태그)
> - `script.js`: 게임 로직, 유효성 검사, 퍼즐 생성 (또는 HTML 내 `<script>` 태그)
>
> 실제 생성되는 파일 구조는 Amazon Q의 판단에 따라 다를 수 있습니다.

### 8.3 게임 기능 개선

57. Amazon Q 채팅창에 추가 요청을 합니다:

```
다음 기능을 추가해주세요:
- 난이도 선택 버튼 (쉬움, 보통, 어려움)
- 타이머 기능 (게임 시작부터 경과 시간 표시)
- 힌트 버튼 (빈 칸 하나에 정답 표시)
```

58. Amazon Q가 파일을 자동으로 수정하는 것을 확인합니다.

59. VS Code의 소스 제어 탭에서 변경 사항을 확인합니다. diff 뷰에서 어떤 부분이 수정되었는지 확인할 수 있습니다.

> [!TIP]
> 변경 사항이 마음에 들지 않으면 **Ctrl+Z** (Windows/Linux) 또는 **Cmd+Z** (Mac)로 실행 취소할 수 있습니다. 또는 소스 제어에서 변경 사항을 되돌릴 수 있습니다.

### 8.4 스도쿠 게임 실행

60. `index.html` 파일을 브라우저에서 열어 게임을 실행합니다.

61. 다음 기능들을 테스트합니다:
   - 빈 칸에 숫자 입력
   - 유효성 검사 작동 확인 (잘못된 숫자 입력 시 경고)
   - "새 게임" 버튼으로 새 퍼즐 생성
   - "정답 확인" 버튼으로 완성 여부 확인
   - 난이도 선택 및 타이머 작동 확인

> [!SUCCESS]
> 에이전트 코딩을 통해 Amazon Q가 자연어 지시만으로 복잡한 게임을 생성하고 기능을 추가하는 것을 체험했습니다. 실무 프로젝트에서도 동일한 방식으로 애플리케이션을 개발하고 개선할 수 있습니다.

✅ **태스크 완료**: 에이전트 코딩으로 스도쿠 게임을 생성하고 기능을 추가하는 과정을 체험했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: IAM Identity Center 사용자 삭제

1. 상단 검색창에서 `IAM Identity Center`를 검색하고 **IAM Identity Center**를 선택합니다.

2. 왼쪽 메뉴에서 **Users**를 선택합니다.

3. `test-developer` 사용자를 선택(체크)합니다.

4. [[Delete users]] 버튼을 클릭합니다.

5. 확인 창에서 `test-developer`를 입력하고 [[Delete users]] 버튼을 클릭합니다.

### 태스크 2: IAM Identity Center 그룹 삭제

6. 왼쪽 메뉴에서 **Groups**를 선택합니다.

7. `Developers` 그룹을 선택(체크)합니다.

8. [[Delete groups]] 버튼을 클릭합니다.

9. 확인 창에서 `Developers`를 입력하고 [[Delete groups]] 버튼을 클릭합니다.

> [!NOTE]
> IAM Identity Center 자체를 비활성화할 수도 있지만, 비활성화 시 AWS Organizations 설정에도 영향을 줄 수 있습니다. 실습 계정에서만 사용하는 경우가 아니라면 사용자와 그룹만 삭제하는 것을 권장합니다.

### 태스크 3: 최종 확인

10. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

11. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

12. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

13. [[Search resources]]를 클릭합니다.

14. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

15. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

> [!IMPORTANT]
> IAM Identity Center의 사용자와 그룹은 Tag Editor에서 검색되지 않습니다. 반드시 태스크 1, 2를 먼저 수행하여 직접 삭제해야 합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🔐
AWS IAM Identity Center
여러 AWS 계정과 애플리케이션에 대한 SSO(Single Sign-On)를 중앙에서 관리하는 서비스입니다

👥
중앙 집중식 사용자 관리
조직 내 모든 사용자를 한 곳에서 생성하고 관리하여 계정별로 IAM 사용자를 만들 필요가 없습니다

🤖
Amazon Q Developer
AWS가 제공하는 AI 기반 코딩 어시스턴트로 코드 자동완성, AI 채팅, 코드 변환 등을 지원합니다

🆓
AWS Builder ID
개발자를 위한 무료 개인 프로필로 Amazon Q Developer에 무료로 접근할 수 있습니다

⚡
에이전트 코딩
Amazon Q가 자연어 지시만으로 파일을 직접 생성하고 수정하는 강력한 기능입니다

💡
AI 활용 개발
구체적이고 상세한 프롬프트를 제공할수록 더 정확하고 유용한 코드를 생성할 수 있습니다
