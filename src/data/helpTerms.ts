// 용어 사전 데이터
export interface Term {
    term: string
    definition: string
    category: string
    awsCategory?: string // AWS 서비스 카테고리명
    weeks?: string[] // 실습/데모에서 다루는 주차
}

// 실습/데모 가이드 관련 용어 데이터
export const labTerms: Term[] = [
    // AWS 서비스 (알파벳 순)
    {
        term: 'Amazon CloudFront',
        definition: '전 세계 엣지 로케이션을 통해 콘텐츠를 빠르게 전송하는 CDN(Content Delivery Network) 서비스입니다. 웹사이트, API, 동영상 스트리밍 등의 성능을 향상시킵니다.\n\n주요 개념:\n• Distribution - CloudFront 배포 단위\n• Origin - 원본 콘텐츠 위치 (S3, EC2, ALB 등)\n• Edge Location - 전 세계 400개 이상 캐시 서버\n• Cache Behavior - 캐싱 규칙 및 경로 패턴\n• TTL (Time To Live) - 캐시 유효 시간\n• Invalidation - 캐시 강제 삭제\n• OAC (Origin Access Control) - S3 비공개 접근\n• Custom Domain - Route 53 도메인 연결\n• SSL/TLS Certificate - HTTPS 암호화 (ACM)\n• Geo Restriction - 지역 기반 접근 제어\n• Lambda@Edge - 엣지에서 코드 실행\n• Real-time Logs - 실시간 로그 스트리밍',
        category: 'AWS 서비스',
        awsCategory: 'Networking',
        weeks: ['11']
    },
    {
        term: 'Amazon CloudWatch',
        definition: 'AWS 리소스와 애플리케이션을 실시간으로 모니터링하는 서비스입니다. 로그 수집, 메트릭 추적, 알람 설정 등을 통해 시스템 상태를 관리할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['7']
    },
    {
        term: 'Amazon DynamoDB',
        definition: '완전 관리형 NoSQL 데이터베이스로, 밀리초 단위의 빠른 응답 속도와 무제한 확장성을 제공합니다. 키-값 및 문서 데이터 모델을 지원합니다.\n\n주요 개념:\n• Partition Key - 데이터 분산 저장을 위한 기본 키\n• Sort Key - 파티션 내 데이터 정렬 키\n• GSI (Global Secondary Index) - 다른 쿼리 패턴 지원\n• LSI (Local Secondary Index) - 동일 파티션 키로 다른 정렬\n• On-Demand Mode - 자동 확장/축소 용량 모드\n• Provisioned Mode - 읽기/쓰기 용량 사전 지정\n• Streams - 데이터 변경 이벤트 캡처\n• TTL (Time To Live) - 항목 자동 만료 및 삭제\n• Transactions - ACID 트랜잭션 지원\n• PartiQL - SQL 유사 쿼리 언어\n• Point-in-Time Recovery - 특정 시점 복구\n• Global Tables - 다중 리전 복제',
        category: 'AWS 서비스',
        awsCategory: 'Database',
        weeks: ['6', '9']
    },
    {
        term: 'Amazon EC2',
        definition: '크기 조정 가능한 가상 서버(인스턴스)를 제공하는 컴퓨팅 서비스입니다. 다양한 인스턴스 타입과 운영체제를 선택하여 애플리케이션을 실행할 수 있습니다.\n\n주요 개념:\n• Instance Types - 컴퓨팅 성능 조합 (t2.micro, m5.large 등)\n• AMI (Amazon Machine Image) - 인스턴스 템플릿\n• EBS (Elastic Block Store) - 영구 블록 스토리지\n• Instance Store - 임시 블록 스토리지\n• Security Group - 인스턴스 방화벽 규칙\n• Key Pair - SSH 접속용 공개/개인 키\n• User Data - 인스턴스 시작 시 실행 스크립트\n• Elastic IP - 고정 공인 IP 주소\n• Placement Group - 인스턴스 배치 전략\n• Auto Scaling - 자동 확장/축소\n• Load Balancer - 트래픽 분산 (ALB, NLB)\n• Spot Instance - 저렴한 예비 용량',
        category: 'AWS 서비스',
        awsCategory: 'Compute',
        weeks: ['4']
    },
    {
        term: 'Amazon ECR',
        definition: 'Docker 컨테이너 이미지를 안전하게 저장, 관리, 배포하는 완전 관리형 컨테이너 레지스트리 서비스입니다. ECS, EKS와 통합되어 사용됩니다.',
        category: 'AWS 서비스',
        awsCategory: 'Containers',
        weeks: ['10']
    },
    {
        term: 'Amazon ECS',
        definition: 'Docker 컨테이너를 쉽게 실행, 중지, 관리할 수 있는 완전 관리형 컨테이너 오케스트레이션 서비스입니다. Fargate 또는 EC2에서 실행할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Containers',
        weeks: ['10']
    },
    {
        term: 'Amazon RDS',
        definition: '관계형 데이터베이스를 쉽게 설정, 운영, 확장할 수 있는 관리형 서비스입니다. MySQL, PostgreSQL, Oracle, SQL Server 등을 지원하며, 자동 백업과 패치를 제공합니다.\n\n주요 개념:\n• Multi-AZ - 여러 가용 영역에 동기식 복제 (고가용성)\n• Read Replica - 읽기 전용 복제본 (성능 향상)\n• Automated Backup - 자동 백업 및 특정 시점 복구\n• Snapshot - 수동 백업 및 복원\n• Parameter Group - 데이터베이스 설정 관리\n• Option Group - 추가 기능 활성화\n• DB Subnet Group - VPC 내 서브넷 지정\n• Security Group - 네트워크 접근 제어\n• Enhanced Monitoring - 상세 모니터링 메트릭\n• Performance Insights - 쿼리 성능 분석\n• Encryption - 저장 데이터 암호화 (KMS)\n• IAM Database Authentication - IAM 기반 인증',
        category: 'AWS 서비스',
        awsCategory: 'Database',
        weeks: ['6']
    },
    {
        term: 'Amazon Route 53',
        definition: '확장 가능한 DNS 웹 서비스로, 도메인 등록, DNS 라우팅, 헬스 체크 기능을 제공합니다. 지연 시간 기반, 지리적 위치 기반 등 다양한 라우팅 정책을 지원합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Networking',
        weeks: ['11']
    },
    {
        term: 'Amazon S3',
        definition: '무제한 용량의 객체 스토리지 서비스로, 파일을 버킷에 저장하고 관리합니다. 높은 내구성(99.999999999%)과 가용성을 제공하며, 정적 웹사이트 호스팅도 가능합니다.\n\n주요 개념:\n• Bucket - 객체를 저장하는 최상위 컨테이너\n• Object - 파일과 메타데이터의 조합 (최대 5TB)\n• Versioning - 객체의 여러 버전 유지 및 복구\n• Lifecycle Policy - 객체 자동 전환 및 삭제 규칙\n• Storage Class - Standard, IA, Glacier 등 비용 최적화 옵션\n• Bucket Policy - 버킷 수준의 액세스 제어\n• ACL (Access Control List) - 객체 수준의 권한 관리\n• CORS - 다른 도메인에서의 접근 허용 설정\n• Static Website Hosting - HTML/CSS/JS 정적 사이트 호스팅\n• Presigned URL - 임시 접근 권한 URL 생성\n• Multipart Upload - 대용량 파일 분할 업로드\n• S3 Select - SQL로 객체 내용 직접 쿼리',
        category: 'AWS 서비스',
        awsCategory: 'Storage',
        weeks: ['5', '11']
    },
    {
        term: 'Amazon VPC',
        definition: 'AWS 클라우드 내에서 논리적으로 격리된 가상 네트워크를 생성하는 서비스입니다. IP 주소 범위, 서브넷, 라우팅 테이블, 게이트웨이 등을 완전히 제어할 수 있습니다.\n\n주요 개념:\n• Subnet - VPC 내 IP 주소 범위 분할 (퍼블릭/프라이빗)\n• Route Table - 네트워크 트래픽 경로 규칙\n• Internet Gateway (IGW) - VPC와 인터넷 연결\n• NAT Gateway - 프라이빗 서브넷의 아웃바운드 인터넷 접근\n• Security Group - 인스턴스 수준 방화벽 (상태 저장)\n• NACL - 서브넷 수준 방화벽 (상태 비저장)\n• VPC Endpoint - AWS 서비스에 프라이빗 연결\n• VPC Peering - VPC 간 프라이빗 연결\n• Elastic IP - 고정 공인 IP 주소\n• Flow Logs - 네트워크 트래픽 로그 캡처\n• CIDR Block - VPC/서브넷 IP 주소 범위',
        category: 'AWS 서비스',
        awsCategory: 'Networking',
        weeks: ['3']
    },
    {
        term: 'API Gateway',
        definition: 'RESTful API와 WebSocket API를 생성, 게시, 유지 관리하는 완전 관리형 서비스입니다. Lambda, EC2, 다른 AWS 서비스와 통합하여 서버리스 백엔드를 구축할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Networking',
        weeks: ['9']
    },
    {
        term: 'AWS Auto Scaling',
        definition: '애플리케이션 수요에 따라 리소스를 자동으로 확장하거나 축소하는 서비스입니다. EC2 인스턴스, ECS 태스크, DynamoDB 테이블 등의 용량을 자동 조정합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Compute',
        weeks: ['4']
    },
    {
        term: 'AWS Backup',
        definition: 'AWS 서비스 전반의 데이터 백업을 중앙에서 관리하고 자동화하는 완전 관리형 서비스입니다. 백업 계획, 백업 볼트, 복구 시점 등을 통해 체계적인 백업 전략을 구성합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Storage',
        weeks: ['12']
    },
    {
        term: 'AWS Budgets',
        definition: 'AWS 비용과 사용량에 대한 예산을 설정하고 추적하는 서비스입니다. 예산 초과 시 알림을 받을 수 있으며, SNS와 연동하여 자동 알림 시스템을 구축할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['13']
    },
    {
        term: 'AWS CloudShell',
        definition: '브라우저 기반의 사전 인증된 셸 환경으로, AWS CLI가 미리 설치되어 있어 별도 설정 없이 AWS 리소스를 관리할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['1']
    },
    {
        term: 'AWS CloudTrail',
        definition: 'AWS 계정의 API 호출과 사용자 활동을 기록하고 모니터링하는 서비스입니다. 보안 분석, 규정 준수 감사, 운영 문제 해결에 활용됩니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['7']
    },
    {
        term: 'AWS Cost Explorer',
        definition: 'AWS 비용과 사용량을 시각화하고 분석하는 도구입니다. 비용 추세 파악, 이상 비용 감지, 비용 최적화 권장 사항을 제공합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['13']
    },
    {
        term: 'AWS Fargate',
        definition: '서버를 관리하지 않고 컨테이너를 실행할 수 있는 서버리스 컴퓨팅 엔진입니다. ECS와 함께 사용하여 인프라 관리 없이 컨테이너를 배포합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Containers',
        weeks: ['10']
    },
    {
        term: 'AWS IAM',
        definition: 'AWS 리소스에 대한 액세스를 안전하게 제어하는 서비스입니다. 사용자, 그룹, 역할, 정책을 통해 세밀한 권한 관리가 가능합니다.\n\n주요 개념:\n• User - AWS에 접근하는 개별 사용자\n• Group - 사용자 모음 (공통 권한 부여)\n• Role - 임시 자격 증명을 통한 권한 위임\n• Policy - JSON 형식의 권한 정의 문서\n• MFA - 다중 인증 (Multi-Factor Authentication)\n• Access Key - 프로그래밍 방식 접근용 키\n• Permission Boundary - 최대 권한 범위 제한\n• SCP (Service Control Policy) - 조직 수준 권한 제어\n• Trust Policy - 역할 수임 허용 대상 정의\n• Instance Profile - EC2에 역할 연결',
        category: 'AWS 서비스',
        awsCategory: 'Security',
        weeks: ['1', '2', '14']
    },
    {
        term: 'AWS Lambda',
        definition: '서버를 프로비저닝하거나 관리하지 않고 코드를 실행할 수 있는 서버리스 컴퓨팅 서비스입니다. 이벤트에 응답하여 자동으로 실행되며, 사용한 컴퓨팅 시간만큼만 비용을 지불합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Compute',
        weeks: ['9']
    },
    {
        term: 'AWS Management Console',
        definition: 'AWS 서비스를 관리하기 위한 웹 기반 인터페이스입니다. 브라우저를 통해 AWS 리소스를 생성, 구성, 모니터링할 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['1']
    },
    {
        term: 'AWS Organizations',
        definition: '여러 AWS 계정을 중앙에서 관리하고 통합하는 서비스입니다. OU(조직 단위)와 SCP(서비스 제어 정책)를 통해 계정 거버넌스를 구현합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['14']
    },
    {
        term: 'AWS SNS',
        definition: '완전 관리형 메시징 서비스로, 게시/구독(Pub/Sub) 패턴을 통해 메시지를 전달합니다. 이메일, SMS, HTTP, Lambda 등 다양한 엔드포인트로 알림을 보낼 수 있습니다.',
        category: 'AWS 서비스',
        awsCategory: 'Application Integration',
        weeks: ['13']
    },
    {
        term: 'AWS Well-Architected Tool',
        definition: 'AWS Well-Architected Framework의 모범 사례를 기반으로 워크로드를 검토하고 개선 사항을 식별하는 도구입니다. 6가지 핵심 원칙에 따라 아키텍처를 평가합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Management',
        weeks: ['1']
    },
    {
        term: 'Elastic Load Balancing (ALB)',
        definition: '수신 트래픽을 여러 대상(EC2, 컨테이너 등)에 자동으로 분산하는 로드 밸런서입니다. ALB(Application Load Balancer)는 HTTP/HTTPS 트래픽을 처리하며, 경로 기반 라우팅을 지원합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Networking',
        weeks: ['4', '10']
    },

    // 네트워킹 용어
    {
        term: 'VPC Endpoint',
        definition: 'VPC 내에서 AWS 서비스에 프라이빗하게 연결하는 기능입니다. 인터넷 게이트웨이 없이 S3, DynamoDB 등의 서비스에 접근할 수 있습니다.\n\n유형:\n• Gateway Endpoint - S3, DynamoDB 전용 (무료)\n• Interface Endpoint - 대부분의 AWS 서비스 지원 (PrivateLink)',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'VPC Peering',
        definition: '두 VPC 간에 프라이빗 네트워크 연결을 설정하는 기능입니다. 같은 리전 또는 다른 리전의 VPC를 연결할 수 있으며, 전이적 피어링은 지원하지 않습니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'Subnet',
        definition: 'VPC 내에서 IP 주소 범위를 분할한 네트워크 영역입니다. 퍼블릭 서브넷은 인터넷과 직접 통신하고, 프라이빗 서브넷은 NAT Gateway를 통해 간접 통신합니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'Internet Gateway (IGW)',
        definition: 'VPC와 인터넷 간의 통신을 가능하게 하는 게이트웨이입니다. 퍼블릭 서브넷의 리소스가 인터넷에 접근하려면 IGW가 필요합니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'NAT Gateway',
        definition: '프라이빗 서브넷의 리소스가 인터넷에 아웃바운드 연결을 할 수 있게 해주는 서비스입니다. 인바운드 연결은 차단하여 보안을 유지합니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'Security Group',
        definition: '인스턴스 수준의 가상 방화벽으로, 인바운드와 아웃바운드 트래픽을 제어합니다. 상태 저장(Stateful) 방식으로 동작하며, 허용 규칙만 설정할 수 있습니다.',
        category: '네트워킹',
        weeks: ['3', '4']
    },
    {
        term: 'NACL (Network ACL)',
        definition: '서브넷 수준의 방화벽으로, 인바운드와 아웃바운드 트래픽을 제어합니다. 상태 비저장(Stateless) 방식으로 동작하며, 허용과 거부 규칙을 모두 설정할 수 있습니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'Route Table',
        definition: '서브넷의 네트워크 트래픽이 전달되는 경로를 정의하는 규칙 집합입니다. 각 서브넷은 하나의 라우팅 테이블에 연결됩니다.',
        category: '네트워킹',
        weeks: ['3']
    },
    {
        term: 'Elastic IP',
        definition: 'AWS 계정에 할당되는 고정 공인 IPv4 주소입니다. 인스턴스를 중지/시작해도 IP가 변경되지 않으며, 다른 인스턴스로 재연결할 수 있습니다.',
        category: '네트워킹',
        weeks: ['3', '4']
    },
    {
        term: 'CIDR',
        definition: 'Classless Inter-Domain Routing의 약자로, IP 주소 범위를 표현하는 방법입니다. 예: 10.0.0.0/16은 10.0.0.0~10.0.255.255 범위를 의미합니다.',
        category: '네트워킹',
        weeks: ['3']
    },

    // 보안 용어
    {
        term: 'IAM Role',
        definition: 'AWS 서비스나 사용자가 임시로 권한을 부여받을 수 있는 자격 증명입니다. 직접 자격 증명(비밀번호, 액세스 키)이 아닌 임시 보안 자격 증명을 사용합니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'IAM Policy',
        definition: 'AWS 리소스에 대한 권한을 정의하는 JSON 문서입니다. Effect, Action, Resource, Condition 등의 요소로 구성되며, 자격 증명 기반과 리소스 기반 정책이 있습니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'IAM User',
        definition: 'AWS 서비스와 리소스에 접근할 수 있는 개별 사용자 계정입니다. 콘솔 비밀번호와 액세스 키를 통해 인증하며, 정책을 통해 권한을 부여받습니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'MFA (Multi-Factor Authentication)',
        definition: '사용자 이름과 비밀번호 외에 추가 인증 요소를 요구하는 보안 메커니즘입니다. 가상 MFA 디바이스, 하드웨어 토큰, FIDO 보안 키 등을 사용합니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'AssumeRole',
        definition: 'IAM 역할의 임시 자격 증명을 획득하는 AWS STS API 호출입니다. 교차 계정 접근, 서비스 간 권한 위임 등에 사용됩니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'Trust Policy',
        definition: 'IAM 역할을 수임(AssumeRole)할 수 있는 대상을 정의하는 정책입니다. 어떤 AWS 서비스, 계정, 사용자가 해당 역할을 사용할 수 있는지 지정합니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'Instance Profile',
        definition: 'EC2 인스턴스에 IAM 역할을 연결하기 위한 컨테이너입니다. 인스턴스 프로파일을 통해 EC2에서 실행되는 애플리케이션이 AWS 서비스에 안전하게 접근할 수 있습니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'Permission Boundary',
        definition: 'IAM 엔터티(사용자, 역할)가 가질 수 있는 최대 권한 범위를 제한하는 고급 기능입니다. 권한 경계 내에서만 실제 권한이 부여됩니다.',
        category: '보안',
        weeks: ['2']
    },
    {
        term: 'STS (Security Token Service)',
        definition: 'AWS 리소스에 대한 임시 보안 자격 증명을 생성하는 서비스입니다. AssumeRole, GetSessionToken 등의 API를 통해 임시 자격 증명을 발급합니다.',
        category: '보안',
        weeks: ['1', '2']
    },
    {
        term: 'OAC (Origin Access Control)',
        definition: 'CloudFront에서 S3 오리진에 대한 접근을 제어하는 기능입니다. S3 버킷을 비공개로 유지하면서 CloudFront를 통해서만 콘텐츠에 접근할 수 있도록 합니다.',
        category: '보안',
        weeks: ['11']
    },
    {
        term: 'SSO (Single Sign-On)',
        definition: '한 번의 로그인으로 여러 AWS 계정과 애플리케이션에 접근할 수 있는 인증 방식입니다. AWS IAM Identity Center를 통해 중앙 집중식 SSO를 구성합니다.',
        category: '보안',
        weeks: ['14']
    },

    // 데이터베이스 용어
    {
        term: 'Multi-AZ',
        definition: 'RDS에서 여러 가용 영역에 데이터베이스를 동기식으로 복제하여 고가용성을 제공하는 배포 옵션입니다. 장애 발생 시 자동으로 대기 인스턴스로 전환됩니다.',
        category: '데이터베이스',
        weeks: ['6']
    },
    {
        term: 'Read Replica',
        definition: 'RDS 데이터베이스의 읽기 전용 복제본입니다. 읽기 트래픽을 분산하여 성능을 향상시키며, 비동기식으로 복제됩니다.',
        category: '데이터베이스',
        weeks: ['6']
    },
    {
        term: 'Partition Key',
        definition: 'DynamoDB 테이블에서 데이터를 분산 저장하기 위한 기본 키입니다. 해시 함수를 통해 데이터가 저장될 파티션을 결정합니다.',
        category: '데이터베이스',
        weeks: ['6']
    },
    {
        term: 'Sort Key',
        definition: 'DynamoDB에서 파티션 키와 함께 복합 기본 키를 구성하는 키입니다. 같은 파티션 내에서 데이터를 정렬하고 범위 쿼리를 가능하게 합니다.',
        category: '데이터베이스',
        weeks: ['6']
    },
    {
        term: 'DB Subnet Group',
        definition: 'RDS 인스턴스가 배치될 수 있는 VPC 서브넷의 모음입니다. 최소 2개 이상의 가용 영역에 걸친 서브넷을 포함해야 합니다.',
        category: '데이터베이스',
        weeks: ['6']
    },

    // 컨테이너 용어
    {
        term: 'Docker',
        definition: '애플리케이션을 컨테이너로 패키징하고 실행하는 오픈소스 플랫폼입니다. 이미지를 빌드하고 컨테이너를 실행하여 일관된 환경을 제공합니다.',
        category: '컨테이너',
        weeks: ['10']
    },
    {
        term: 'Container Image',
        definition: '컨테이너를 실행하기 위한 읽기 전용 템플릿입니다. Dockerfile을 통해 빌드되며, 애플리케이션 코드, 런타임, 라이브러리 등을 포함합니다.',
        category: '컨테이너',
        weeks: ['10']
    },
    {
        term: 'Task Definition',
        definition: 'ECS에서 컨테이너를 실행하기 위한 설정 문서입니다. 컨테이너 이미지, CPU/메모리, 포트 매핑, 환경 변수 등을 정의합니다.',
        category: '컨테이너',
        weeks: ['10']
    },
    {
        term: 'Container Registry',
        definition: '컨테이너 이미지를 저장하고 배포하는 저장소입니다. AWS에서는 Amazon ECR이 완전 관리형 컨테이너 레지스트리 서비스를 제공합니다.',
        category: '컨테이너',
        weeks: ['10']
    },
    {
        term: 'Dockerfile',
        definition: '컨테이너 이미지를 빌드하기 위한 명령어가 포함된 텍스트 파일입니다. FROM, RUN, COPY, CMD 등의 명령어로 이미지 레이어를 정의합니다.',
        category: '컨테이너',
        weeks: ['10']
    },
    {
        term: 'Multi-stage Build',
        definition: 'Dockerfile에서 여러 빌드 단계를 사용하여 최종 이미지 크기를 최소화하는 기법입니다. 빌드 도구는 중간 단계에만 포함하고 최종 이미지에는 실행 파일만 포함합니다.',
        category: '컨테이너',
        weeks: ['10']
    },

    // 서버리스 용어
    {
        term: 'Serverless',
        definition: '서버 인프라를 관리하지 않고 애플리케이션을 구축하고 실행하는 클라우드 컴퓨팅 모델입니다. AWS Lambda, API Gateway, DynamoDB 등이 대표적인 서버리스 서비스입니다.',
        category: '서버리스',
        weeks: ['9']
    },
    {
        term: 'Event-driven',
        definition: '이벤트(HTTP 요청, 파일 업로드, DB 변경 등)에 의해 함수가 자동으로 실행되는 아키텍처 패턴입니다. 서버리스 아키텍처의 핵심 개념입니다.',
        category: '서버리스',
        weeks: ['9']
    },
    {
        term: 'Cold Start',
        definition: 'Lambda 함수가 처음 호출되거나 오랜 시간 후 호출될 때 실행 환경을 초기화하는 데 걸리는 지연 시간입니다. 프로비저닝된 동시성으로 완화할 수 있습니다.',
        category: '서버리스',
        weeks: ['9']
    },
    {
        term: 'Stage',
        definition: 'API Gateway에서 API의 배포 단계를 나타냅니다. dev, staging, prod 등의 스테이지를 만들어 API의 여러 버전을 관리할 수 있습니다.',
        category: '서버리스',
        weeks: ['9']
    },

    // 컴퓨팅 용어
    {
        term: 'AMI (Amazon Machine Image)',
        definition: 'EC2 인스턴스를 시작하는 데 필요한 정보를 포함하는 템플릿입니다. 운영체제, 애플리케이션, 설정 등이 포함되며, 커스텀 AMI를 생성하여 재사용할 수 있습니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },
    {
        term: 'User Data',
        definition: 'EC2 인스턴스가 시작될 때 자동으로 실행되는 스크립트입니다. 소프트웨어 설치, 설정 변경, 서비스 시작 등의 초기화 작업을 자동화합니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },
    {
        term: 'Launch Template',
        definition: 'EC2 인스턴스를 시작하기 위한 구성 정보를 저장하는 템플릿입니다. AMI, 인스턴스 타입, 키 페어, 보안 그룹 등을 미리 정의하여 Auto Scaling에서 사용합니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },
    {
        term: 'Target Group',
        definition: '로드 밸런서가 트래픽을 라우팅할 대상의 그룹입니다. EC2 인스턴스, IP 주소, Lambda 함수 등을 대상으로 등록하고 헬스 체크를 수행합니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },
    {
        term: 'Scaling Policy',
        definition: 'Auto Scaling 그룹의 인스턴스 수를 조정하는 규칙입니다. 대상 추적, 단계별, 단순 조정 등의 정책 유형이 있으며, CloudWatch 지표를 기반으로 동작합니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },
    {
        term: 'Health Check',
        definition: '로드 밸런서나 Auto Scaling이 대상의 상태를 확인하는 메커니즘입니다. 정상(Healthy) 또는 비정상(Unhealthy) 상태를 판단하여 트래픽 라우팅을 결정합니다.',
        category: '컴퓨팅',
        weeks: ['4']
    },

    // 스토리지 용어
    {
        term: 'Bucket Policy',
        definition: 'S3 버킷에 대한 액세스 권한을 정의하는 리소스 기반 정책입니다. JSON 형식으로 작성하며, 특정 사용자나 서비스의 버킷 접근을 허용하거나 거부합니다.',
        category: '스토리지',
        weeks: ['5']
    },
    {
        term: 'Static Website Hosting',
        definition: 'S3 버킷을 웹 서버로 사용하여 HTML, CSS, JavaScript 등의 정적 파일을 호스팅하는 기능입니다. 인덱스 문서와 오류 문서를 설정할 수 있습니다.',
        category: '스토리지',
        weeks: ['5']
    },

    // 모니터링 용어
    {
        term: 'Logs Insights',
        definition: 'CloudWatch Logs에 저장된 로그 데이터를 대화형으로 검색하고 분석하는 기능입니다. 전용 쿼리 언어를 사용하여 로그 패턴을 분석하고 시각화합니다.',
        category: '모니터링',
        weeks: ['7']
    },
    {
        term: 'Metric Filter',
        definition: 'CloudWatch Logs에서 특정 패턴을 검색하여 커스텀 메트릭을 생성하는 기능입니다. 로그에서 오류 횟수, 지연 시간 등을 추출하여 알람을 설정할 수 있습니다.',
        category: '모니터링',
        weeks: ['7']
    },

    // 백업 및 복구 용어
    {
        term: 'Backup Plan',
        definition: 'AWS Backup에서 백업 일정, 보존 기간, 대상 리소스를 정의하는 정책입니다. 자동화된 백업 스케줄을 구성하여 체계적인 데이터 보호를 구현합니다.',
        category: '백업 및 복구',
        weeks: ['12']
    },
    {
        term: 'Backup Vault',
        definition: 'AWS Backup에서 복구 시점(백업 데이터)을 저장하는 논리적 컨테이너입니다. 암호화 키와 액세스 정책을 통해 백업 데이터를 보호합니다.',
        category: '백업 및 복구',
        weeks: ['12']
    },
    {
        term: 'Recovery Point',
        definition: 'AWS Backup에서 생성된 백업 데이터의 특정 시점 스냅샷입니다. 복구 시점을 사용하여 리소스를 이전 상태로 복원할 수 있습니다.',
        category: '백업 및 복구',
        weeks: ['12']
    },
    {
        term: 'RPO (Recovery Point Objective)',
        definition: '재해 발생 시 허용 가능한 최대 데이터 손실 시간입니다. RPO가 1시간이면 최대 1시간 분량의 데이터 손실을 허용한다는 의미입니다.',
        category: '백업 및 복구',
        weeks: ['12']
    },
    {
        term: 'RTO (Recovery Time Objective)',
        definition: '재해 발생 후 서비스를 복구하는 데 허용되는 최대 시간입니다. RTO가 4시간이면 4시간 이내에 서비스가 정상화되어야 한다는 의미입니다.',
        category: '백업 및 복구',
        weeks: ['12']
    },

    // 일반 용어
    {
        term: 'Region',
        definition: 'AWS 인프라가 위치한 지리적 영역입니다. 각 리전은 독립적으로 운영되며, 여러 가용 영역(AZ)으로 구성됩니다. 예: ap-northeast-2 (서울)',
        category: '일반',
        weeks: ['1', '3']
    },
    {
        term: 'Availability Zone (AZ)',
        definition: '리전 내의 독립된 데이터 센터 그룹입니다. 각 AZ는 독립적인 전원, 냉각, 네트워크를 갖추고 있어 장애 격리가 가능합니다.',
        category: '일반',
        weeks: ['1', '3', '6']
    },
    {
        term: 'ARN (Amazon Resource Name)',
        definition: 'AWS 리소스를 고유하게 식별하는 표준 형식입니다. arn:aws:service:region:account-id:resource 형태로 구성됩니다.',
        category: '일반',
        weeks: ['1', '2']
    },
    {
        term: 'Tag',
        definition: 'AWS 리소스에 부여하는 키-값 쌍의 메타데이터입니다. 리소스 분류, 비용 추적, 접근 제어 등에 활용됩니다.',
        category: '일반',
        weeks: ['1', '4', '13']
    },
    {
        term: 'AWS CLI',
        definition: 'AWS 서비스를 명령줄에서 관리하는 도구입니다. 스크립트를 통한 자동화가 가능하며, 콘솔과 동일한 작업을 수행할 수 있습니다.',
        category: '일반',
        weeks: ['1']
    },
    {
        term: 'Console',
        definition: 'AWS 서비스를 관리하기 위한 웹 기반 그래픽 인터페이스입니다. 브라우저를 통해 리소스를 생성, 구성, 모니터링할 수 있습니다.',
        category: '일반',
        weeks: ['1']
    },
    {
        term: 'High Availability (고가용성)',
        definition: '시스템이 장애 없이 지속적으로 운영되는 능력입니다. Multi-AZ 배포, 로드 밸런서, Auto Scaling 등을 통해 달성합니다.',
        category: '일반',
        weeks: ['4', '6', '12']
    },
    {
        term: 'Fault Tolerance (내결함성)',
        definition: '시스템 구성 요소에 장애가 발생해도 전체 시스템이 정상 동작하는 능력입니다. 이중화, 자동 복구, 데이터 복제 등의 기법을 사용합니다.',
        category: '일반',
        weeks: ['4', '12']
    },
    {
        term: 'Scalability (확장성)',
        definition: '워크로드 증가에 따라 시스템 용량을 늘릴 수 있는 능력입니다. 수직 확장(Scale Up)과 수평 확장(Scale Out)이 있습니다.',
        category: '일반',
        weeks: ['4', '9']
    },
    {
        term: 'Latency (지연 시간)',
        definition: '요청을 보낸 후 응답을 받기까지 걸리는 시간입니다. CloudFront, Route 53 등을 통해 지연 시간을 최소화할 수 있습니다.',
        category: '일반',
        weeks: ['9', '11']
    },
    {
        term: 'Throughput (처리량)',
        definition: '단위 시간당 처리할 수 있는 데이터 또는 요청의 양입니다. EBS, DynamoDB 등에서 IOPS나 RCU/WCU로 측정합니다.',
        category: '일반',
        weeks: ['5', '6']
    },
    {
        term: 'Encryption (암호화)',
        definition: '데이터를 읽을 수 없는 형태로 변환하여 보호하는 기술입니다. 전송 중 암호화(TLS/SSL)와 저장 시 암호화(SSE, KMS)가 있습니다.',
        category: '일반',
        weeks: ['5', '6']
    },
    {
        term: 'Well-Architected Framework',
        definition: 'AWS가 제시하는 클라우드 아키텍처 설계 모범 사례 프레임워크입니다. 운영 우수성, 보안, 안정성, 성능 효율성, 비용 최적화, 지속 가능성의 6가지 핵심 원칙으로 구성됩니다.',
        category: '일반',
        weeks: ['1']
    },
    {
        term: 'Snapshot',
        definition: 'EBS 볼륨이나 RDS 인스턴스의 특정 시점 백업입니다. S3에 증분 방식으로 저장되며, 새 볼륨이나 인스턴스를 생성하는 데 사용할 수 있습니다.',
        category: '일반',
        weeks: ['6', '12']
    },
    {
        term: 'Monitoring (모니터링)',
        definition: '시스템의 상태, 성능, 가용성을 지속적으로 관찰하고 측정하는 활동입니다. CloudWatch를 통해 메트릭 수집, 로그 분석, 알람 설정 등을 수행합니다.',
        category: '일반',
        weeks: ['7']
    },
    {
        term: 'Logging (로깅)',
        definition: '시스템 이벤트, 오류, 사용자 활동 등을 기록하는 활동입니다. CloudWatch Logs, CloudTrail 등을 통해 로그를 수집하고 분석합니다.',
        category: '일반',
        weeks: ['7']
    },

    // 추가 AWS 서비스
    {
        term: 'Amazon EBS',
        definition: 'EC2 인스턴스에 연결하여 사용하는 블록 스토리지 서비스입니다. 인스턴스를 중지해도 데이터가 유지되며, 스냅샷을 통한 백업과 복구가 가능합니다.\n\n주요 개념:\n• Volume Types - gp3, gp2, io2, st1, sc1 등 용도별 볼륨 유형\n• IOPS - 초당 입출력 작업 수 (성능 지표)\n• Snapshot - 볼륨의 특정 시점 백업 (S3에 저장)\n• Encryption - 볼륨 및 스냅샷 암호화',
        category: 'AWS 서비스',
        awsCategory: 'Storage',
        weeks: ['4', '5']
    },
    {
        term: 'Amazon EFS',
        definition: '여러 EC2 인스턴스에서 동시에 접근할 수 있는 완전 관리형 파일 스토리지 서비스입니다. NFS 프로토콜을 사용하며, 자동으로 용량이 확장/축소됩니다.\n\n주요 개념:\n• Performance Mode - General Purpose, Max I/O\n• Throughput Mode - Bursting, Provisioned, Elastic\n• Storage Class - Standard, Infrequent Access\n• Lifecycle Management - 자동 스토리지 클래스 전환',
        category: 'AWS 서비스',
        awsCategory: 'Storage',
        weeks: ['5']
    },
    {
        term: 'AWS IAM Identity Center',
        definition: '여러 AWS 계정과 비즈니스 애플리케이션에 대한 SSO(Single Sign-On) 접근을 중앙에서 관리하는 서비스입니다. 사용자와 그룹을 생성하고 권한 세트를 할당하여 통합 인증을 구현합니다.',
        category: 'AWS 서비스',
        awsCategory: 'Security',
        weeks: ['14']
    },

    // 추가 보안/조직 용어
    {
        term: 'SCP (Service Control Policy)',
        definition: 'AWS Organizations에서 조직 단위(OU)나 계정에 적용하는 정책으로, 해당 범위 내에서 사용할 수 있는 AWS 서비스와 작업의 최대 범위를 제한합니다.',
        category: '보안',
        weeks: ['14']
    },
    {
        term: 'OU (Organizational Unit)',
        definition: 'AWS Organizations에서 계정을 논리적으로 그룹화하는 단위입니다. OU에 SCP를 적용하여 하위 계정들의 권한을 일괄적으로 관리할 수 있습니다.',
        category: '보안',
        weeks: ['14']
    },

    // 추가 서버리스 용어
    {
        term: 'CORS (Cross-Origin Resource Sharing)',
        definition: '웹 브라우저에서 다른 도메인의 리소스에 접근할 수 있도록 허용하는 보안 메커니즘입니다. API Gateway에서 CORS를 활성화하면 프론트엔드 웹 애플리케이션이 API를 호출할 수 있습니다.',
        category: '서버리스',
        weeks: ['9']
    },
]
