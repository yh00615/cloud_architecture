---
title: 'DynamoDB 서비스 활용'
week: 6
session: 3
awsServices:
  - Amazon DynamoDB
learningObjectives:
  - Amazon DynamoDB의 개념과 핵심 데이터 모델(테이블, 항목, 속성)을 이해할 수 있습니다.
  - Amazon DynamoDB의 용량 모드(온디맨드, 프로비저닝)를 비교하고 선택할 수 있습니다.
  - 쿼리, 스캔 연산의 특징을 이해하고 보조 인덱스를 활용할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **NoSQL 데이터베이스**인 **DynamoDB 테이블**을 생성하고 데이터를 관리합니다. **파티션 키**와 **정렬 키**를 설정하여 테이블 구조를 정의하고, **프로비저닝 모드**로 읽기/쓰기 용량을 설정합니다. 콘솔에서 항목을 생성하고 **쿼리**로 데이터를 검색한 후, **스캔**으로 전체 데이터를 조회합니다. 마지막으로 **강력한 일관된 읽기**와 **최종 일관된 읽기**의 차이를 이해합니다.

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다.

> [!CONCEPT] Amazon DynamoDB란?
>
> Amazon DynamoDB는 AWS에서 제공하는 **완전 관리형 NoSQL 데이터베이스** 서비스입니다.
>
> - **NoSQL**: 관계형 데이터베이스(RDS)와 달리 스키마가 없어 각 항목마다 다른 속성을 가질 수 있습니다
> - **파티션 키**: 데이터를 여러 파티션에 분산 저장하는 기준이 되는 필수 키입니다
> - **정렬 키**: 같은 파티션 키 내에서 데이터를 정렬하는 선택적 키입니다
> - **쿼리 vs 스캔**: 쿼리는 파티션 키로 특정 데이터만 조회하여 빠르고, 스캔은 전체 테이블을 검색하여 느립니다
>
> RDS가 정형화된 데이터에 적합하다면, DynamoDB는 유연한 구조의 대규모 데이터 처리에 적합합니다.

## 태스크 1: Amazon DynamoDB 테이블 생성

> [!CONCEPT] DynamoDB 테이블 구조
>
> DynamoDB 테이블은 **항목(Item)**의 모음이며, 각 항목은 **속성(Attribute)**으로 구성됩니다.
>
> - **테이블**: RDS의 테이블과 유사하지만 스키마가 고정되지 않습니다
> - **항목(Item)**: RDS의 행(Row)에 해당하며, 각 항목은 서로 다른 속성을 가질 수 있습니다
> - **속성(Attribute)**: RDS의 열(Column)에 해당하며, String, Number, Boolean 등 다양한 타입을 지원합니다
> - **파티션 키**: 각 항목을 고유하게 식별하는 필수 키입니다. DynamoDB는 이 키를 기준으로 데이터를 여러 파티션에 분산 저장하여 대규모 트래픽에서도 빠른 응답을 보장합니다

### 1.1 Amazon DynamoDB 서비스 접근

1. AWS Management Console에 로그인한 후 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

2. Amazon DynamoDB 콘솔의 왼쪽 메뉴에서 **Tables**를 선택합니다.

3. [[Create table]] 버튼을 클릭합니다.

### 1.2 테이블 기본 설정

4. **Table name**에 `CloudArchitect-Lab-Users`를 입력합니다.

5. **Partition key**에 `id`를 입력하고 타입을 **String**으로 설정합니다.

6. **Table settings**에서 **Default settings**를 선택합니다.

> [!NOTE]
> Default settings를 선택하면 On-demand 용량 모드가 자동으로 적용됩니다. On-demand 모드는 실제 읽기/쓰기 요청 수에 따라 자동으로 용량이 조절되므로 트래픽 예측이 어려운 실습 환경에 적합합니다.

7. 페이지를 아래로 스크롤하여 **Tags** 섹션을 찾습니다.

8. [[Add new tag]] 버튼을 클릭하고 첫 번째 태그를 입력합니다:
- **Key**: `Name`
- **Value**: `CloudArchitect-Lab-Users`

9. [[Add new tag]] 버튼을 다시 클릭하고 두 번째 태그를 추가합니다:
- **Key**: `StudentId`
- **Value**: `[본인 학번]` (예: 20241234)

> [!TIP]
> StudentId 태그를 추가하면 공유 AWS 계정에서 본인의 DynamoDB 테이블을 쉽게 구분하고, Tag Editor로 본인 학번으로 검색하여 모든 실습 리소스를 한 번에 확인할 수 있습니다.

10. [[Create table]] 버튼을 클릭합니다.

### 1.3 테이블 생성 완료 확인

11. 테이블 상태가 "Active"로 변경될 때까지 기다립니다.

> [!NOTE]
> 테이블 생성에 약 1-2분이 소요됩니다. 상태가 "Creating"에서 "Active"로 변경되면 데이터를 추가할 수 있습니다.

12. 생성된 `CloudArchitect-Lab-Users` 테이블 이름을 선택하여 상세 정보로 이동합니다.


## 태스크 2: 데이터 아이템 생성

> [!CONCEPT] DynamoDB의 스키마리스 구조
>
> DynamoDB는 파티션 키 외에는 스키마가 고정되지 않습니다. 같은 테이블 내에서 항목마다 서로 다른 속성을 가질 수 있습니다. 예를 들어 user001에는 `major` 속성이 있고, user002에는 `department` 속성이 있어도 문제없습니다. 이것이 NoSQL의 핵심 장점입니다.

### 2.1 첫 번째 아이템 생성 (Form 뷰)

13. 테이블 상세 페이지 상단의 **Explore table items** 탭을 선택합니다.

14. 화면 오른쪽 상단의 [[Create item]] 버튼을 클릭합니다.

15. **id** 필드에 `user001`을 입력합니다.

16. [[Add new attribute]] 버튼을 클릭하고 **String**을 선택합니다.

17. 속성 이름에 `name`을 입력하고 값에 `김철수`를 입력합니다.

18. [[Add new attribute]] 버튼을 클릭하고 **String**을 선택합니다.

19. 속성 이름에 `email`을 입력하고 값에 `kim@example.com`을 입력합니다.

20. [[Add new attribute]] 버튼을 클릭하고 **Number**를 선택합니다.

21. 속성 이름에 `age`를 입력하고 값에 `25`를 입력합니다.

22. [[Add new attribute]] 버튼을 클릭하고 **String**을 선택합니다.

23. 속성 이름에 `department`를 입력하고 값에 `컴퓨터공학과`를 입력합니다.

24. [[Create item]] 버튼을 클릭합니다.

> [!OUTPUT]
> ```
> Items returned 탭에서 생성된 아이템을 확인할 수 있습니다:
> id: user001 | name: 김철수 | email: kim@example.com | age: 25 | department: 컴퓨터공학과
> ```

### 2.2 두 번째 아이템 생성 (JSON 뷰)

25. [[Create item]] 버튼을 클릭합니다.

26. 아이템 편집 화면 상단의 **JSON view**를 선택합니다.

27. **View DynamoDB JSON** 토글을 비활성화합니다 (꺼진 상태로 설정).

> [!WARNING]
> **View DynamoDB JSON**이 활성화되어 있으면 타입 정보가 추가된 복잡한 형태(`{"S": "값"}`)로 표시됩니다. 일반 JSON 형태로 입력하려면 반드시 비활성화합니다.

28. 다음 JSON 데이터를 입력합니다:

```json
{
  "id": "user002",
  "name": "이영희",
  "email": "lee@example.com",
  "age": 23,
  "department": "정보시스템학과"
}
```

29. [[Create item]] 버튼을 클릭합니다.

> [!TIP]
> JSON 뷰를 사용하면 복잡한 중첩 구조나 여러 속성을 한 번에 입력할 수 있어 편리합니다. 대량의 데이터를 입력할 때는 AWS CLI의 `aws dynamodb put-item` 명령어를 사용하는 것이 더 효율적입니다.

✅ **태스크 완료**: 2개의 사용자 아이템이 생성되었습니다.


## 태스크 3: 데이터 조회 및 쿼리

> [!CONCEPT] 쿼리(Query) vs 스캔(Scan)
>
> DynamoDB에서 데이터를 조회하는 방법은 크게 두 가지입니다. 각각의 특징을 이해하면 효율적인 데이터 조회 전략을 세울 수 있습니다.
>
> | 구분 | Query (쿼리) | Scan (스캔) |
> |------|-------------|-------------|
> | 검색 범위 | 파티션 키로 특정 항목만 조회 | 테이블의 모든 항목을 순차적으로 읽음 |
> | 속도 | 빠름 (필요한 데이터만 접근) | 느림 (데이터가 많을수록 시간 증가) |
> | 비용 | 낮음 (읽은 항목만 과금) | 높음 (전체 항목에 대해 과금) |
> | 사용 시점 | 특정 사용자, 특정 주문 등 조건 조회 | 전체 데이터 내보내기, 일괄 처리 등 |
>
> 예를 들어, 100만 건의 주문 데이터에서 특정 고객의 주문만 찾을 때 쿼리는 해당 고객의 항목만 읽지만, 스캔은 100만 건을 모두 읽은 후 필터링합니다. 실무에서는 가능한 한 쿼리를 사용하고 스캔은 최소화하는 것이 비용과 성능 면에서 유리합니다.

### 3.1 전체 데이터 스캔

30. 테이블 상세 페이지에서 **Explore table items** 탭을 선택합니다.

31. **Scan or query items** 섹션에서 드롭다운이 **Scan**으로 설정되어 있는지 확인합니다.

32. [[Run]] 버튼을 클릭하여 테이블의 모든 데이터를 조회합니다.

33. 하단의 **Items returned** 섹션에서 생성한 2개의 사용자 아이템이 모두 표시되는지 확인합니다.

> [!OUTPUT]
> ```
> Items returned: 2 | Items scanned: 2
>
> id       | name   | email              | age | department
> user001  | 김철수  | kim@example.com    | 25  | 컴퓨터공학과
> user002  | 이영희  | lee@example.com    | 23  | 정보시스템학과
> ```

32. **Items returned**와 **Items scanned** 수치를 확인합니다.

> [!NOTE]
> 스캔 결과에서 **Items returned**과 **Items scanned**가 동일하게 2로 표시됩니다. 데이터가 적을 때는 차이가 없지만, 대규모 테이블에서는 스캔이 전체 항목을 읽으므로 비용이 크게 증가합니다.

### 3.2 파티션 키로 쿼리

33. **Scan or query items** 섹션에서 드롭다운을 **Query**로 변경합니다.

34. **Partition key** 필드에 `user001`을 입력합니다.

35. [[Run]] 버튼을 클릭합니다.

36. `user001` (김철수) 사용자의 정보만 정확히 조회되는지 확인합니다.

> [!OUTPUT]
> ```
> Items returned: 1 | Items scanned: 1
>
> id       | name   | email              | age | department
> user001  | 김철수  | kim@example.com    | 25  | 컴퓨터공학과
> ```

37. **Items returned**이 `1`이고 **Items scanned**도 `1`인 것을 확인합니다.

> [!TIP]
> 쿼리는 파티션 키를 사용하여 정확한 항목만 검색하므로 매우 효율적입니다. 스캔에서는 Items scanned가 전체 항목 수(2)였지만, 쿼리에서는 1만 읽었습니다. 데이터가 수백만 건인 테이블에서 이 차이는 비용과 성능에 큰 영향을 미칩니다.

### 3.3 아이템 수정

38. **Scan or query items** 섹션에서 드롭다운을 다시 **Scan**으로 변경하고 [[Run]] 버튼을 클릭하여 전체 아이템을 조회합니다.

38. 하단 결과 목록에서 `user002` 아이템의 **id** 링크를 선택합니다.

39. **age** 값을 `24`로 변경합니다.

40. [[Save and close]] 버튼을 클릭합니다.

41. 변경된 내용이 반영되었는지 확인합니다.

> [!NOTE]
> DynamoDB에서는 개별 항목의 속성을 자유롭게 수정할 수 있습니다. 단, 파티션 키(`id`)는 항목을 식별하는 기준이므로 변경할 수 없습니다. 파티션 키를 변경하려면 기존 항목을 삭제하고 새로 생성해야 합니다.

✅ **태스크 완료**: 스캔과 쿼리의 차이를 확인하고 데이터를 수정했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: Amazon DynamoDB 테이블 삭제

1. 상단 검색창에서 `DynamoDB`를 검색하고 **DynamoDB**를 선택합니다.

2. 왼쪽 메뉴에서 **Tables**를 선택합니다.

3. 실습에서 생성한 테이블을 선택합니다.

4. **Delete** 버튼을 클릭합니다.

5. 확인 창에 `delete`를 입력하고 [[Delete]] 버튼을 클릭합니다.

### 태스크 2: 최종 확인

1. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

2. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

3. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `StudentId`를 선택하고, Tag value에 본인 학번을 입력합니다.

> [!TIP]
> StudentId 태그로 검색하면 본인이 생성한 리소스만 정확히 확인할 수 있습니다. Name 태그로 검색하려면 Tag key를 `Name`, Tag value를 `CloudArchitect-Lab`로 입력합니다.

4. [[Search resources]]를 클릭합니다.

5. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

6. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🔍
쿼리 vs 스캔
쿼리는 파티션 키를 사용해 특정 데이터만 조회하여 빠르고 효율적입니다. 스캔은 전체 테이블을 검색하므로 느리고 비용이 많이 듭니다.

📊
RDS vs DynamoDB
RDS는 정형화된 관계형 데이터에, DynamoDB는 유연한 구조의 대규모 비정형 데이터에 적합합니다.
