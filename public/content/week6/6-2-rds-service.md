---
title: 'RDS 서비스 활용'
week: 6
session: 2
awsServices:
  - Amazon RDS
learningObjectives:
  - Amazon RDS의 핵심 개념과 지원되는 엔진을 이해할 수 있습니다.
  - Amazon RDS 인스턴스를 생성하고 구성할 수 있습니다.
  - Amazon RDS의 고가용성(Multi-AZ) 및 백업 전략을 설명할 수 있습니다.
---

> [!DOWNLOAD]
> [week6-2-rds-service.zip](/files/week6/week6-2-rds-service.zip)
>
> - `setup-6-2-student.sh` - 사전 환경 구축 스크립트 (VPC, Public/Private Subnets, Route Table, Security Group, EC2 인스턴스 등 생성)
> - `cleanup-6-2-student.sh` - 리소스 정리 스크립트
> - 태스크 0: 사전 환경 구축 (setup-6-2-student.sh 실행)

> [!NOTE]
> 이 실습에서는 Amazon RDS를 사용하여 관리형 데이터베이스 서비스를 구축하고 EC2 인스턴스를 통해 데이터베이스에 접속하는 방법을 학습합니다. RDS 인스턴스는 Free tier 또는 Sandbox 템플릿을 사용하며, 실습 후 반드시 리소스를 정리합니다.

> [!ARCHITECTURE] 실습 아키텍처 다이어그램 - RDS 서비스 아키텍처
>
> <img src="/images/week6/6-2-architecture-diagram.svg" alt="RDS 서비스 아키텍처 - VPC 내 Public Subnet의 EC2 Bastion Host에서 Private Subnet의 RDS MySQL로 접속하는 구조" class="guide-img-lg" />

> [!CONCEPT] Amazon RDS란?
>
> Amazon RDS(Relational Database Service)는 AWS에서 제공하는 **완전 관리형 관계형 데이터베이스** 서비스입니다.
>
> - **관리형 서비스**: 데이터베이스 설치, 패치, 백업을 AWS가 자동으로 관리합니다
> - **지원 엔진**: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, Aurora 등 6가지 엔진을 지원합니다
> - **고가용성**: Multi-AZ 배포를 통해 장애 시 자동 복구가 가능합니다
> - **보안**: VPC 내 Private 서브넷에 배치하여 인터넷에서 직접 접근을 차단합니다
>
> 이 실습에서는 MySQL 엔진으로 RDS 인스턴스를 생성하고, EC2 Bastion Host를 통해 접속합니다.

## 태스크 0: 사전 환경 구축

> [!NOTE]
> 실습을 시작하기 전에 AWS 콘솔 우측 상단에서 현재 리전을 확인하세요. 올바른 리전에서 작업하고 있는지 반드시 확인해야 합니다.

1. 위 DOWNLOAD 섹션에서 `week6-2-rds-service.zip` 파일을 다운로드합니다.

2. AWS Management Console에 로그인한 후 상단의 **CloudShell** 아이콘을 선택하여 CloudShell을 실행합니다.

3. CloudShell 상단의 **Actions** > `Upload file`을 선택하여 다운로드한 ZIP 파일을 업로드합니다.

4. 업로드가 완료되면 다음 명령어로 압축을 해제합니다:

```bash
unzip week6-2-rds-service.zip
```

5. setup 스크립트에 실행 권한을 부여하고 실행합니다:

```bash
chmod +x setup-6-2-student.sh
./setup-6-2-student.sh
```

6. 스크립트 실행 중 생성 계획이 표시되면 `y`를 입력하여 진행합니다.

> [!NOTE]
> 사전 환경 구축에 약 3-5분이 소요됩니다. 스크립트가 완료될 때까지 기다립니다.

7. 스크립트가 완료되면 출력 메시지에서 다음 리소스가 생성되었는지 확인합니다:

| 리소스 | 이름 |
|--------|------|
| VPC | CloudArchitect-Lab-VPC |
| Internet Gateway | CloudArchitect-Lab-IGW |
| Public Subnet | CloudArchitect-Lab-Public-Subnet |
| Private Subnet 1 | CloudArchitect-Lab-Private-Subnet-1 |
| Private Subnet 2 | CloudArchitect-Lab-Private-Subnet-2 |
| Route Table | CloudArchitect-Lab-Public-RT |
| Security Group | CloudArchitect-Lab-EC2-SG |
| EC2 인스턴스 | CloudArchitect-Lab-RDS-Client |

✅ **태스크 완료**: 사전 환경 구축이 완료되었습니다.


## 태스크 1: 사전 구축 환경 확인

> [!CONCEPT] Bastion Host 아키텍처
>
> RDS 인스턴스는 보안을 위해 **Private 서브넷**에 배치합니다. 인터넷에서 직접 접근할 수 없으므로, 같은 VPC 내 **Public 서브넷**에 위치한 EC2 인스턴스(Bastion Host)를 통해 접속합니다.
>
> - **Public 서브넷**: 인터넷 접근이 가능한 서브넷으로, Bastion Host EC2가 위치합니다
> - **Private 서브넷**: 인터넷에서 직접 접근할 수 없는 서브넷으로, RDS 인스턴스가 위치합니다
> - **DB 서브넷 그룹**: Multi-AZ 배포를 위해 최소 2개 AZ의 Private 서브넷을 묶은 그룹입니다

### 1.1 사전 구축된 VPC 확인

8. AWS Management Console에 로그인한 후 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

9. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

10. `CloudArchitect-Lab-VPC`가 "Available" 상태이고 CIDR 블록이 `10.0.0.0/16`으로 설정되어 있는지 확인합니다.

### 1.2 Private 서브넷 확인

11. 왼쪽 메뉴에서 **Subnets**를 선택합니다.

12. `CloudArchitect-Lab-Private-Subnet-1`과 `CloudArchitect-Lab-Private-Subnet-2`가 서로 다른 가용 영역에 생성되어 있는지 확인합니다.

> [!TIP]
> RDS Multi-AZ 배포를 위해서는 최소 2개의 서로 다른 가용 영역에 서브넷이 필요합니다. 사전 구축 스크립트가 이를 자동으로 구성했습니다.

### 1.3 Bastion Host EC2 인스턴스 확인

13. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

14. 왼쪽 메뉴에서 **Instances**를 선택합니다.

15. `CloudArchitect-Lab-RDS-Client` 인스턴스의 상태가 "Running"인지 확인합니다.

16. 인스턴스의 **Public IPv4 address**가 할당되어 있는지 확인합니다.

✅ **태스크 완료**: VPC, Private 서브넷 2개, Bastion Host EC2 인스턴스가 정상적으로 구축되어 있습니다.


## 태스크 2: Amazon RDS DB 서브넷 그룹 생성

> [!CONCEPT] DB 서브넷 그룹이란?
>
> DB 서브넷 그룹은 RDS 인스턴스가 배치될 수 있는 서브넷들의 모음입니다. Multi-AZ 배포를 위해 **최소 2개의 서로 다른 가용 영역**에 있는 서브넷을 포함해야 합니다. RDS는 이 그룹 내의 서브넷 중 하나에 인스턴스를 배치합니다.

### 2.1 Amazon RDS DB 서브넷 그룹 생성 시작

17. 상단 검색창에서 `RDS`를 검색하고 **RDS**를 선택합니다.

18. RDS 콘솔의 왼쪽 메뉴에서 **Subnet groups**를 선택합니다. (왼쪽 메뉴에 보이지 않으면 메뉴를 아래로 스크롤합니다.)

19. [[Create DB subnet group]] 버튼을 클릭합니다.

### 2.2 Amazon RDS DB 서브넷 그룹 설정

20. **Name**에 `cloudarchitect-lab-db-subnet-group`을 입력합니다.

21. **Description**에 `CloudArchitect Lab DB Subnet Group`을 입력합니다.

22. **VPC**에서 `CloudArchitect-Lab-VPC`를 선택합니다.

23. **Add subnets** 섹션에서 다음 2개의 가용 영역과 서브넷을 선택합니다:
    - **Availability Zones**: `ap-northeast-2a`와 `ap-northeast-2c`를 선택합니다
    - **Subnets**: `CloudArchitect-Lab-Private-Subnet-1` (ap-northeast-2a)과 `CloudArchitect-Lab-Private-Subnet-2` (ap-northeast-2c)를 선택합니다

24. [[Create]] 버튼을 클릭합니다.

✅ **태스크 완료**: Multi-AZ 배치를 위한 DB 서브넷 그룹이 생성되었습니다.


## 태스크 3: Amazon RDS 보안 그룹 생성

> [!CONCEPT] RDS 보안 그룹
>
> RDS 인스턴스에 접근할 수 있는 트래픽을 제어하는 가상 방화벽입니다. MySQL의 기본 포트는 **3306**이며, 같은 VPC 내의 EC2 인스턴스에서만 접근할 수 있도록 인바운드 규칙을 설정합니다.

### 3.1 보안 그룹 생성

25. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

26. 왼쪽 메뉴에서 **Security Groups**를 선택합니다.

27. [[Create security group]] 버튼을 클릭합니다.

28. **Security group name**에 `CloudArchitect-Lab-RDS-SG`를 입력합니다.

29. **Description**에 `CloudArchitect Lab RDS Security Group`을 입력합니다.

30. **VPC**에서 `CloudArchitect-Lab-VPC`를 선택합니다.

### 3.2 인바운드 규칙 설정

31. **Inbound rules** 섹션에서 [[Add rule]] 버튼을 클릭합니다.

32. 다음과 같이 설정합니다:

| 항목 | 값 |
|------|-----|
| Type | MySQL/Aurora |
| Port range | 3306 |
| Source | `CloudArchitect-Lab-EC2-SG` (EC2 보안 그룹 선택) |

> [!TIP]
> Source에 IP 대신 EC2 보안 그룹을 지정하면, 해당 보안 그룹이 연결된 인스턴스에서만 접근이 허용됩니다. IP가 변경되어도 규칙을 수정할 필요가 없어 관리가 편리합니다.

33. [[Create security group]] 버튼을 클릭합니다.

✅ **태스크 완료**: VPC 내부의 EC2에서만 MySQL 포트(3306)로 접근할 수 있는 보안 그룹이 생성되었습니다.


## 태스크 4: Amazon RDS MySQL 인스턴스 생성

> [!CONCEPT] RDS 인스턴스 생성 옵션
>
> RDS 인스턴스를 생성할 때 주요 설정 항목은 다음과 같습니다:
>
> - **엔진 타입**: MySQL, PostgreSQL, MariaDB 등 사용할 데이터베이스 엔진을 선택합니다
> - **템플릿**: Free tier(무료), Sandbox(연결 계정), Production(운영) 중 선택합니다
> - **인스턴스 클래스**: CPU, 메모리 사양을 결정합니다 (실습에서는 db.t4g.micro 사용)
> - **스토리지**: 데이터 저장 공간 크기와 타입을 설정합니다
> - **네트워크**: VPC, 서브넷 그룹, 보안 그룹을 지정합니다

### 4.1 RDS 인스턴스 생성 시작

34. 상단 검색창에서 `RDS`를 검색하고 **RDS**를 선택합니다.

35. 왼쪽 메뉴에서 **Databases**를 선택합니다.

36. [[Create database]] 버튼을 클릭합니다.

37. **Choose a database creation method**에서 **Standard create**를 선택합니다.

### 4.2 엔진 및 템플릿 설정

38. **Engine type**에서 **MySQL**을 선택합니다.

39. **Templates**에서 **Free tier** (신규 계정) 또는 **Sandbox** (연결된 계정)를 선택합니다.

> [!WARNING]
> **Dev/Test** 또는 **Production** 템플릿을 선택하면 Multi-AZ DB Cluster로 설정되어 높은 비용이 발생합니다. 반드시 **Free tier** 또는 **Sandbox**를 선택합니다.

### 4.3 인스턴스 기본 설정

40. **DB instance identifier**에 `cloudarchitect-lab-mysql`을 입력합니다.

41. **Master username**에 `admin`을 입력합니다.

42. **Master password**에 `CloudArchitect123!`을 입력합니다.

43. **Confirm master password**에 동일한 패스워드를 입력합니다.

### 4.4 네트워크 설정

44. **Connectivity** 섹션으로 스크롤합니다.

45. **Compute resource**에서 `Don't connect to an EC2 compute resource`를 선택합니다.

46. **Virtual private cloud (VPC)**에서 `CloudArchitect-Lab-VPC`를 선택합니다.

47. **DB subnet group**에서 `cloudarchitect-lab-db-subnet-group`을 선택합니다.

48. **Public access**에서 `No`를 선택합니다.

49. **VPC security group (firewall)**에서 `Choose existing`을 선택합니다.

50. **Existing VPC security groups** 드롭다운에서 `CloudArchitect-Lab-RDS-SG`를 선택합니다.

51. `default` 보안 그룹 옆의 [[X]] 버튼을 클릭하여 제거합니다.

### 4.5 추가 설정 및 생성

52. 페이지 최하단으로 스크롤하여 **Additional configuration** 섹션을 찾습니다. 접힌 상태라면 섹션 제목을 클릭하여 확장합니다.

54. **Database options**에서:
    - **Initial database name**: `cloudarchitect`를 입력합니다

> [!NOTE]
> Initial database name을 지정하지 않으면 RDS 인스턴스에 기본 데이터베이스가 생성되지 않습니다. 연결 후 수동으로 데이터베이스를 생성해야 합니다.

55. **Deletion protection** 섹션에서:
    - ☐ **Enable deletion protection**: 체크를 해제합니다

> [!WARNING]
> 실습 환경이므로 Deletion protection을 비활성화합니다. 프로덕션 환경에서는 반드시 활성화해야 합니다.

> [!IMPORTANT]
> cleanup 시 문제를 방지하기 위해 다음 설정을 반드시 확인합니다:
>
> - **DB parameter group**: `default.mysql8.0` (기본값) 유지
> - **Option group**: `default:mysql-8-0` (기본값) 유지
> - **Log exports**: 모든 체크박스 해제 (CloudWatch Log Groups 자동 생성 방지)

56. 모든 설정을 확인한 후 [[Create database]] 버튼을 클릭합니다.

> [!NOTE]
> RDS MySQL 인스턴스 생성에는 약 10-15분이 소요됩니다. 생성이 완료될 때까지 기다립니다. 대기하는 동안 RDS 콘솔에서 인스턴스 상태가 "Creating"에서 "Available"로 변경되는 과정을 확인할 수 있습니다.

✅ **태스크 완료**: RDS MySQL 인스턴스 생성이 시작되었습니다.


## 태스크 5: 데이터베이스 연결 및 테스트

> [!CONCEPT] Private 서브넷 RDS 접속 방법
>
> RDS가 Private 서브넷에 있으므로 인터넷에서 직접 접속할 수 없습니다. 같은 VPC 내의 EC2 인스턴스(Bastion Host)를 통해서만 접속할 수 있습니다. CloudShell은 VPC 외부에 있어 직접 접속이 불가능합니다.

### 5.1 Amazon RDS 인스턴스 상태 확인

57. RDS 콘솔에서 왼쪽 메뉴의 **Databases**를 선택합니다.

58. `cloudarchitect-lab-mysql` 인스턴스의 상태가 "Available"로 변경될 때까지 기다립니다.

59. 인스턴스 이름을 선택하여 세부 정보를 확인합니다.

60. **Connectivity & security** 탭에서 **Endpoint**를 복사하여 메모장에 저장합니다.

> [!NOTE]
> 엔드포인트 형식: `cloudarchitect-lab-mysql.xxxxx.ap-northeast-2.rds.amazonaws.com`. 이 값은 EC2에서 RDS에 접속할 때 사용합니다.

### 5.2 Amazon EC2 인스턴스를 통한 RDS 접속

61. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

62. 왼쪽 메뉴에서 **Instances**를 선택합니다.

63. `CloudArchitect-Lab-RDS-Client` 인스턴스를 선택합니다.

64. [[Connect]] 버튼을 클릭합니다.

65. **EC2 Instance Connect** 탭에서 [[Connect]] 버튼을 클릭합니다.

66. MySQL 클라이언트 설치 상태를 확인합니다:

```bash
mysql --version
```

> [!TROUBLESHOOTING]
> `mysql` 명령어가 없다는 오류가 발생하면 다음 명령어로 수동 설치합니다:
> ```bash
> sudo dnf install -y mariadb105
> ```

67. RDS 인스턴스에 연결합니다 (엔드포인트를 실제 값으로 교체):

```bash
mysql -h [RDS-엔드포인트] -u admin -p
```

68. 패스워드 입력 프롬프트가 나타나면 `CloudArchitect123!`을 입력합니다.

### 5.3 MySQL 연결 확인

69. MySQL 연결이 성공하면 다음과 같은 프롬프트가 표시됩니다:

> [!OUTPUT]
> ```
> Welcome to the MySQL monitor. Commands end with ; or \g.
> Your MySQL connection id is 8
> Server version: 8.0.35 Source distribution
> mysql>
> ```

70. 연결 상태와 데이터베이스 정보를 확인합니다:

```sql
SELECT USER(), DATABASE(), VERSION();
SHOW DATABASES;
USE cloudarchitect;
```

### 5.4 테이블 생성 및 데이터 조작

71. 샘플 테이블을 생성합니다:

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    age INT,
    major VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DESCRIBE users;
```

72. 샘플 데이터를 삽입하고 조회합니다:

```sql
INSERT INTO users (name, email, age, major) VALUES 
('김철수', 'kim@example.com', 25, '컴퓨터공학과'),
('이영희', 'lee@example.com', 23, '정보시스템학과'),
('박민준', 'park@example.com', 27, '소프트웨어공학과'),
('최지원', 'choi@example.com', 21, '데이터사이언스학과');

SELECT * FROM users;
SELECT name, email, major FROM users WHERE age >= 25;
SELECT COUNT(*) as total_users FROM users;
```

> [!OUTPUT]
> ```
> +----+-----------+--------------------+------+----------------------------+---------------------+
> | id | name      | email              | age  | major                      | created_at          |
> +----+-----------+--------------------+------+----------------------------+---------------------+
> |  1 | 김철수    | kim@example.com    |   25 | 컴퓨터공학과               | 2025-xx-xx xx:xx:xx |
> |  2 | 이영희    | lee@example.com    |   23 | 정보시스템학과             | 2025-xx-xx xx:xx:xx |
> |  3 | 박민준    | park@example.com   |   27 | 소프트웨어공학과           | 2025-xx-xx xx:xx:xx |
> |  4 | 최지원    | choi@example.com   |   21 | 데이터사이언스학과         | 2025-xx-xx xx:xx:xx |
> +----+-----------+--------------------+------+----------------------------+---------------------+
> ```

### 5.5 연결 종료

73. MySQL 세션을 종료합니다:

```sql
EXIT;
```

74. EC2 Instance Connect 세션도 종료합니다:

```bash
exit
```

✅ **태스크 완료**: EC2 Bastion Host를 통해 Private 서브넷의 RDS MySQL에 성공적으로 연결하고 데이터베이스 작업을 수행했습니다.

## 리소스 정리

> [!WARNING]
> 실습 완료 후 **반드시** 리소스를 정리하여 불필요한 비용을 방지하세요. 특히 **RDS 인스턴스**는 시간당 요금이 발생합니다.

### 방법 1: CloudShell에서 정리 스크립트 실행

1. AWS Management Console 상단의 **CloudShell** 아이콘을 선택합니다.

2. 다음 명령어로 정리 스크립트를 실행합니다:

```bash
./cleanup-6-2-student.sh
```

3. 삭제 확인 메시지가 표시되면 `y`를 입력하여 진행합니다.

4. 스크립트가 다음 리소스를 자동으로 삭제합니다:
   - RDS 인스턴스 (`cloudarchitect-lab-mysql`)
   - DB Subnet Group (`cloudarchitect-lab-db-subnet-group`)
   - EC2 인스턴스 (`CloudArchitect-Lab-RDS-Client`)
   - Security Groups, VPC 및 관련 리소스

> [!NOTE]
> RDS 인스턴스 삭제에는 약 5-10분이 소요됩니다. 스크립트가 완료될 때까지 기다려주세요.

### 방법 2: 수동 삭제 (스크립트 실행이 불가능한 경우)

> [!IMPORTANT]
> RDS 인스턴스를 먼저 삭제해야 DB Subnet Group과 Security Group을 삭제할 수 있습니다.

#### 태스크 1: Amazon RDS 인스턴스 삭제

1. 상단 검색창에서 `RDS`를 검색하고 **RDS**를 선택합니다.

2. 왼쪽 메뉴에서 **Databases**를 선택합니다.

3. `cloudarchitect-lab-mysql`을 선택하고 **Actions** > **Delete**를 선택합니다.

4. **Create final snapshot** 체크를 해제합니다.

5. **I acknowledge that upon instance deletion, automated backups, including system snapshots and point-in-time recovery, will no longer be available.** 체크박스를 선택합니다.

6. 확인 필드에 `delete me`를 입력하고 [[Delete]]를 클릭합니다.

> [!NOTE]
> RDS 인스턴스 삭제에는 약 5-10분이 소요됩니다. **Status**가 "Deleting"으로 변경되면 다음 단계를 진행할 수 있습니다.

#### 태스크 2: DB Subnet Group 삭제

7. RDS 인스턴스 삭제가 완료된 후, 왼쪽 메뉴에서 **Subnet groups**를 선택합니다.

8. `cloudarchitect-lab-db-subnet-group`을 선택하고 **Delete**를 클릭합니다.

9. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 3: Amazon EC2 인스턴스 종료

10. 상단 검색창에서 `EC2`를 검색하고 **EC2**를 선택합니다.

11. 왼쪽 메뉴에서 **Instances**를 선택합니다.

12. `CloudArchitect-Lab-RDS-Client` 인스턴스를 선택합니다.

13. **Instance state** > **Terminate instance**를 선택합니다.

14. 확인 대화 상자에서 [[Terminate]]를 클릭합니다.

#### 태스크 4: Security Group 삭제

15. 왼쪽 메뉴의 **Network & Security** 섹션에서 **Security Groups**를 선택합니다.

16. `CloudArchitect-Lab-RDS-SG`를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

17. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

18. `CloudArchitect-Lab-EC2-SG`를 선택하고 **Actions** > **Delete security groups**를 선택합니다.

19. 확인 대화 상자에서 [[Delete]]를 클릭합니다.

#### 태스크 5: Amazon VPC 삭제

20. 상단 검색창에서 `VPC`를 검색하고 **VPC**를 선택합니다.

21. 왼쪽 메뉴에서 **Your VPCs**를 선택합니다.

22. `CloudArchitect-Lab-VPC`를 선택하고 **Actions** > **Delete VPC**를 선택합니다.

23. 확인 필드에 `delete`를 입력하고 [[Delete]]를 클릭합니다.

#### 태스크 6: 최종 확인

24. 상단 검색창에서 `Resource Groups & Tag Editor`를 검색하고 **Resource Groups & Tag Editor**를 선택합니다.

25. 왼쪽 메뉴에서 **Tag Editor**를 선택합니다.

26. 다음과 같이 검색 조건을 설정합니다:
   - **Regions**: `Asia Pacific (Seoul) ap-northeast-2`
   - **Resource types**: `All supported resource types`
   - **Tags**: Tag key에 `Name`을 선택하고, Tag value에 `CloudArchitect-Lab`을 입력합니다.

27. [[Search resources]]를 클릭합니다.

28. 검색 결과에 리소스가 표시되지 않으면 정리가 완료된 것입니다.

✅ **리소스 정리 완료**: 모든 리소스가 삭제되었습니다.


## 💡 핵심 포인트 정리

🛡️
보안 및 네트워크 제어
VPC 보안 그룹으로 네트워크 수준에서 데이터베이스 접근을 제어하고, Private 서브넷에 배치하여 외부 접근을 차단합니다.

💾
자동 백업 및 스냅샷
자동 백업(7일 보존)과 수동 스냅샷을 통해 데이터 보호와 특정 시점 복구를 제공합니다.
