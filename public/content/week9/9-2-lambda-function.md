---
title: 'AWS Lambda 함수 개발'
week: 9
session: 2
awsServices:
  - AWS Lambda
learningObjectives:
  - AWS Lambda의 기본 개념과 주요 특징을 이해할 수 있습니다.
  - AWS Lambda 함수를 개발하고 이벤트 소스를 구성할 수 있습니다.
  - AWS Lambda 함수를 배포하고 모니터링할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 서버 없이 코드를 실행하는 **AWS Lambda** 함수를 생성하고, **DynamoDB**와 연동하여 사용자 데이터를 관리하는 **서버리스 API**를 구축합니다.

> [!DOWNLOAD]
> [week9-2-lambda-function.zip](/files/week9/week9-2-lambda-function.zip)
>
> - `setup-9-2.sh` - 사전 환경 구축 스크립트 (Amazon DynamoDB 테이블, AWS IAM 역할, 샘플 데이터 생성)
> - `cleanup-9-2.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-9-2.sh 실행)

> [!CONCEPT] AWS Lambda란?
>
> AWS Lambda는 서버를 프로비저닝하거나 관리하지 않고 코드를 실행할 수 있는 **서버리스 컴퓨팅** 서비스입니다.
>
> - **서버리스**: 서버 관리가 필요 없으며, 코드가 실행될 때만 컴퓨팅 리소스가 할당됩니다
> - **이벤트 기반**: API Gateway 요청, S3 업로드, DynamoDB 변경 등 이벤트에 의해 자동으로 실행됩니다
> - **자동 확장**: 동시 요청 수에 따라 자동으로 확장되며, 별도의 스케일링 설정이 필요 없습니다
> - **종량제 과금**: 함수 실행 횟수와 실행 시간(밀리초 단위)에 따라 과금됩니다
>
> 이 실습에서는 Lambda 함수로 DynamoDB 테이블의 사용자 데이터를 조회하고 생성하는 RESTful API를 구현합니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week9-2-lambda-function.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > **Upload file**을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week9-2-lambda-function.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-9-2.sh
./setup-9-2.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 1-2분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| DynamoDB 테이블 | CloudArchitect-Lab-Users |
| IAM 역할 | CloudArchitect-Lab-LambdaExecutionRole |
| 샘플 데이터 | 사용자 2개 레코드 (김철수, 이영희) |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.

> [!TIP]
> **CloudShell 파일 정리**: 실습이 완전히 종료된 후, 업로드한 ZIP 파일과 스크립트를 삭제하여 CloudShell 스토리지를 정리할 수 있습니다:
> ```bash
> rm -f week9-2-lambda-function.zip setup-9-2.sh cleanup-9-2.sh
> ```
> CloudShell 스토리지는 리전별로 1GB까지 무료 제공되며, 파일 정리는 선택사항입니다.


## 태스크 1: 사전 구축된 환경 확인

> [!CONCEPT] Amazon DynamoDB와 AWS Lambda 연동
>
> Lambda 함수가 DynamoDB에 접근하려면 **IAM 역할**이 필요합니다. IAM 역할에 DynamoDB 읽기/쓰기 권한과 CloudWatch Logs 권한을 부여하면, Lambda 함수가 액세스 키 없이 안전하게 데이터베이스에 접근할 수 있습니다.

### 1.1 Amazon DynamoDB 테이블 확인

8. 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

9. 왼쪽 메뉴에서 **Tables**를 선택합니다.

10. **CloudArchitect-Lab-Users** 테이블이 생성되어 있는지 확인합니다.

11. **CloudArchitect-Lab-Users** 테이블을 선택하여 상세 정보를 확인합니다.

12. **General information** 섹션에서 다음 설정을 확인합니다:
- **Partition key**: `id` (String)
- **Table status**: "Active"

13. **Explore table items** 버튼을 선택하여 샘플 데이터를 확인합니다.

14. 김철수(user001), 이영희(user002) 2개의 레코드가 있는지 확인합니다.

### 1.2 AWS IAM 역할 확인

15. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

16. 왼쪽 메뉴에서 **Roles**를 선택합니다.

17. 검색창에 `CloudArchitect-Lab`을 입력하여 **CloudArchitect-Lab-LambdaExecutionRole**을 찾습니다.

18. 해당 역할을 선택합니다.

19. **Permissions** 탭에서 연결된 정책을 확인합니다:
- DynamoDB 읽기/쓰기 권한
- CloudWatch Logs 권한

> [!TIP]
> IAM 역할의 **Trust relationships** 탭을 선택하면 `lambda.amazonaws.com`이 신뢰할 수 있는 엔터티로 설정되어 있는 것을 확인할 수 있습니다. 이 설정이 있어야 Lambda 서비스가 이 역할을 사용할 수 있습니다.

✅ **태스크 완료**: DynamoDB 테이블과 IAM 역할이 정상적으로 구축되어 있습니다.


## 태스크 2: AWS Lambda 함수 생성

> [!CONCEPT] AWS Lambda 함수 구성 요소
>
> Lambda 함수는 다음 요소로 구성됩니다:
>
> - **핸들러(Handler)**: 이벤트를 처리하는 진입점 함수입니다 (예: `lambda_function.lambda_handler`)
> - **런타임(Runtime)**: 코드 실행 환경입니다 (Python, Node.js, Java 등)
> - **실행 역할(Execution Role)**: 함수가 AWS 서비스에 접근할 때 사용하는 IAM 역할입니다
> - **메모리/타임아웃**: 함수에 할당되는 메모리(128MB~10GB)와 최대 실행 시간(최대 15분)입니다

### 2.1 AWS Lambda 함수 생성 시작

20. 상단 검색창에서 `Lambda`를 검색하고 **Lambda**를 선택합니다.

21. [[Create function]] 버튼을 클릭합니다.

22. **Author from scratch**를 선택합니다.

23. **Function name**에 `CloudArchitect-Lab-UsersAPI`를 입력합니다.

24. **Runtime**에서 **Python 3.14**를 선택합니다.

### 2.2 실행 역할 설정

25. **Change default execution role** 섹션을 확장합니다.

26. **Execution role**에서 **Use another role**을 선택합니다.

27. **Existing role** 드롭다운에서 **CloudArchitect-Lab-LambdaExecutionRole**을 선택합니다.

28. [[Create function]] 버튼을 클릭합니다.

29. 함수 상세 페이지가 표시되면 상단에 "Successfully created the function" 메시지를 확인합니다.

> [!NOTE]
> 함수 상태가 **Active**인지 상단의 **Function overview** 섹션에서 확인합니다. Active 상태여야 함수를 실행할 수 있습니다.

✅ **태스크 완료**: DynamoDB 접근 권한이 있는 Lambda 함수가 생성되었습니다.


## 태스크 3: AWS Lambda 함수 코드 작성

### 3.1 함수 코드 구현

30. 생성된 Lambda 함수 페이지에서 **Code** 탭을 선택합니다.

31. 코드 편집기에서 기본 코드(`lambda_function.py`)를 모두 선택하고 다음 코드로 교체합니다:

```python
"""
CloudArchitect Week 9-2 - Lambda와 DynamoDB 연동
사용자 프로필을 관리하는 서버리스 API 함수입니다.

이 Lambda 함수는 RESTful API 형태로 DynamoDB 테이블의 사용자 데이터를 관리합니다.
- GET /users: 전체 사용자 목록 조회
- GET /users/{id}: 특정 사용자 프로필 조회
- POST /users: 새 사용자 생성 또는 기존 사용자 업데이트
"""

import json
import boto3
from decimal import Decimal

# DynamoDB 리소스 및 테이블 연결
# boto3.resource()는 고수준 API로 객체 지향적인 방식으로 DynamoDB를 사용할 수 있습니다
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('CloudArchitect-Lab-Users')

def decimal_default(obj):
    """
    DynamoDB의 Decimal 타입을 JSON 직렬화 가능한 float로 변환합니다.
    
    DynamoDB는 숫자를 Decimal 타입으로 저장하는데, 
    Python의 json.dumps()는 Decimal을 직렬화할 수 없어 오류가 발생합니다.
    이 함수를 json.dumps()의 default 파라미터로 전달하여 변환을 처리합니다.
    
    Args:
        obj: 직렬화할 객체
        
    Returns:
        float: Decimal을 float로 변환한 값
        
    Raises:
        TypeError: Decimal이 아닌 타입이 전달된 경우
    """
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    """
    Lambda 핸들러 함수 - API Gateway 프록시 통합 이벤트를 처리합니다.
    
    HTTP 메서드와 경로에 따라 사용자 데이터를 조회하거나 생성합니다.
    
    Args:
        event (dict): API Gateway에서 전달하는 이벤트 객체
            - httpMethod: HTTP 메서드 (GET, POST 등)
            - path: 요청 경로 (/users, /users/{id} 등)
            - pathParameters: 경로 파라미터 (예: {"id": "user001"})
            - queryStringParameters: 쿼리 문자열 (예: {"profileType": "basic"})
            - body: 요청 본문 (JSON 문자열)
        context (object): Lambda 실행 컨텍스트 정보
        
    Returns:
        dict: API Gateway 프록시 통합 응답 형식
            - statusCode: HTTP 상태 코드
            - headers: 응답 헤더
            - body: 응답 본문 (JSON 문자열)
    """
    try:
        # 이벤트에서 HTTP 메서드와 경로 추출
        # API Gateway가 전달하는 표준 필드입니다
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/users')
        
        # ===== GET /users - 전체 사용자 목록 조회 =====
        if http_method == 'GET' and path == '/users':
            # DynamoDB scan() 작업: 테이블의 모든 항목을 조회합니다
            # 주의: 대용량 테이블에서는 성능 문제가 있을 수 있으므로 프로덕션에서는 Query 사용을 권장합니다
            response = table.scan()
            
            # HTTP 200 OK 응답 반환
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'message': 'CloudArchitect Week 9-2 - Lambda와 DynamoDB 연동',
                    'users': response['Items'],  # 조회된 사용자 목록
                    'count': response['Count']   # 조회된 항목 수
                }, default=decimal_default, ensure_ascii=False)
            }
        
        # ===== GET /users/{id} - 특정 사용자 프로필 조회 =====
        elif http_method == 'GET' and path.startswith('/users/'):
            # 경로 파라미터에서 사용자 ID 추출
            # API Gateway가 /users/{id} 형태의 경로를 파싱하여 pathParameters에 저장합니다
            path_parameters = event.get('pathParameters', {})
            user_id = path_parameters.get('id') if path_parameters else None
            
            # ID가 없으면 400 Bad Request 반환
            if not user_id:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'error': 'id가 필요합니다'
                    }, ensure_ascii=False)
                }
            
            # 쿼리 파라미터에서 프로필 타입 확인
            # 예: /users/user001?profileType=detailed
            query_params = event.get('queryStringParameters') or {}
            profile_type = query_params.get('profileType', 'basic')
            
            # DynamoDB get_item() 작업: 파티션 키로 특정 항목 조회
            # scan()보다 훨씬 빠르고 효율적입니다
            response = table.get_item(
                Key={'id': user_id}
            )
            
            # 사용자가 존재하는 경우
            if 'Item' in response:
                user_data = response['Item']
                
                # profileType에 따라 반환 데이터 필터링
                # basic: 기본 정보만 (id, name, email)
                # detailed: 모든 정보 (age, department 포함)
                if profile_type == 'basic':
                    filtered_data = {
                        'id': user_data['id'],
                        'name': user_data['name'],
                        'email': user_data['email']
                    }
                else:  # detailed
                    filtered_data = user_data
                
                # HTTP 200 OK 응답 반환
                return {
                    'statusCode': 200,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'message': f'사용자 프로필 조회 성공 ({profile_type})',
                        'user': filtered_data
                    }, default=decimal_default, ensure_ascii=False)
                }
            else:
                # 사용자가 존재하지 않는 경우 404 Not Found 반환
                return {
                    'statusCode': 404,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'error': '사용자를 찾을 수 없습니다',
                        'id': user_id
                    }, ensure_ascii=False)
                }
        
        # ===== POST /users - 사용자 생성/업데이트 =====
        elif http_method == 'POST' and path == '/users':
            # 요청 본문(JSON 문자열)을 파싱하여 딕셔너리로 변환
            body = json.loads(event.get('body', '{}'))
            
            # id 필드가 있는 경우에만 처리
            if 'id' in body:
                # DynamoDB put_item() 작업: 항목 생성 또는 덮어쓰기
                # 동일한 id가 있으면 업데이트, 없으면 새로 생성됩니다
                table.put_item(Item=body)
                
                # HTTP 201 Created 응답 반환
                return {
                    'statusCode': 201,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'message': '사용자 생성/업데이트 성공',
                        'id': body['id']
                    }, ensure_ascii=False)
                }
            else:
                # id가 없으면 400 Bad Request 반환
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json'
                    },
                    'body': json.dumps({
                        'error': 'id가 필요합니다'
                    }, ensure_ascii=False)
                }
        
        # ===== 지원하지 않는 메서드/경로 =====
        else:
            # HTTP 405 Method Not Allowed 응답 반환
            return {
                'statusCode': 405,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'error': f'지원하지 않는 HTTP 메서드: {http_method} {path}'
                }, ensure_ascii=False)
            }
    
    # ===== 예외 처리 =====
    except Exception as e:
        # 모든 예외를 캐치하여 500 Internal Server Error 반환
        # 프로덕션에서는 로깅을 추가하고 민감한 정보를 노출하지 않도록 주의해야 합니다
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e)
            }, ensure_ascii=False)
        }
```

32. [[Deploy]] 버튼을 클릭하여 코드를 배포합니다.

33. 상단에 "Successfully updated the function" 메시지가 표시되는지 확인합니다.

> [!NOTE]
> 코드에서 `boto3.resource('dynamodb')`는 AWS SDK를 통해 DynamoDB에 연결합니다. Lambda 실행 역할에 DynamoDB 권한이 있으므로 별도의 액세스 키 설정이 필요 없습니다.

✅ **태스크 완료**: DynamoDB와 연동하는 사용자 프로필 관리 함수가 배포되었습니다.


## 태스크 4: AWS Lambda 함수 테스트

> [!CONCEPT] Lambda 테스트 이벤트
>
> Lambda 함수는 **이벤트(JSON)**를 입력으로 받아 처리합니다. 콘솔에서 테스트 이벤트를 직접 작성하여 함수를 실행할 수 있습니다. API Gateway와 연동할 때 전달되는 이벤트 구조를 미리 시뮬레이션하여 함수가 올바르게 동작하는지 검증합니다.

### 4.1 특정 사용자 프로필 조회 테스트

34. **Test** 탭을 선택합니다.

35. **Create new event**를 선택합니다.

36. **Event name**에 `GetUserProfile`을 입력합니다.

37. 이벤트 JSON을 다음으로 교체합니다:

```json
{
  "httpMethod": "GET",
  "path": "/users/user001",
  "pathParameters": {
    "id": "user001"
  },
  "queryStringParameters": {
    "profileType": "basic"
  }
}
```

> [!NOTE]
> 테스트 이벤트의 각 필드 설명:
>
> | 필드 | 설명 |
> |------|------|
> | `httpMethod` | HTTP 메서드 (GET, POST 등) |
> | `path` | API 경로 (/users/user001) |
> | `pathParameters` | URL 경로에서 추출한 파라미터 |
> | `queryStringParameters` | URL 쿼리 문자열 (?profileType=basic) |

38. [[Save]] 버튼을 클릭하여 테스트 이벤트를 저장합니다.

39. [[Test]] 버튼을 클릭하여 함수를 실행합니다.

40. 실행 결과에서 **Execution result: succeeded** 메시지를 확인합니다.

41. 응답 본문에서 `statusCode: 200`과 사용자 프로필 정보가 반환되는지 확인합니다.

> [!OUTPUT]
> ```json
> {
>   "statusCode": 200,
>   "body": "{\"message\": \"사용자 프로필 조회 성공 (basic)\", \"user\": {\"id\": \"user001\", \"name\": \"김철수\", \"email\": \"kim@example.com\"}}"
> }
> ```

### 4.2 전체 사용자 목록 조회 테스트

42. **Test** 탭에서 **Create new event**를 선택합니다.

43. **Event name**에 `GetAllUsers`를 입력합니다.

44. 이벤트 JSON을 다음으로 교체합니다:

```json
{
  "httpMethod": "GET",
  "path": "/users"
}
```

45. [[Save]] 버튼을 클릭한 후 [[Test]] 버튼을 클릭합니다.

46. 응답에서 `statusCode: 200`과 사용자 목록(김철수, 이영희)이 반환되는지 확인합니다.

> [!OUTPUT]
> ```json
> {
>   "statusCode": 200,
>   "body": "{\"message\": \"CloudArchitect Week 9-2 - Lambda와 DynamoDB 연동\", \"users\": [...], \"count\": 2}"
> }
> ```

### 4.3 사용자 생성 테스트

47. **Test** 탭에서 **Create new event**를 선택합니다.

48. **Event name**에 `CreateUser`를 입력합니다.

49. 이벤트 JSON을 다음으로 교체합니다:

```json
{
  "httpMethod": "POST",
  "path": "/users",
  "body": "{\"id\": \"user003\", \"name\": \"박민수\", \"email\": \"park@example.com\", \"age\": 28, \"department\": \"소프트웨어학과\"}"
}
```

50. [[Save]] 버튼을 클릭한 후 [[Test]] 버튼을 클릭합니다.

51. 응답에서 `statusCode: 201`과 "사용자 생성/업데이트 성공" 메시지를 확인합니다.

> [!OUTPUT]
> ```json
> {
>   "statusCode": 201,
>   "body": "{\"message\": \"사용자 생성/업데이트 성공\", \"id\": \"user003\"}"
> }
> ```

52. DynamoDB 콘솔로 이동하여 **CloudArchitect-Lab-Users** 테이블의 **Explore table items**를 선택합니다.

53. 박민수(user003) 레코드가 추가되었는지 확인합니다.

54. Lambda 콘솔로 이동하여 **CloudArchitect-Lab-UsersAPI** 함수를 선택합니다.

55. **Test** 탭에서 이벤트 드롭다운에서 `GetAllUsers`를 선택하고 [[Test]] 버튼을 클릭합니다.

56. 사용자 수가 3명(`count: 3`)으로 증가했는지 확인합니다.

✅ **태스크 완료**: GET(전체 조회), GET(개별 조회), POST(생성) 등 RESTful API의 주요 기능을 모두 테스트했습니다.


## 태스크 5: 모니터링 및 로그 확인

### 5.1 AWS Lambda 메트릭 확인

57. Lambda 함수 페이지에서 **Monitor** 탭을 선택합니다.

58. 다음 메트릭 그래프를 확인합니다:
- **Invocations**: 함수 호출 횟수
- **Duration**: 실행 시간 (밀리초)
- **Error count and success rate**: 오류 발생 횟수와 성공률

> [!TIP]
> **Duration** 그래프에서 함수 실행 시간을 확인할 수 있습니다. 첫 번째 호출(Cold Start)은 이후 호출보다 시간이 더 걸립니다. Lambda가 실행 환경을 초기화하는 시간이 포함되기 때문입니다.

### 5.2 Amazon CloudWatch Logs 확인

59. **Monitor** 탭에서 [[View CloudWatch logs]] 버튼을 클릭합니다.

60. CloudWatch Logs 콘솔에서 `/aws/lambda/CloudArchitect-Lab-UsersAPI` 로그 그룹이 표시됩니다.

61. 가장 최근 로그 스트림을 선택합니다.

62. 로그 이벤트에서 다음 정보를 확인합니다:
- **START**: 함수 실행 시작
- **END**: 함수 실행 종료
- **REPORT**: 실행 시간, 메모리 사용량, 과금 시간

> [!OUTPUT]
> ```
> REPORT RequestId: abc123-def456-...
> Duration: 45.23 ms
> Billed Duration: 46 ms
> Memory Size: 128 MB
> Max Memory Used: 67 MB
> ```

✅ **태스크 완료**: CloudWatch를 통해 Lambda 함수의 실행 상태와 성능을 확인했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-9-2.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - DynamoDB 테이블 (`CloudArchitect-Lab-Users`)
   - IAM 역할 (`CloudArchitect-Lab-LambdaExecutionRole`)

> [!NOTE]
> 실습 중 직접 생성한 Lambda 함수는 스크립트로 삭제되지 않을 수 있습니다. 아래 수동 삭제 단계를 확인하세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

#### 태스크 1: AWS Lambda 함수 삭제

1. 상단 검색창에서 `Lambda`를 검색하고 **Lambda**를 선택합니다.

2. 왼쪽 메뉴에서 **Functions**를 선택합니다.

3. **CloudArchitect-Lab-UsersAPI** 함수를 선택하고 **Actions** > **Delete**를 선택합니다.

4. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 2: Amazon DynamoDB 테이블 삭제

5. 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

6. 왼쪽 메뉴에서 **Tables**를 선택합니다.

7. **CloudArchitect-Lab-Users** 테이블을 선택하고 **Delete**를 클릭합니다.

8. **Delete all CloudWatch alarms for this table** 체크박스를 선택합니다.

9. 확인 필드에 `confirm`을 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 3: AWS IAM 역할 삭제

10. 상단 검색창에서 `IAM`을 검색하고 **IAM**을 선택합니다.

11. 왼쪽 메뉴에서 **Roles**를 선택합니다.

12. **CloudArchitect-Lab-LambdaExecutionRole**을 검색하여 선택합니다.

13. **Delete** 버튼을 클릭합니다.

14. 확인 필드에 역할 이름을 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 4: Amazon CloudWatch 로그 그룹 삭제

15. 상단 검색창에서 `CloudWatch`를 검색하고 **CloudWatch**를 선택합니다.

16. 왼쪽 메뉴에서 **Log groups**를 선택합니다.

17. `/aws/lambda/CloudArchitect-Lab-UsersAPI` 로그 그룹을 선택하고 **Actions** > **Delete log group(s)**를 선택합니다.

18. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 5: 최종 확인

19. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

20. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

21. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

22. [[Search resources]]를 클릭합니다.

23. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

⚙️
Lambda 함수 구성 요소
런타임(실행 언어), 핸들러(진입점 함수), 실행 역할(IAM), 메모리(128MB~10GB), 타임아웃(최대 15분)을 설정합니다.

🔐
IAM 역할 기반 권한
Lambda에 IAM 역할을 연결하면 액세스 키 없이도 다른 AWS 서비스(DynamoDB, S3 등)에 안전하게 접근할 수 있습니다.

⚡
서버리스 컴퓨팅
서버를 직접 관리하지 않고 코드만 작성하면 AWS가 자동으로 실행 환경을 제공하고 확장합니다.

🔄
이벤트 기반 실행
Lambda는 API 요청, 파일 업로드 등의 이벤트가 발생할 때만 실행되며, event 객체로 입력 데이터를 받습니다.

📊
CloudWatch 자동 로깅
함수 실행 로그와 메트릭(실행 시간, 메모리 사용량)이 자동으로 CloudWatch에 기록되어 모니터링할 수 있습니다.

💰
사용한 만큼만 과금
함수가 실행된 시간(밀리초)과 호출 횟수에 따라서만 비용이 청구되며, 대기 시간에는 비용이 없습니다.
