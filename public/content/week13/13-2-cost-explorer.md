---
title: 'Cost Explorer 기본 기능'
week: 13
session: 2
awsServices:
  - AWS Cost Explorer
learningObjectives:
  - AWS Cost Explorer를 활성화하고 비용 분석 대시보드의 주요 기능을 이해할 수 있습니다.
  - Amazon SNS 토픽을 생성하고 이메일 구독을 구성하여 알림 채널을 설정할 수 있습니다.
  - AWS Budgets를 생성하고 Amazon SNS와 연동하여 비용 알림 시스템을 구축할 수 있습니다.
---

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다

> [!NOTE]
> 이 실습에서는 AWS Cost Explorer와 AWS Budgets, Amazon SNS를 사용하여 실제 작동하는 비용 알림 시스템을 구축합니다.

## 태스크 1: AWS Cost Explorer 활성화 및 UI 탐색

> [!CONCEPT] AWS Cost Explorer란?
>
> AWS Cost Explorer는 AWS 비용과 사용량을 **시각적으로 분석**하는 서비스입니다.
>
> - **비용 추이 분석**: 서비스별, 리전별, 태그별로 비용을 분류하여 추이를 파악합니다
> - **예측 기능**: 과거 데이터를 기반으로 향후 비용을 예측합니다
> - **필터링**: 특정 서비스, 리전, 계정 등 다양한 조건으로 비용을 필터링합니다
>
> AWS Budgets와 Amazon SNS를 함께 사용하면 예산 초과 시 자동으로 알림을 받는 비용 관리 시스템을 구축할 수 있습니다.

### 1.1 AWS Cost Explorer 활성화

1. AWS Management Console에 로그인한 후 상단 검색창에서 `Billing and Cost Management`를 검색하고 **Billing and Cost Management**를 선택합니다.

2. Billing and Cost Management 콘솔의 왼쪽 메뉴에서 **Cost analysis** 섹션 아래의 **Cost Explorer**를 선택합니다.

3. **Launch Cost Explorer** 버튼이 표시되면 [[Launch Cost Explorer]] 버튼을 클릭합니다.

> [!WARNING]
> Cost Explorer를 처음 사용하는 경우 "Cost Explorer is being set up" 메시지가 표시될 수 있습니다. 이는 정상이며, 최대 24시간 후 데이터가 표시됩니다. 데이터가 없어도 다음 단계로 진행 가능합니다.

### 1.2 AWS Cost Explorer UI 둘러보기

4. Cost Explorer 대시보드에서 다음 요소들을 확인합니다:

   - **Date Range**: 기간 선택 (Last 6 Months가 기본값)
   - **Group by**: 비용 분류 기준 (Service, Region, Tag 등)
   - **Filters**: 특정 서비스나 리소스 필터링
   - **Granularity**: 일별/월별 세분화

5. 데이터가 있는 경우 그래프와 표를 확인하고, 없는 경우 UI 구조만 파악합니다.

> [!TIP]
> 실제 프로젝트에서는 Cost Explorer로 서비스별, 시간별 비용을 분석하여 예상치 못한 비용 증가를 조기에 발견할 수 있습니다. 월 1회 이상 정기적으로 확인하는 습관을 권장합니다.

✅ **태스크 완료**: Cost Explorer를 활성화하고 비용 분석 대시보드의 주요 기능을 확인했습니다.


## 태스크 2: Amazon SNS 토픽 생성 및 이메일 구독

> [!CONCEPT] Amazon SNS란?
>
> Amazon SNS(Simple Notification Service)는 메시지를 **구독자에게 자동으로 전달**하는 서비스입니다.
>
> - **토픽(Topic)**: 메시지를 발행하는 채널입니다. 하나의 토픽에 여러 구독자를 연결할 수 있습니다
> - **구독(Subscription)**: 토픽에 연결된 수신 엔드포인트입니다 (이메일, SMS, Lambda 등)
> - **프로토콜**: 이메일, HTTP/HTTPS, SMS, Lambda 등 다양한 전달 방식을 지원합니다
>
> 이 태스크에서는 AWS Budgets 알림을 이메일로 받기 위한 SNS 토픽을 생성합니다.

### 2.1 Amazon SNS 토픽 생성

6. AWS Management Console에 로그인한 후 상단 검색창에서 `SNS`를 검색하고 **Simple Notification Service**를 선택합니다.

7. Amazon SNS 콘솔의 왼쪽 메뉴에서 **Topics**를 선택합니다.

8. [[Create topic]] 버튼을 클릭합니다.

9. **Details** 섹션에서 **Type**으로 `Standard`를 선택합니다.

10. **Name**에 `MyBudgetAlerts`를 입력합니다.

11. **Display name**은 비워두고 아래로 스크롤하여 [[Create topic]] 버튼을 클릭합니다.

> [!NOTE]
> Standard 타입은 메시지 순서를 보장하지 않지만 높은 처리량을 제공합니다. 비용 알림처럼 순서가 중요하지 않은 경우에 적합합니다. FIFO 타입은 순서 보장이 필요한 경우에 사용합니다.

### 2.2 이메일 구독 추가

12. 생성된 토픽 상세 페이지에서 [[Create subscription]] 버튼을 클릭합니다.

13. **Protocol**에서 `Email`을 선택합니다.

14. **Endpoint**에 개인 이메일 주소를 입력합니다.

15. [[Create subscription]] 버튼을 클릭합니다.

16. 이메일 계정을 확인하고 "AWS Notification - Subscription Confirmation" 제목의 이메일에서 **Confirm subscription** 링크를 선택합니다.

> [!NOTE]
> SNS는 스팸 방지를 위해 이메일 구독 시 반드시 수신자의 동의를 확인합니다. 확인하지 않으면 알림을 받을 수 없습니다.

17. Amazon SNS 콘솔로 이동합니다. 왼쪽 메뉴에서 **Subscriptions**를 선택하고 구독 상태가 "Confirmed"로 변경되었는지 확인합니다.

### 2.3 Amazon SNS 토픽 ARN 복사

18. 왼쪽 메뉴에서 **Topics**를 선택하고 `MyBudgetAlerts` 토픽을 선택합니다.

19. 토픽 상세 페이지 상단의 **ARN**을 복사하여 메모장에 저장합니다.

> [!NOTE]
> ARN 형식은 `arn:aws:sns:ap-northeast-2:계정ID:MyBudgetAlerts`입니다. 태스크 3에서 Budget 알림 설정 시 사용합니다.

✅ **태스크 완료**: SNS 토픽이 생성되고 이메일 구독이 확인되었습니다.


## 태스크 3: AWS Budgets 생성 및 Amazon SNS 연결

> [!CONCEPT] AWS Budgets란?
>
> AWS Budgets는 AWS 비용과 사용량에 대한 **예산을 설정하고 모니터링**하는 서비스입니다.
>
> - **비용 예산(Cost Budget)**: 월별 지출 한도를 설정하고 초과 시 알림을 받습니다
> - **Actual 알림**: 실제 사용량이 임계값에 도달하면 알림을 보냅니다
> - **Forecasted 알림**: AWS가 예측한 월말 사용량이 임계값을 초과할 것으로 예상되면 알림을 보냅니다
>
> Amazon SNS와 연동하면 예산 초과 시 이메일, SMS 등으로 자동 알림을 받을 수 있습니다.

### 3.1 AWS Budgets 생성 시작

20. AWS Management Console에 로그인한 후 상단 검색창에서 `Billing and Cost Management`를 검색하고 **Billing and Cost Management**를 선택합니다.

21. Billing and Cost Management 콘솔의 왼쪽 메뉴에서 **Budgets**를 선택합니다.

22. [[Create budget]] 버튼을 클릭합니다.

23. **Budget setup**에서 `Customize (advanced)`를 선택합니다.

24. **Budget types**에서 `Cost budget`를 선택합니다.

25. [[Next]] 버튼을 클릭합니다.

### 3.2 예산 세부 정보 설정

26. **Details** 섹션의 **Budget name**에 `MyPersonalBudget`를 입력합니다.

27. **Set budget amount** 섹션에서 다음과 같이 설정합니다:

   - **Period**: `Monthly` 선택
   - **Budget renewal type**: `Recurring budget` 선택
   - **Start date**: 현재 월의 1일 (자동 설정됨)

28. **Budgeting method**에서 `Fixed`를 선택합니다.

29. **Enter your budgeted amount**에 `10.00`을 입력합니다.

> [!TIP]
> 실습용으로 $10의 낮은 금액을 설정하면 알림을 빨리 받아볼 수 있습니다. 실무에서는 월 평균 사용량의 110-120%로 설정하는 것을 권장합니다. 금액은 언제든 변경 가능합니다.

30. [[Next]] 버튼을 클릭합니다.

### 3.3 알림 설정 및 Amazon SNS 연결

31. [[Add an alert threshold]] 버튼을 클릭합니다.

32. 첫 번째 알림을 설정합니다:

   - **Threshold**: `80` 입력
   - 옆의 드롭다운에서 `% of budgeted amount` 선택
   - 다음 드롭다운에서 `Actual` 선택

33. **Notification preferences** 섹션에서 **Amazon SNS Alerts**에 태스크 2에서 복사한 SNS 토픽 ARN을 붙여넣습니다.

34. [[Add an alert threshold]] 버튼을 다시 클릭하여 두 번째 알림을 추가합니다.

35. 두 번째 알림을 설정합니다:

   - **Threshold**: `100` 입력
   - 옆의 드롭다운에서 `% of budgeted amount` 선택
   - 다음 드롭다운에서 `Forecasted` 선택
   - **Amazon SNS Alerts**에 동일한 SNS 토픽 ARN을 붙여넣습니다

> [!NOTE]
> Actual은 실제 사용량이 임계값에 도달하면 알림을 보내고, Forecasted는 AWS가 예측한 월말 사용량이 임계값을 초과할 것으로 예상되면 알림을 보냅니다. 두 가지를 함께 설정하면 더 효과적으로 비용을 관리할 수 있습니다.

36. [[Next]] 버튼을 클릭합니다.

### 3.4 AWS Budgets 생성 완료

37. **Attach actions** 페이지에서 [[Next]] 버튼을 클릭합니다.

38. **Review** 페이지에서 설정 내용을 확인합니다:

   - Budget 이름: MyPersonalBudget
   - 월 예산: $10.00
   - 알림: 80% Actual, 100% Forecasted
   - SNS 토픽: MyBudgetAlerts

39. [[Create budget]] 버튼을 클릭하여 예산을 생성합니다.

> [!SUCCESS]
> MyPersonalBudget이 생성되었습니다. 실제 사용량이 $8(80%)에 도달하거나 예측 사용량이 $10(100%)을 초과할 것으로 예상되면 이메일로 알림을 받게 됩니다.

✅ **태스크 완료**: AWS Budgets가 생성되고 SNS 알림이 연결되었습니다.


## 태스크 4: 알림 시스템 테스트 및 검증

> [!CONCEPT] Amazon SNS 테스트 메시지
>
> Amazon SNS 토픽에 직접 메시지를 발행하면 구독자에게 즉시 전달됩니다. 이를 통해 알림 경로가 정상적으로 작동하는지 Budget 알림을 기다리지 않고 바로 검증할 수 있습니다.

### 4.1 Amazon SNS 테스트 메시지 발송

40. AWS Management Console에 로그인한 후 상단 검색창에서 `SNS`를 검색하고 **Simple Notification Service**를 선택합니다.

41. Amazon SNS 콘솔의 왼쪽 메뉴에서 **Topics**를 선택합니다.

42. `MyBudgetAlerts` 토픽을 선택합니다.

43. [[Publish message]] 버튼을 클릭합니다.

44. **Subject**에 `Budget Alert Test`를 입력합니다.

45. **Message body**에 테스트 메시지를 입력합니다:

```text
This is a test message for budget alert notification.
Budget: MyPersonalBudget
Threshold: 80% Actual
```

46. [[Publish message]] 버튼을 클릭하여 테스트 메시지를 발송합니다.

47. 이메일 계정을 확인하고 "Budget Alert Test" 제목의 이메일이 수신되었는지 확인합니다.

> [!OUTPUT]
> ```
> 이메일 제목: Budget Alert Test
> 발신자: AWS Notifications <no-reply@sns.amazonaws.com>
> 본문:
> This is a test message for budget alert notification.
> Budget: MyPersonalBudget
> Threshold: 80% Actual
> ```

> [!TROUBLESHOOTING]
> 이메일이 수신되지 않는 경우:
>
> - 스팸/정크 메일 폴더를 확인합니다
> - Amazon SNS 콘솔에서 구독 상태가 "Confirmed"인지 확인합니다
> - 구독이 "PendingConfirmation" 상태라면 확인 이메일을 다시 요청합니다

### 4.2 AWS Budgets 대시보드 확인

48. AWS Management Console에 로그인한 후 상단 검색창에서 `Billing and Cost Management`를 검색하고 **Billing and Cost Management**를 선택합니다.

49. Billing and Cost Management 콘솔의 왼쪽 메뉴에서 **Budgets**를 선택합니다.

50. `MyPersonalBudget`를 선택합니다.

51. Budget 상세 페이지에서 다음 정보를 확인합니다:

   - **Budgeted amount**: $10.00
   - **Current spend**: 현재까지의 실제 사용량
   - **Forecasted spend**: 월말까지 예측 사용량
   - **% of budget**: 예산 대비 사용률

52. 아래로 스크롤하여 **Alerts** 섹션에서 설정된 알림 규칙을 확인합니다:

   - 80% Actual threshold → SNS 토픽 연결됨
   - 100% Forecasted threshold → SNS 토픽 연결됨

> [!SUCCESS]
> 예산 알림 시스템이 정상적으로 구성되었습니다. 실제 사용량이 $8에 도달하거나 예측 사용량이 $10을 초과하면 자동으로 이메일 알림을 받게 됩니다.

✅ **태스크 완료**: SNS 테스트 메시지 발송과 Budgets 대시보드를 통해 알림 시스템이 정상 작동함을 확인했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

### 태스크 1: 최종 확인

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

📊
AWS Cost Explorer
AWS 비용과 사용량을 서비스별, 리전별, 기간별로 시각적으로 분석하여 비용 추이를 파악합니다.

🛡️
비용 관리 습관
Cost Explorer를 월 1회 이상 확인하고, 예산 알림을 설정하여 예상치 못한 비용 증가를 조기에 발견합니다.
