---
title: 'Amazon API Gateway 서비스 구축'
week: 9
session: 3
awsServices:
  - Amazon API Gateway
  - AWS Lambda
learningObjectives:
  - Amazon API Gateway의 목적과 기본 아키텍처를 이해할 수 있습니다.
  - Amazon API Gateway의 주요 기능(스테이지, 메서드, 통합)을 활용할 수 있습니다.
  - API의 효과적인 배포 및 관리 방법을 습득할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **API Gateway**로 **REST API**를 생성하고 **Lambda 함수**와 통합합니다. 리소스와 메서드를 정의하여 **/users** 경로에 **GET과 POST** 요청을 처리하도록 설정합니다. **Lambda 프록시 통합**으로 API Gateway가 요청을 Lambda에 전달하고 응답을 반환하도록 구성합니다. **CORS**를 활성화하여 브라우저에서 API를 호출할 수 있도록 하고, **스테이지**에 배포하여 실제 엔드포인트를 생성합니다.

> [!DOWNLOAD]
> [week9-3-api-gateway.zip](/files/week9/week9-3-api-gateway.zip)
>
> - `setup-9-3.sh` - 사전 환경 구축 스크립트 (Amazon DynamoDB 테이블, AWS IAM 역할, AWS Lambda 함수, 샘플 데이터 생성)
> - `cleanup-9-3.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-9-3.sh 실행)

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - 서버리스 API 아키텍처
>
> <img src="/images/week9/9-3-architecture-diagram.svg" alt="API Gateway + Lambda + DynamoDB 서버리스 아키텍처 - Client에서 API Gateway를 통해 Lambda 함수(GET/POST/DELETE)를 호출하고 DynamoDB 테이블에 데이터를 저장하는 구조" class="guide-img-lg" />

> [!CONCEPT] Amazon API Gateway란?
>
> Amazon API Gateway는 REST, HTTP, WebSocket API를 생성하고 관리하는 **완전 관리형 서비스**입니다.
>
> - **API 프록시**: 클라이언트 요청을 받아 Lambda, EC2 등 백엔드 서비스로 전달합니다
> - **스테이지(Stage)**: API의 배포 환경을 구분합니다 (dev, staging, prod 등)
> - **Lambda 프록시 통합**: API Gateway가 HTTP 요청 정보를 그대로 Lambda 함수에 전달하는 방식입니다
> - **CORS**: 브라우저에서 다른 도메인의 API를 호출할 수 있도록 허용하는 보안 설정입니다
>
> 이 실습에서는 REST API를 생성하고 Lambda 함수와 연동하여 사용자 데이터를 조회/생성하는 API를 구축합니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week9-3-api-gateway.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week9-3-api-gateway.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-9-3.sh cleanup-9-3.sh
./setup-9-3.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 2-3분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| DynamoDB 테이블 | CloudArchitect-Lab-Users |
| IAM 역할 | CloudArchitect-Lab-LambdaRole |
| Lambda 함수 | CloudArchitect-Lab-UsersAPI |
| 샘플 데이터 | 사용자 2개 레코드 (김철수, 이영희) |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week9-3-api-gateway.zip setup-9-3.sh cleanup-9-3.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

### 1.1 AWS Lambda 함수 확인

8. 상단 검색창에서 `Lambda`를 검색하고 **Lambda**를 선택합니다.

9. 왼쪽 메뉴에서 **Functions**를 선택합니다.

10. `CloudArchitect-Lab-UsersAPI` 함수를 선택합니다.

11. **Code** 탭에서 함수 코드를 확인합니다. 이 함수는 HTTP 메서드(GET/POST)에 따라 DynamoDB에서 사용자 데이터를 조회하거나 생성합니다.

12. **Configuration** 탭을 선택합니다. 탭 내 왼쪽 메뉴에서 **Permissions**를 선택하여 실행 역할이 `CloudArchitect-Lab-LambdaRole`인지 확인합니다.

### 1.2 Amazon DynamoDB 테이블 확인

13. 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

14. 왼쪽 메뉴에서 **Tables**를 선택합니다.

15. `CloudArchitect-Lab-Users` 테이블을 선택합니다.

16. **Explore table items** 버튼을 선택하여 김철수(user001), 이영희(user002) 샘플 데이터를 확인합니다.

✅ **태스크 완료**: Lambda 함수와 DynamoDB 테이블이 정상적으로 구축되어 있습니다.


## 태스크 2: Amazon API Gateway REST API 생성

> [!CONCEPT] REST API vs HTTP API
>
> API Gateway는 두 가지 API 유형을 제공합니다:
>
> | 구분 | REST API | HTTP API |
> |------|----------|----------|
> | 기능 | API 키, 사용량 계획, 캐싱 등 풍부한 기능 | 경량화된 기본 기능 |
> | 비용 | 상대적으로 높음 | REST API 대비 약 70% 저렴 |
> | 적합 사례 | 엔터프라이즈 API, 세밀한 제어 필요 시 | 간단한 프록시, 비용 최적화 |
>
> 이 실습에서는 기능이 풍부한 **REST API**를 사용합니다.

### 2.1 REST API 생성

17. 상단 검색창에서 `API Gateway`를 검색하고 **API Gateway**를 선택합니다.

18. [[Create API]] 버튼을 클릭합니다.

19. **REST API** 섹션에서 [[Build]] 버튼을 클릭합니다.

20. **New API**를 선택합니다.

21. **API name**에 `CloudArchitect-Lab-UsersAPI`를 입력합니다.

22. **Description**에 `CloudArchitect Lab 실습용 사용자 API`를 입력합니다.

23. [[Create API]] 버튼을 클릭합니다.

### 2.2 리소스 생성

24. API가 생성되면 **Resources** 화면이 표시됩니다. `/` (루트) 리소스가 보입니다.

25. [[Create resource]] 버튼을 클릭합니다.

26. **Resource name**에 `users`를 입력합니다.

27. **Resource path**가 `/users`로 자동 설정되는지 확인합니다.

28. [[Create resource]] 버튼을 클릭합니다.

> [!NOTE]
> 리소스 경로 `/users`는 API의 엔드포인트 URL에 포함됩니다. 예를 들어 `https://[api-id].execute-api.ap-northeast-2.amazonaws.com/dev/users` 형태가 됩니다.

✅ **태스크 완료**: REST API와 `/users` 리소스가 생성되었습니다.


## 태스크 3: AWS Lambda 함수 연동

> [!CONCEPT] Lambda 프록시 통합
>
> Lambda 프록시 통합을 사용하면 API Gateway가 HTTP 요청 정보(메서드, 경로, 헤더, 쿼리 파라미터, 본문)를 **그대로 Lambda 함수에 전달**합니다. Lambda 함수는 이 정보를 파싱하여 적절한 응답을 반환합니다. 프록시 통합을 사용하지 않으면 API Gateway에서 요청/응답 매핑 템플릿을 별도로 설정해야 합니다.

### 3.1 GET 메서드 생성

29. `/users` 리소스가 선택된 상태에서 [[Create method]] 버튼을 클릭합니다.

30. **Method type**에서 **GET**을 선택합니다.

31. **Integration type**에서 **Lambda Function**을 선택합니다.

32. **Lambda proxy integration** 토글을 활성화합니다.

33. **Lambda function** 필드에서 **CloudArchitect-Lab-UsersAPI**를 선택합니다.

34. [[Create method]] 버튼을 클릭합니다.

35. Lambda 함수에 대한 권한 추가 확인 창이 표시되면 [[OK]] 버튼을 클릭합니다.

### 3.2 POST 메서드 생성

36. `/users` 리소스가 선택된 상태에서 [[Create method]] 버튼을 클릭합니다.

37. **Method type**에서 **POST**를 선택합니다.

38. **Integration type**에서 **Lambda Function**을 선택합니다.

39. **Lambda proxy integration** 토글을 활성화합니다.

40. **Lambda function** 필드에서 **CloudArchitect-Lab-UsersAPI**를 선택합니다.

41. [[Create method]] 버튼을 클릭합니다.

42. 권한 추가 확인 창에서 [[OK]] 버튼을 클릭합니다.

### 3.3 CORS 활성화

43. `/users` 리소스를 선택한 상태에서 [[Enable CORS]] 버튼을 클릭합니다.

44. **Gateway responses**와 **Methods** 섹션에서 **GET**과 **POST**를 체크합니다.

45. **Access-Control-Allow-Origin**에 `*`가 입력되어 있는지 확인합니다.

46. [[Save]] 버튼을 클릭합니다.

> [!TIP]
> CORS를 활성화하면 OPTIONS 메서드가 자동으로 생성됩니다. 브라우저는 실제 API 호출 전에 OPTIONS 요청(Preflight)을 보내 CORS 허용 여부를 확인합니다. 이 설정이 없으면 웹 애플리케이션에서 API 호출 시 CORS 에러가 발생합니다.

47. Resources 목록에서 `/users` 아래에 GET, POST, OPTIONS 메서드가 모두 표시되는지 확인합니다.

✅ **태스크 완료**: Lambda 함수와 연동된 GET/POST 메서드와 CORS 설정이 완료되었습니다.


## 태스크 4: API 배포 및 테스트

### 4.1 API 배포

48. 화면 오른쪽 상단의 주황색 [[Deploy API]] 버튼을 클릭합니다.

49. **Stage** 드롭다운에서 ***New Stage***를 선택합니다.

50. **Stage name**에 `dev`를 입력합니다.

51. [[Deploy]] 버튼을 클릭합니다.

52. 배포가 완료되면 **Stages** 화면에서 **Invoke URL**이 표시됩니다.

53. **Invoke URL**을 복사하여 메모장에 저장합니다.

> [!IMPORTANT]
> Invoke URL 형식: `https://[api-id].execute-api.ap-northeast-2.amazonaws.com/dev`
> `[api-id]`는 AWS가 자동으로 생성한 10자리 고유 ID입니다. 이 URL은 외부에서 접근 가능한 HTTPS 엔드포인트입니다.

### 4.2 콘솔에서 GET 테스트

54. 왼쪽 메뉴에서 **Resources**를 선택합니다.

55. `/users` 리소스 아래의 **GET** 메서드를 선택합니다.

56. **Test** 탭을 선택합니다.

57. [[Test]] 버튼을 클릭하여 테스트를 실행합니다.

58. **Response body**에서 사용자 목록(김철수, 이영희)이 JSON 형태로 반환되는지 확인합니다.

> [!OUTPUT]
> ```json
> {
>   "message": "CloudArchitect Lab12 - Lambda와 DynamoDB 연동",
>   "users": [
>     {"id": "user001", "name": "김철수", "email": "kim@example.com", ...},
>     {"id": "user002", "name": "이영희", "email": "lee@example.com", ...}
>   ],
>   "count": 2
> }
> ```

### 4.3 콘솔에서 POST 테스트

59. `/users` 리소스 아래의 **POST** 메서드를 선택합니다.

60. **Test** 탭을 선택합니다.

61. **Request body**에 다음 JSON을 입력합니다:

```json
{
  "id": "user003",
  "name": "박민수",
  "email": "park@example.com",
  "age": 28,
  "department": "소프트웨어학과"
}
```

62. [[Test]] 버튼을 클릭합니다.

63. **Response body**에서 `statusCode: 201`과 "사용자 생성/업데이트 성공" 메시지를 확인합니다.

> [!OUTPUT]
> ```json
> {
>   "message": "사용자 생성/업데이트 성공",
>   "id": "user003"
> }
> ```

### 4.4 CloudShell에서 외부 API 테스트

64. CloudShell에서 다음 명령어를 실행합니다 (`[Invoke URL]`을 실제 URL로 교체):

```bash
curl -s "[Invoke URL]/users" | python3 -m json.tool
```

> [!OUTPUT]
> ```json
> {
>     "message": "CloudArchitect Lab12 - Lambda와 DynamoDB 연동",
>     "users": [...],
>     "count": 3
> }
> ```

65. POST 요청도 테스트합니다:

```bash
curl -s -X POST "[Invoke URL]/users" \
  -H "Content-Type: application/json" \
  -d '{"id":"user004","name":"최지은","email":"choi@example.com","age":25}' | python3 -m json.tool
```

66. 다시 GET 요청을 실행하여 사용자 수가 증가했는지 확인합니다.

> [!TROUBLESHOOTING]
> - `{"message":"Missing Authentication Token"}` 에러: URL 경로에 `/users`가 포함되어 있는지 확인합니다. Invoke URL 뒤에 `/users`를 추가해야 합니다
> - `{"message":"Internal server error"}` 에러: Lambda 함수의 CloudWatch Logs에서 상세 에러 메시지를 확인합니다

✅ **태스크 완료**: API Gateway를 통해 GET/POST 요청이 정상적으로 처리되고 DynamoDB 데이터가 조회/생성됩니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-9-3.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - DynamoDB 테이블 (`CloudArchitect-Lab-Users`)
   - Lambda 함수 (`CloudArchitect-Lab-UsersAPI`)
   - IAM 역할 (`CloudArchitect-Lab-LambdaRole`)

> [!NOTE]
> 실습 중 직접 생성한 API Gateway는 스크립트로 삭제되지 않을 수 있습니다. 아래 수동 삭제 단계를 확인하세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> API Gateway를 먼저 삭제한 후 Lambda 함수를 삭제합니다.

#### 태스크 1: Amazon API Gateway 삭제

1. 상단 검색창에서 `API Gateway`를 검색하고 **API Gateway**를 선택합니다.

2. `CloudArchitect-Lab-UsersAPI` API를 선택합니다.

3. **Actions** > **Delete**를 선택합니다.

4. 확인 필드에 API 이름을 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 2: AWS Lambda 함수 삭제

5. 상단 검색창에서 `Lambda`를 검색하고 **Lambda**를 선택합니다.

6. `CloudArchitect-Lab-UsersAPI` 함수를 선택하고 **Actions** > **Delete**를 선택합니다.

7. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 3: Amazon DynamoDB 테이블 삭제

8. 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

9. 왼쪽 메뉴에서 **Tables**를 선택합니다.

10. `CloudArchitect-Lab-Users` 테이블을 선택하고 **Delete**를 클릭합니다.

11. 확인 필드에 `confirm`을 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: AWS IAM 역할 삭제

12. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

13. 왼쪽 메뉴에서 **Roles**를 선택합니다.

14. `CloudArchitect-Lab-LambdaRole`을 검색하여 선택합니다.

15. **Delete** 버튼을 클릭합니다.

16. 확인 필드에 역할 이름을 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 5: Amazon CloudWatch 로그 그룹 삭제

17. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

18. 왼쪽 메뉴에서 **Log groups**를 선택합니다.

19. `/aws/lambda/CloudArchitect-Lab-UsersAPI` 로그 그룹을 선택하고 **Actions** > **Delete log group(s)**를 선택합니다.

20. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

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

🌐
Amazon API Gateway
REST API를 생성하고 리소스(/users)와 메서드(GET/POST)를 구성하여 HTTP 엔드포인트를 만들었습니다

🚀
스테이지 배포
dev 스테이지에 API를 배포하여 외부에서 접근 가능한 HTTPS 엔드포인트를 생성했습니다

🧪
API 테스트
콘솔 테스트와 curl 명령어로 GET/POST 요청의 정상 동작을 확인했습니다
