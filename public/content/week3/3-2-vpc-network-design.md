---
title: 'VPC 네트워크 설계'
week: 3
session: 2
awsServices:
  - Amazon VPC
learningObjectives:
  - Amazon VPC와 서브넷을 설계하고 생성할 수 있습니다.
  - 라우팅 테이블을 통한 트래픽 흐름 제어 방법을 이해할 수 있습니다.
  - 인터넷 게이트웨이와 NAT 게이트웨이를 구성하여 외부 연결을 설정할 수 있습니다.
---

> [!TIP]
> 이 실습에서는 **AWS** 클라우드 네트워크 인프라를 처음부터 구축합니다. **VPC**를 생성하고 2개의 **가용 영역**에 **퍼블릭 서브넷**과 **프라이빗 서브넷**을 각각 배치합니다. **Internet Gateway**와 **NAT Gateway**를 생성하여 외부 통신을 설정하고, **라우팅 테이블**로 트래픽 흐름을 제어합니다. 마지막으로 **보안 그룹**을 생성하여 웹 계층과 데이터베이스 계층 간의 접근을 제어하는 다층 보안 아키텍처를 완성합니다.

> [!DOWNLOAD]
> 사전 구축되는 리소스가 없습니다.

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - VPC 네트워크 아키텍처
>
> <img src="/images/week3/3-2-architecture-diagram.svg" alt="VPC 네트워크 아키텍처 - 2개 AZ에 퍼블릭/프라이빗 서브넷, Internet Gateway, NAT Gateway, Web-SG/DB-SG 계층화 구조" class="guide-img-lg" />

> [!CONCEPT] Amazon VPC란?
>
> Amazon VPC(Virtual Private Cloud)는 AWS 클라우드 내에서 논리적으로 격리된 가상 네트워크입니다.
>
> - **VPC**: IP 주소 범위(CIDR)를 지정하여 생성하는 가상 네트워크입니다
> - **서브넷**: VPC 내에서 IP 주소 범위를 나눈 하위 네트워크입니다
> - **퍼블릭 서브넷**: Internet Gateway를 통해 인터넷과 직접 통신할 수 있는 서브넷입니다
> - **프라이빗 서브넷**: NAT Gateway를 통해 아웃바운드만 허용되는 보안이 강화된 서브넷입니다

## 태스크 1: Amazon VPC 생성

> [!CONCEPT] 가용 영역과 고가용성
>
> 2개의 가용 영역(AZ)에 서브넷을 분산 배치하면 하나의 AZ에 장애가 발생해도 다른 AZ에서 서비스를 계속할 수 있습니다. 이것이 AWS에서 고가용성을 구현하는 기본 패턴입니다.
>
> AWS는 기본적으로 다음과 같이 CIDR 블록을 자동 할당합니다:
> - Public subnets: `10.0.0.0/20`, `10.0.16.0/20`
> - Private subnets: `10.0.128.0/20`, `10.0.144.0/20`

### 1.1 Amazon VPC 콘솔 접속

1. AWS Management Console에 로그인한 후 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

> [!IMPORTANT]
> 이 실습은 **Asia Pacific (Seoul) ap-northeast-2** 리전에서 진행합니다. 콘솔 오른쪽 상단에서 리전이 올바르게 선택되었는지 확인합니다.

2. VPC 대시보드에서 [[Create VPC]] 버튼을 클릭합니다.

3. **Resources to create**에서 **VPC and more**를 선택합니다.

> [!CONCEPT] VPC and more로 생성되는 리소스
>
> "VPC and more" 옵션을 선택하면 다음 리소스들이 자동으로 생성됩니다:
>
> - **VPC 1개**: 논리적으로 격리된 가상 네트워크 공간 (10.0.0.0/16)
> - **서브넷 4개**: 
>   - Public 서브넷 2개 (각 AZ에 1개씩, 10.0.0.0/20, 10.0.16.0/20)
>   - Private 서브넷 2개 (각 AZ에 1개씩, 10.0.128.0/20, 10.0.144.0/20)
> - **Internet Gateway 1개**: 퍼블릭 서브넷의 인터넷 연결 담당
> - **NAT Gateway 1개**: 프라이빗 서브넷의 아웃바운드 인터넷 연결 담당
> - **라우팅 테이블 3개**: 
>   - Public용 1개 (0.0.0.0/0 → Internet Gateway)
>   - Private용 2개 (0.0.0.0/0 → NAT Gateway 또는 로컬만)
>
> 이 방식은 프로덕션 환경에 적합한 고가용성 네트워크를 빠르게 구축할 수 있습니다. 수동으로 하나씩 생성하는 것보다 실수를 줄이고 시간을 절약할 수 있습니다.

### 1.2 Amazon VPC 기본 설정

4. **Name tag auto-generation** 필드에서 **Auto-generate**를 체크하고 `CloudArchitect-Lab`을 입력합니다.

5. **IPv4 CIDR block**에 `10.0.0.0/16`을 입력합니다.

> [!TIP]
> CIDR 블록 크기는 /16과 /28 사이여야 합니다. `10.0.0.0/16`은 65,536개의 IP 주소를 제공합니다.

6. **IPv6 CIDR block**은 **No IPv6 CIDR block**을 선택합니다.

7. **Tenancy**에서 **Default**를 선택합니다.

### 1.3 가용 영역 및 서브넷 설정

8. **Number of Availability Zones (AZs)**에서 **2**를 선택합니다.

9. **Number of public subnets**에서 **2**를 선택합니다.

10. **Number of private subnets**에서 **2**를 선택합니다.

### 1.4 NAT 게이트웨이 및 추가 옵션 설정

11. **NAT gateways**에서 **In 1 AZ**를 선택합니다.

> [!TIP]
> NAT Gateway 옵션은 **None**, **In 1 AZ**, **1 per AZ** 세 가지입니다. 이 실습에서는 비용 절감을 위해 **In 1 AZ**를 선택합니다. **1 per AZ**는 각 가용 영역에 NAT Gateway를 배치하여 고가용성을 제공하지만 추가 비용이 발생합니다.

12. **VPC endpoints**에서 **None**을 선택합니다.

13. **DNS options**는 기본값을 유지합니다 (Enable DNS hostnames, Enable DNS resolution 모두 체크).

> [!NOTE]
> NAT Gateway는 시간당 요금과 데이터 처리 요금이 발생합니다. 실습 완료 후 반드시 리소스를 정리합니다.

### 1.5 Amazon VPC 생성

14. **Preview** 창에서 구성한 VPC 리소스 간의 관계를 확인합니다:
- VPC: CloudArchitect-Lab-vpc
- Subnets: 4개 (퍼블릭 2개, 프라이빗 2개)
- Route tables: 3개
- Network connections: Internet Gateway, NAT Gateway

15. [[Create VPC]] 버튼을 클릭합니다.

16. VPC 생성이 완료될 때까지 기다립니다.

> [!NOTE]
> VPC와 모든 네트워크 구성 요소 생성에 약 2-3분이 소요됩니다. 생성 진행 상황이 화면에 표시됩니다.

✅ **태스크 완료**: CloudArchitect-Lab VPC와 모든 네트워크 구성 요소가 생성되었습니다.


## 태스크 2: 생성된 리소스 확인

### 2.1 Amazon VPC 확인

17. VPC 콘솔에서 왼쪽 메뉴의 **Your VPCs**를 선택합니다.

18. **CloudArchitect-Lab-vpc**를 찾아 선택합니다.

19. 다음 정보를 확인합니다:
- **State**: Available
- **IPv4 CIDR**: `10.0.0.0/16`
- **DNS hostnames**: Enabled
- **DNS resolution**: Enabled

### 2.2 서브넷 확인

20. 왼쪽 메뉴에서 **Subnets**를 선택합니다.

21. 생성된 4개의 서브넷을 확인합니다:

| 서브넷 이름 | CIDR | 타입 | AZ |
|-------------|------|------|-----|
| CloudArchitect-Lab-subnet-public1-ap-northeast-2a | 10.0.0.0/20 | Public | 2a |
| CloudArchitect-Lab-subnet-public2-ap-northeast-2b | 10.0.16.0/20 | Public | 2b |
| CloudArchitect-Lab-subnet-private1-ap-northeast-2a | 10.0.128.0/20 | Private | 2a |
| CloudArchitect-Lab-subnet-private2-ap-northeast-2b | 10.0.144.0/20 | Private | 2b |

### 2.3 Internet Gateway 및 NAT Gateway 확인

22. 왼쪽 메뉴에서 **Internet gateways**를 선택합니다.

23. **CloudArchitect-Lab-igw**가 생성되고 **State**가 "Attached"인지 확인합니다.

24. 왼쪽 메뉴에서 **NAT gateways**를 선택합니다.

25. **CloudArchitect-Lab-nat-public1-ap-northeast-2a**가 생성되고 **State**가 "Available"인지 확인합니다.

> [!OUTPUT]
> ```
> Internet Gateway: CloudArchitect-Lab-igw → State: Attached
> NAT Gateway: CloudArchitect-Lab-nat-public1-ap-northeast-2a → State: Available
> ```

✅ **태스크 완료**: VPC, 서브넷, Internet Gateway, NAT Gateway가 모두 정상적으로 생성되었습니다.


## 태스크 3: 라우팅 테이블 확인

> [!CONCEPT] 라우팅 테이블이란?
>
> 라우팅 테이블은 네트워크 트래픽이 어디로 전달되어야 하는지 결정하는 규칙의 집합입니다.
>
> - **퍼블릭 라우팅 테이블**: `0.0.0.0/0 → Internet Gateway` 규칙이 있어 인터넷과 직접 통신합니다
> - **프라이빗 라우팅 테이블**: `0.0.0.0/0 → NAT Gateway` 규칙이 있어 아웃바운드만 허용됩니다
> - `10.0.0.0/16 → local` 규칙은 VPC 내부 통신을 위한 기본 규칙입니다

### 3.1 Public 라우팅 테이블 확인

26. 왼쪽 메뉴에서 **Route tables**를 선택합니다.

27. **CloudArchitect-Lab-rtb-public** 라우팅 테이블을 찾아 선택합니다.

28. **Routes** 탭에서 다음 라우트를 확인합니다:

| 목적지 | 대상 | 설명 |
|--------|------|------|
| 10.0.0.0/16 | local | VPC 내부 통신 |
| 0.0.0.0/0 | igw-xxxxx | 인터넷 게이트웨이 |

> [!NOTE] "local" 경로의 의미
>
> `10.0.0.0/16 → local` 경로는 VPC 내부 통신을 위한 기본 규칙입니다:
>
> - **10.0.0.0/16 범위 내의 모든 IP**는 라우터를 거치지 않고 VPC 내부에서 직접 통신합니다
> - 예: 10.0.0.5 인스턴스가 10.0.128.10 인스턴스와 통신할 때 Internet Gateway나 NAT Gateway를 거치지 않습니다
> - 이 규칙은 VPC 생성 시 자동으로 추가되며 삭제할 수 없습니다
> - 서브넷이 Public이든 Private이든 같은 VPC 내에서는 항상 직접 통신이 가능합니다

29. **Subnet associations** 탭에서 2개의 퍼블릭 서브넷이 연결되어 있는지 확인합니다.

### 3.2 Private 라우팅 테이블 확인

30. **CloudArchitect-Lab-rtb-private1-ap-northeast-2a** 라우팅 테이블을 찾아 선택합니다.

31. **Routes** 탭에서 다음 라우트를 확인합니다:

| 목적지 | 대상 | 설명 |
|--------|------|------|
| 10.0.0.0/16 | local | VPC 내부 통신 |
| 0.0.0.0/0 | nat-xxxxx | NAT 게이트웨이 |

> [!NOTE] Private 서브넷의 라우팅
>
> Private 서브넷의 라우팅 테이블도 `10.0.0.0/16 → local` 규칙을 가지고 있습니다:
>
> - VPC 내부 통신(10.0.0.0/16)은 `local`로 직접 연결됩니다
> - 외부 인터넷 통신(0.0.0.0/0)은 NAT Gateway를 통해 아웃바운드만 가능합니다
> - 즉, Private 서브넷의 인스턴스는 같은 VPC의 Public 서브넷 인스턴스와 자유롭게 통신할 수 있습니다

32. **Subnet associations** 탭에서 프라이빗 서브넷 1개가 연결되어 있는지 확인합니다.

> [!NOTE]
> In 1 AZ NAT Gateway를 선택한 경우, 하나의 프라이빗 서브넷만 이 라우팅 테이블을 사용합니다. 다른 프라이빗 서브넷은 별도의 라우팅 테이블(**CloudArchitect-Lab-rtb-private2-ap-northeast-2b**)을 가지며, NAT Gateway 없이 VPC 내부 통신만 가능합니다.

> [!TIP]
> 퍼블릭 서브넷과 프라이빗 서브넷의 차이는 라우팅 테이블에 있습니다. `0.0.0.0/0`이 Internet Gateway로 향하면 퍼블릭, NAT Gateway로 향하면 프라이빗입니다.

✅ **태스크 완료**: 퍼블릭/프라이빗 라우팅 테이블의 경로를 확인했습니다.


## 태스크 4: 보안 그룹 생성

> [!CONCEPT] 보안 그룹 계층화
>
> DB Security Group의 Source를 Web Security Group으로 지정하면, 웹 서버에서만 데이터베이스에 접근할 수 있습니다. 이렇게 보안 그룹을 계층화하면 외부에서 직접 DB에 접근하는 것을 원천 차단할 수 있습니다.

### 4.1 Web Server Security Group 생성

33. 상단 검색창에 `EC2`를 검색하고 **EC2**를 선택합니다.

34. EC2 콘솔에서 왼쪽 메뉴의 **Network & Security** 섹션 아래의 **Security Groups**를 선택합니다.

35. [[Create security group]] 버튼을 클릭합니다.

36. **Security group name** 필드에 `CloudArchitect-Lab-Web-SG`를 입력합니다.

37. **Description** 필드에 `Web server security group for Lab04`를 입력합니다.

38. **VPC**에서 **CloudArchitect-Lab-vpc**를 선택합니다.

### 4.2 Web Security Group 인바운드 규칙 설정

39. **Inbound rules** 섹션에서 [[Add rule]] 버튼을 클릭합니다.

40. 다음 규칙을 추가합니다:

| Type | Source type | Source | Description | 용도 |
|------|-------------|--------|-------------|------|
| HTTP (80) | Anywhere-IPv4 | 0.0.0.0/0 | Allow HTTP | 웹 접근 허용 |
| HTTPS (443) | Anywhere-IPv4 | 0.0.0.0/0 | Allow HTTPS | 보안 웹 접근 허용 |
| SSH (22) | My IP | (자동 입력) | Allow SSH | 관리 접근 허용 |

> [!TIP]
> Type을 선택하면 Protocol과 Port range는 자동으로 설정됩니다. Source type을 선택하면 Source 값이 자동으로 입력되거나 선택할 수 있습니다. Description은 선택 사항이지만 규칙의 용도를 명확히 하기 위해 입력하는 것이 좋습니다.

41. 각 규칙을 [[Add rule]] 버튼으로 추가합니다.

42. [[Create security group]] 버튼을 클릭합니다.

### 4.3 Database Security Group 생성

43. [[Create security group]] 버튼을 클릭합니다.

44. **Security group name** 필드에 `CloudArchitect-Lab-DB-SG`를 입력합니다.

45. **Description** 필드에 `Database security group for Lab04`를 입력합니다.

46. **VPC**에서 **CloudArchitect-Lab-vpc**를 선택합니다.

47. **Inbound rules** 섹션에서 [[Add rule]] 버튼을 클릭합니다.

48. **Type**에서 **MySQL/Aurora**를 선택합니다.

49. **Source type**에서 **Custom**을 선택하고, **Source** 필드에서 **CloudArchitect-Lab-Web-SG**를 검색하여 선택합니다.

50. **Description** 필드에 `Allow MySQL from Web SG`를 입력합니다.

51. [[Create security group]] 버튼을 클릭합니다.

✅ **태스크 완료**: Web-SG와 DB-SG 보안 그룹이 계층화된 구조로 생성되었습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요. 특히 **NAT Gateway**는 시간당 요금이 발생하므로 빠르게 삭제해야 합니다.

이 실습에서는 자동 정리 스크립트가 제공되지 않으므로, 아래 단계에 따라 AWS Management Console에서 수동으로 리소스를 삭제합니다.

> [!IMPORTANT]
> 삭제 순서가 중요합니다. 의존 관계가 있는 리소스는 먼저 삭제해야 다음 리소스를 삭제할 수 있습니다. 아래 순서를 따라주세요.

### 태스크 1: 보안 그룹 삭제

1. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

2. 왼쪽 메뉴의 **Network & Security** 섹션에서 **Security Groups**를 선택합니다.

3. **CloudArchitect-Lab-DB-SG**를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

> [!TIP]
> DB 보안 그룹을 먼저 삭제해야 합니다. DB 보안 그룹이 Web 보안 그룹을 Source로 참조하고 있기 때문에, Web 보안 그룹을 먼저 삭제하면 오류가 발생합니다.

4. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

5. **CloudArchitect-Lab-Web-SG**를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

6. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

✅ **태스크 완료**: 2개의 보안 그룹이 삭제되었습니다.

### 태스크 2: NAT Gateway 삭제

7. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

8. 왼쪽 메뉴에서 **NAT gateways**를 선택합니다.

9. **CloudArchitect-Lab-nat-public1-ap-northeast-2a**를 선택하고 **Actions** > **Delete NAT gateway**를 선택합니다.

10. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

> [!NOTE]
> NAT Gateway 삭제에는 약 1-2분이 소요됩니다. **State**가 "Deleted"로 변경될 때까지 기다립니다.

✅ **태스크 완료**: NAT Gateway가 삭제되었습니다.

### 태스크 3: Elastic IP 주소 해제

> [!CONCEPT] Elastic IP 해제
>
> NAT Gateway를 생성하면 Elastic IP(탄력적 IP)가 자동으로 할당됩니다. NAT Gateway를 삭제해도 Elastic IP는 자동으로 해제되지 않으며, 사용하지 않는 Elastic IP에는 요금이 부과됩니다.

11. 왼쪽 메뉴에서 **Elastic IPs**를 선택합니다.

12. NAT Gateway에 할당되었던 Elastic IP를 선택합니다 (Name 태그에 `CloudArchitect-Lab`이 포함된 항목).

> [!TIP]
> **Association ID** 열이 비어 있는 Elastic IP가 NAT Gateway 삭제 후 해제 대상입니다.

13. **Actions** > **Release Elastic IP addresses**를 선택합니다.

14. 확인 대화 상자에서 [[Release]]를 클릭합니다.

✅ **태스크 완료**: Elastic IP가 해제되었습니다.

### 태스크 4: Amazon VPC 삭제

> [!NOTE]
> VPC를 삭제하면 연결된 서브넷, 라우팅 테이블, Internet Gateway가 함께 삭제됩니다. 단, NAT Gateway와 보안 그룹은 사전에 삭제해야 합니다.

15. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

16. **CloudArchitect-Lab-vpc**를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

17. 삭제 대화 상자에서 함께 삭제될 리소스 목록을 확인합니다:
- 서브넷 4개 (퍼블릭 2개, 프라이빗 2개)
- 라우팅 테이블
- Internet Gateway (**CloudArchitect-Lab-igw**)

18. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

✅ **태스크 완료**: VPC와 연관 리소스가 모두 삭제되었습니다.

### 태스크 5: 최종 확인

19. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

20. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

21. 다음과 같이 검색 조건을 설정합니다:
- **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
- **Resource types**: `All supported resource types`
- **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

> [!TIP]
> 이 실습에서는 VPC 생성 시 **Name tag auto-generation**에 `CloudArchitect-Lab`을 입력했으므로, 모든 리소스에 `Name` 태그가 `CloudArchitect-Lab-*` 형식으로 자동 부여되었습니다. 이 값으로 검색하면 남은 리소스를 확인할 수 있습니다.

22. [[Search resources]]를 클릭합니다.

23. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

24. 검색된 리소스가 있다면 해당 서비스 콘솔로 이동하여 삭제합니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🌐
VPC와 CIDR 블록
VPC는 논리적으로 격리된 가상 네트워크이며, CIDR 블록(예: 10.0.0.0/16)으로 IP 주소 범위를 정의합니다.

📍
서브넷과 가용 영역
서브넷은 VPC를 더 작은 네트워크로 나눈 것이며, 각 서브넷은 하나의 가용 영역(AZ)에 속합니다.

🌍
퍼블릭 vs 프라이빗 서브넷
퍼블릭 서브넷은 Internet Gateway로 인터넷과 직접 통신하고, 프라이빗 서브넷은 NAT Gateway를 통해 아웃바운드만 가능합니다.

🗺️
라우팅 테이블
서브넷의 트래픽이 어디로 전달될지 결정하는 규칙 집합으로, 목적지 IP와 타겟(IGW, NAT 등)을 매핑합니다.

🚪
Internet Gateway와 NAT Gateway
IGW는 퍼블릭 서브넷의 양방향 인터넷 통신을, NAT Gateway는 프라이빗 서브넷의 아웃바운드 통신을 담당합니다.

🔒
보안 그룹
인스턴스 레벨의 가상 방화벽으로, 인바운드/아웃바운드 트래픽을 제어하며 상태 저장(Stateful) 방식으로 동작합니다.
