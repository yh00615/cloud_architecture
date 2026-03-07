// 실습 계획서 기반 커리큘럼 데이터

export type SessionType = 'theory' | 'lab' | 'demo' | 'none';

export interface Session {
  session: number;
  type: SessionType;
  title: string;
  hasContent: boolean;
  markdownPath?: string;
  description?: string;
  awsServices?: string[];
  learningObjectives?: string[]; // 차시별 학습 목표
}

export interface WeekCurriculum {
  week: number;
  title: string;
  description: string;
  sessions: Session[];
  prerequisites?: string[];
  estimatedTime?: string;
  difficulty?: 'beginner' | 'intermediate' | 'advanced';
}

// 15주차 커리큘럼 데이터 (실제 실습 계획서 기반)
export const curriculum: WeekCurriculum[] = [
  {
    week: 1,
    title: '클라우드 아키텍처 개요 및 설계 원칙',
    description:
      '클라우드 컴퓨팅의 기본 개념과 AWS 핵심 서비스, Well-Architected Framework를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: '클라우드 컴퓨팅 기본 개념',
        hasContent: false,
        description:
          '클라우드 컴퓨팅 정의 및 특징, 클라우드 기반 기술 및 배포 모델, AWS 글로벌 인프라',
        awsServices: [],
        learningObjectives: [
          '클라우드 컴퓨팅의 정의와 5가지 핵심 특징을 설명할 수 있습니다.',
          '클라우드 서비스 모델(IaaS, PaaS, SaaS)과 배포 모델(퍼블릭, 프라이빗, 하이브리드)을 구분할 수 있습니다.',
          'AWS 글로벌 인프라의 구성 요소(리전, 가용 영역, 엣지 로케이션)를 설명할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'AWS 관리 인터페이스',
        hasContent: true,
        markdownPath: '/content/week1/1-2-aws-management-interface.md',
        description:
          'AWS 서비스 카테고리 및 핵심 서비스 소개, AWS 관리형 서비스의 이점과 활용 사례, AWS 관리 인터페이스: 콘솔과 CLI',
        awsServices: ['AWS CloudShell', 'AWS IAM'],
        learningObjectives: [
          'AWS Management Console의 기본 구성과 계정/리전 정보를 확인할 수 있습니다.',
          'AWS CloudShell 환경을 활용하여 파일 업로드 및 CLI 명령을 실행할 수 있습니다.',
          'AWS CLI의 기본 명령어를 사용하여 계정 정보를 조회하고 콘솔 결과와 비교할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'AWS Well-Architected Framework 및 설계 원칙',
        hasContent: false,
        description:
          '클라우드 아키텍처 설계, AWS Well-Architected Framework 개요, AWS Well-Architected Tool 활용',
        awsServices: ['AWS Well-Architected Tool'],
        learningObjectives: [
          '클라우드 아키텍처 설계의 기본 원칙을 이해할 수 있습니다.',
          'AWS Well-Architected Framework의 6가지 핵심 원칙을 설명할 수 있습니다.',
          'AWS Well-Architected Tool을 활용하여 아키텍처를 검토하는 방법을 이해할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['AWS 기본 개념 이해', '클라우드 컴퓨팅 기초 지식'],
    estimatedTime: '180분',
    difficulty: 'beginner',
  },
  {
    week: 2,
    title: 'AWS IAM 고급 정책 구성',
    description:
      'AWS IAM 사용자, 그룹, 정책 관리와 역할 기반 접근 제어, IAM Access Analyzer를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'lab',
        title: 'AWS IAM 사용자 및 정책 관리',
        hasContent: true,
        markdownPath: '/content/week2/2-1-iam-user-policy.md',
        description:
          'AWS IAM 사용자 및 그룹 관리, AWS IAM 정책 구조 및 요소, 자격 증명 기반 vs 리소스 기반 정책',
        awsServices: ['AWS IAM'],
        learningObjectives: [
          'AWS IAM 사용자와 그룹을 생성하고 관리할 수 있습니다.',
          'AWS IAM 정책의 기본 구조(Effect, Action, Resource)를 이해하고 작성할 수 있습니다.',
          '자격 증명 기반 정책과 리소스 기반 정책의 차이를 구분할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'AWS IAM 역할 구성',
        hasContent: true,
        markdownPath: '/content/week2/2-2-iam-role-config.md',
        description:
          'AWS IAM 역할 소개, AWS IAM 역할 활용, AWS IAM 권한 경계',
        awsServices: ['AWS IAM', 'AWS STS'],
        learningObjectives: [
          'AWS IAM 역할의 개념과 다양한 유형을 이해할 수 있습니다.',
          'AWS IAM 역할을 활용하여 서비스 간 안전한 접근을 구성할 수 있습니다.',
          'AWS IAM 권한 경계(Permission Boundary)의 개념과 활용 방법을 이해할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'AWS IAM Access Analyzer 및 보안 검증',
        hasContent: false,
        description:
          'AWS IAM Access Analyzer 개요, AWS IAM Access Analyzer 정책 관리, AWS IAM Access Analyzer 정책 검증',
        awsServices: ['AWS IAM'],
        learningObjectives: [
          'AWS IAM Access Analyzer의 개요와 주요 기능을 설명할 수 있습니다.',
          'AWS IAM Access Analyzer를 활용한 정책 관리 방법을 이해할 수 있습니다.',
          'AWS IAM Access Analyzer를 통한 정책 검증 프로세스를 설명할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1 완료', 'IAM 기본 개념 이해'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 3,
    title: 'Amazon VPC 및 서브넷 설계 실습',
    description:
      '클라우드 네트워크 기초, VPC 설계 및 서브넷 구성, 네트워크 보안 및 연결 옵션을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: '클라우드 네트워크 기초 및 Amazon VPC 이해',
        hasContent: false,
        description:
          'IP 주소와 CIDR 표기법, Amazon VPC 개요, 퍼블릭/프라이빗 서브넷 구성 및 활용',
        awsServices: ['Amazon VPC'],
        learningObjectives: [
          'IP 주소 체계와 CIDR 표기법의 원리를 이해하고 네트워크 설계에 활용할 수 있습니다.',
          'Amazon VPC의 개념과 핵심 구성 요소를 설명할 수 있습니다.',
          '퍼블릭 서브넷과 프라이빗 서브넷의 차이를 이해하고 활용할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon VPC 네트워크 설계',
        hasContent: true,
        markdownPath: '/content/week3/3-2-vpc-network-design.md',
        description:
          'Amazon VPC 및 서브넷 설계 및 생성, 라우팅 테이블 및 트래픽 흐름 구성, 외부 연결을 위한 게이트웨이 구성',
        awsServices: ['Amazon VPC'],
        learningObjectives: [
          'Amazon VPC와 서브넷을 설계하고 생성할 수 있습니다.',
          '라우팅 테이블을 통한 트래픽 흐름 제어 방법을 이해할 수 있습니다.',
          '인터넷 게이트웨이와 NAT 게이트웨이를 구성하여 외부 연결을 설정할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: '네트워크 보안 및 연결 옵션',
        hasContent: false,
        description:
          'VPC 네트워크 보안 제어 방식, VPC 엔드포인트를 통한 서비스 액세스, VPC 피어링을 통한 VPC 간 연결',
        awsServices: ['Amazon VPC'],
        learningObjectives: [
          'VPC 보안 그룹과 NACL의 차이점과 활용 방법을 이해할 수 있습니다.',
          'VPC 엔드포인트를 통한 프라이빗 서비스 액세스 방법을 설명할 수 있습니다.',
          'VPC 피어링을 통한 VPC 간 연결 방법을 이해할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-2 완료', '네트워킹 기본 개념 이해'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 4,
    title: 'Amazon EC2와 오토스케일링 구성 실습',
    description:
      'Amazon EC2 기본 개념, 스토리지 및 이미지 관리, Auto Scaling 및 로드 밸런서를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'lab',
        title: 'Amazon EC2 인스턴스 생성',
        hasContent: true,
        markdownPath: '/content/week4/4-1-ec2-instance-deploy.md',
        description:
          'Amazon EC2 서비스 개요 및 핵심 요소, Amazon EC2 인스턴스 유형, Amazon EC2 인스턴스 관리 및 활용',
        awsServices: ['Amazon EC2'],
        learningObjectives: [
          'Amazon EC2의 기본 개념과 아키텍처를 이해할 수 있습니다.',
          'EC2 인스턴스 패밀리의 종류와 특징을 구분할 수 있습니다.',
          'Amazon EC2 인스턴스를 생성하고 관리할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'theory',
        title: 'Amazon EC2 스토리지 및 이미지 관리',
        hasContent: false,
        description:
          'Amazon EC2 스토리지 옵션 개요, Amazon EBS 소개, AMI를 통한 배포',
        awsServices: ['Amazon EC2', 'Amazon EBS'],
        learningObjectives: [
          'Amazon EC2의 스토리지 옵션(인스턴스 스토어, EBS)을 비교할 수 있습니다.',
          'Amazon EBS 볼륨 유형과 특징을 이해할 수 있습니다.',
          'AMI(Amazon Machine Image)를 활용한 인스턴스 배포 방법을 설명할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'lab',
        title: 'Amazon EC2 Auto Scaling 환경 구축',
        hasContent: true,
        markdownPath: '/content/week4/4-3-ec2-autoscaling.md',
        description:
          'Amazon EC2 Auto Scaling 개요, Amazon EC2 Auto Scaling 구성 요소, 로드 밸런서 유형 및 특징',
        awsServices: ['Amazon EC2', 'Elastic Load Balancing'],
        learningObjectives: [
          'Amazon EC2 Auto Scaling의 개념과 주요 이점을 이해할 수 있습니다.',
          'Auto Scaling 그룹의 구성 요소(시작 템플릿, 조정 정책)를 설명할 수 있습니다.',
          '다양한 로드 밸런서 유형의 특징을 파악하고 적절한 사용 사례를 구분할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-3 완료', 'VPC 기본 개념 이해'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 5,
    title: '스토리지 전략 (Amazon S3, Amazon EBS, Amazon EFS)',
    description:
      'AWS 스토리지 서비스 개요, Amazon S3 기능 및 활용, Amazon EBS 및 Amazon EFS 활용을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: 'AWS 스토리지 서비스 개요',
        hasContent: false,
        description:
          '클라우드 스토리지 기본 개념, AWS 스토리지 서비스 유형, AWS 스토리지 서비스 선택',
        awsServices: ['Amazon S3', 'Amazon EBS', 'Amazon EFS'],
        learningObjectives: [
          '클라우드 스토리지의 기본 개념과 유형(블록, 파일, 객체)을 이해할 수 있습니다.',
          'AWS 스토리지 서비스의 종류와 각 서비스의 특징을 설명할 수 있습니다.',
          '워크로드 요구사항에 따라 적절한 AWS 스토리지 서비스를 선택할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon S3 웹사이트 호스팅',
        hasContent: true,
        markdownPath: '/content/week5/5-2-s3-website-hosting.md',
        description:
          'Amazon S3 기본 개념 및 특징, 버킷 관리 및 정적 웹사이트 호스팅, 데이터 관리 및 보안 기능',
        awsServices: ['Amazon S3'],
        learningObjectives: [
          'Amazon S3의 기본 개념과 핵심 기능을 이해할 수 있습니다.',
          'Amazon S3 버킷을 생성하고 정적 웹사이트를 호스팅할 수 있습니다.',
          'Amazon S3의 데이터 관리 및 보안 기능(버전 관리, 암호화, 접근 제어)을 활용할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'Amazon EBS 및 Amazon EFS 활용',
        hasContent: false,
        description:
          'Amazon EBS 소개, Amazon EFS 소개, Amazon EFS 핵심 기능 및 활용',
        awsServices: ['Amazon EBS', 'Amazon EFS'],
        learningObjectives: [
          'Amazon EBS의 볼륨 유형과 특징을 이해하고 적절한 유형을 선택할 수 있습니다.',
          'Amazon EFS의 개념과 Amazon EBS와의 차이를 설명할 수 있습니다.',
          'Amazon EFS의 핵심 기능(성능 모드, 처리량 모드, 수명 주기 관리)을 이해할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-4 완료'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 6,
    title: 'Amazon RDS 및 Amazon DynamoDB 구성',
    description:
      'AWS 데이터베이스 서비스 개요, Amazon RDS 서비스, Amazon DynamoDB 기초 및 활용을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: 'AWS 데이터베이스 서비스 개요',
        hasContent: false,
        description:
          '데이터베이스 기본 개념 및 유형, 관계형 vs 비관계형 데이터베이스 비교, AWS 데이터베이스 서비스 옵션',
        awsServices: ['Amazon RDS', 'Amazon DynamoDB'],
        learningObjectives: [
          '데이터베이스의 기본 개념과 유형(관계형, 비관계형)을 이해할 수 있습니다.',
          '관계형 데이터베이스와 비관계형 데이터베이스의 차이를 비교할 수 있습니다.',
          'AWS 데이터베이스 서비스 옵션을 이해하고 요구사항에 맞는 서비스를 선택할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon RDS 서비스 활용',
        hasContent: true,
        markdownPath: '/content/week6/6-2-rds-service.md',
        description:
          'Amazon RDS 개요, Amazon RDS 인스턴스 생성 및 구성, 고가용성 및 백업 전략',
        awsServices: ['Amazon RDS'],
        learningObjectives: [
          'Amazon RDS의 핵심 개념과 지원되는 엔진을 이해할 수 있습니다.',
          'Amazon RDS 인스턴스를 생성하고 구성할 수 있습니다.',
          'Amazon RDS의 고가용성(Multi-AZ) 및 백업 전략을 설명할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'lab',
        title: 'Amazon DynamoDB 서비스 활용',
        hasContent: true,
        markdownPath: '/content/week6/6-3-dynamodb-service.md',
        description:
          'Amazon DynamoDB 개요 및 데이터 모델, Amazon DynamoDB 용량 모드, 쿼리, 스캔 및 보조 인덱스 활용',
        awsServices: ['Amazon DynamoDB'],
        learningObjectives: [
          'Amazon DynamoDB의 개념과 핵심 데이터 모델(테이블, 항목, 속성)을 이해할 수 있습니다.',
          'Amazon DynamoDB의 용량 모드(온디맨드, 프로비저닝)를 비교하고 선택할 수 있습니다.',
          '쿼리, 스캔 연산의 특징을 이해하고 보조 인덱스를 활용할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-5 완료', '데이터베이스 기본 개념 이해'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 7,
    title: '모니터링과 로깅 (Amazon CloudWatch, AWS CloudTrail)',
    description:
      'Amazon CloudWatch 기본 개념, 알람 및 로그 분석, CloudTrail 통합 분석을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'lab',
        title: 'Amazon CloudWatch 대시보드 구성',
        hasContent: true,
        markdownPath: '/content/week7/7-1-cloudwatch-dashboard.md',
        description:
          '클라우드 모니터링 개요 및 전략, Amazon CloudWatch 개요, 지표 수집 및 대시보드 구성',
        awsServices: ['Amazon CloudWatch'],
        learningObjectives: [
          '클라우드 모니터링의 개요와 전략을 이해할 수 있습니다.',
          'Amazon CloudWatch의 핵심 개념(네임스페이스, 지표, 차원)을 설명할 수 있습니다.',
          'Amazon CloudWatch 지표를 수집하고 대시보드를 구성할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon CloudWatch Logs 분석',
        hasContent: true,
        markdownPath: '/content/week7/7-2-cloudwatch-logs.md',
        description:
          'Amazon CloudWatch 알람 기능, Amazon CloudWatch Logs 활용, Amazon CloudWatch Logs 분석',
        awsServices: ['Amazon CloudWatch'],
        learningObjectives: [
          'Amazon CloudWatch 알람의 주요 기능과 설정 방법을 이해하고 활용할 수 있습니다.',
          'Amazon CloudWatch Logs의 수집, 저장 및 관리 방법을 파악하고 적용할 수 있습니다.',
          'Amazon CloudWatch Logs Insights를 활용하여 로그를 분석할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'AWS CloudTrail 및 Amazon CloudWatch Logs 통합 분석',
        hasContent: false,
        description:
          'Amazon CloudTrail 개요, Amazon CloudTrail 이벤트 로그, Amazon CloudWatch와 CloudTrail 통합',
        awsServices: ['AWS CloudTrail', 'Amazon CloudWatch'],
        learningObjectives: [
          'AWS CloudTrail의 목적과 주요 기능을 이해할 수 있습니다.',
          'AWS CloudTrail 이벤트 로그의 유형과 구조를 설명할 수 있습니다.',
          'Amazon CloudWatch와 AWS CloudTrail 통합을 통해 고급 모니터링 솔루션을 구성할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-6 완료'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 8,
    title: '중간고사',
    description: '중간고사',
    sessions: [
      { session: 1, type: 'none', title: '중간고사', hasContent: false },
    ],
    prerequisites: ['Week 1-7 완료'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 9,
    title: '서버리스 아키텍처 구성',
    description:
      'AWS 서버리스 컴퓨팅 개요, AWS Lambda 함수 개발, API Gateway 서비스 구축을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: 'AWS 서버리스 컴퓨팅 개요',
        hasContent: false,
        description:
          '모던 애플리케이션 소개, 서버리스 컴퓨팅 개요, AWS 서버리스 컴퓨팅 서비스',
        awsServices: ['AWS Lambda'],
        learningObjectives: [
          '모던 애플리케이션의 특징과 서버리스 컴퓨팅의 개념을 이해할 수 있습니다.',
          '서버리스 컴퓨팅의 주요 이점과 제약사항을 설명할 수 있습니다.',
          'AWS 서버리스 컴퓨팅 서비스(Lambda, API Gateway, Step Functions 등)를 파악할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'AWS Lambda 함수 개발',
        hasContent: true,
        markdownPath: '/content/week9/9-2-lambda-function.md',
        description:
          'AWS Lambda 개요, AWS Lambda 함수 개발, AWS Lambda 함수 배포',
        awsServices: ['AWS Lambda'],
        learningObjectives: [
          'AWS Lambda의 기본 개념과 주요 특징을 이해할 수 있습니다.',
          'AWS Lambda 함수를 개발하고 이벤트 소스를 구성할 수 있습니다.',
          'AWS Lambda 함수를 배포하고 모니터링할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'lab',
        title: 'Amazon API Gateway 서비스 구축',
        hasContent: true,
        markdownPath: '/content/week9/9-3-api-gateway.md',
        description:
          'Amazon API Gateway 개요, Amazon API Gateway 기능, Amazon API Gateway 배포',
        awsServices: ['Amazon API Gateway', 'AWS Lambda'],
        learningObjectives: [
          'Amazon API Gateway의 목적과 기본 아키텍처를 이해할 수 있습니다.',
          'Amazon API Gateway의 주요 기능(스테이지, 메서드, 통합)을 활용할 수 있습니다.',
          'API의 효과적인 배포 및 관리 방법을 습득할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-7 완료'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 10,
    title: '컨테이너 아키텍처 (Amazon ECS/Amazon EKS)',
    description:
      '컨테이너 기술 기초, AWS ECR 및 ECS 기본 구성, Kubernetes 및 Amazon EKS를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'lab',
        title: 'Docker 컨테이너 이미지 빌드',
        hasContent: true,
        markdownPath: '/content/week10/10-1-docker-container.md',
        description:
          '컨테이너 기술 개요 및 가상머신 비교, Docker 아키텍처 및 핵심 개념, Dockerfile 소개',
        awsServices: ['Amazon ECR'],
        learningObjectives: [
          '컨테이너의 개념과 가상머신과의 차이점을 이해할 수 있습니다.',
          'Docker의 기본 개념과 구성요소(이미지, 컨테이너, 레지스트리)를 설명할 수 있습니다.',
          'Dockerfile을 작성하여 컨테이너 이미지를 빌드할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon ECS 서비스 배포',
        hasContent: true,
        markdownPath: '/content/week10/10-2-ecs-service-deploy.md',
        description:
          'AWS 컨테이너 서비스, Amazon ECR 개요, Amazon ECS 활용',
        awsServices: ['Amazon ECS', 'Amazon ECR'],
        learningObjectives: [
          'Amazon ECR의 주요 기능과 컨테이너 이미지 관리 방법을 파악할 수 있습니다.',
          'Amazon ECS의 핵심 개념(태스크 정의, 서비스, 클러스터)을 이해할 수 있습니다.',
          'Amazon ECS를 활용하여 컨테이너화된 애플리케이션을 배포하고 관리할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'Kubernetes 및 Amazon EKS 소개',
        hasContent: false,
        description:
          'Kubernetes 기본 개념, Amazon EKS 개요, Amazon EKS에 지속적 배포',
        awsServices: ['Amazon EKS'],
        learningObjectives: [
          'Kubernetes의 기본 개념과 아키텍처를 이해할 수 있습니다.',
          'Amazon EKS의 개요와 Amazon ECS와의 차이를 설명할 수 있습니다.',
          'Amazon EKS에서의 지속적 배포 방법을 이해할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-9 완료', 'Docker 기본 개념 이해'],
    estimatedTime: '180분',
    difficulty: 'intermediate',
  },
  {
    week: 11,
    title: 'AWS 글로벌 인프라 및 엣지 컴퓨팅',
    description:
      'AWS 글로벌 인프라 심화, Amazon CloudFront 콘텐츠 전송 최적화, Amazon Route 53 글로벌 트래픽 관리를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: 'AWS 글로벌 인프라 심화',
        hasContent: false,
        description:
          'AWS 글로벌 인프라 구성 요소, 글로벌 서비스와 리전 서비스 비교, 엣지 서비스',
        awsServices: [],
        learningObjectives: [
          'AWS 글로벌 인프라의 핵심 구성 요소와 아키텍처를 이해할 수 있습니다.',
          '글로벌 서비스와 리전 서비스의 차이를 비교할 수 있습니다.',
          '엣지 서비스의 개념과 역할을 설명할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'Amazon CloudFront 배포 구성',
        hasContent: true,
        markdownPath: '/content/week11/11-2-cloudfront-deploy.md',
        description:
          'Amazon CloudFront 서비스 소개, Amazon CloudFront 동작 방식, 오리진 보호를 위한 정책',
        awsServices: ['Amazon CloudFront'],
        learningObjectives: [
          'Amazon CloudFront의 핵심 기능과 CDN으로서의 역할을 이해할 수 있습니다.',
          'Amazon CloudFront의 동작 방식(엣지 로케이션, 캐시 동작)을 설명할 수 있습니다.',
          '오리진 액세스 제어(OAC)를 활용한 오리진 보호 정책을 구성할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: 'Amazon Route 53을 활용한 글로벌 트래픽 관리',
        hasContent: false,
        description:
          'DNS(Domain Name Service) 개요, Amazon Route 53 서비스 소개, Amazon Route 53 라우팅 정책',
        awsServices: ['Amazon Route 53'],
        learningObjectives: [
          'DNS의 기본 개념과 인터넷 인프라에서의 중요성을 이해할 수 있습니다.',
          'Amazon Route 53의 주요 기능과 호스팅 영역을 설명할 수 있습니다.',
          'Amazon Route 53의 다양한 라우팅 정책(단순, 가중치, 지연 시간, 장애 조치 등)을 학습할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-10 완료'],
    estimatedTime: '180분',
    difficulty: 'advanced',
  },
  {
    week: 12,
    title: '백업 및 재해 복구 설계',
    description:
      '클라우드에서의 백업 및 복구, AWS 백업 메커니즘, AWS Backup 서비스 및 재해 복구 전략을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: '클라우드에서의 백업 및 복구 특징',
        hasContent: false,
        description:
          '백업과 복구의 설계 원칙, 백업과 복구의 핵심 지표, 클라우드에서의 백업 및 복구',
        awsServices: ['AWS Backup'],
        learningObjectives: [
          '효과적인 백업과 복구 전략을 위한 설계 원칙을 이해할 수 있습니다.',
          'RPO(복구 시점 목표)와 RTO(복구 시간 목표)의 개념을 설명할 수 있습니다.',
          '클라우드 환경에서의 백업 및 복구 특징과 이점을 이해할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'theory',
        title: 'AWS에서의 백업 및 복원',
        hasContent: false,
        description:
          'AWS 백업 메커니즘, AWS 서비스의 백업 방법, 주요 AWS 서비스 백업 방법',
        awsServices: ['AWS Backup'],
        learningObjectives: [
          'AWS 백업 메커니즘(스냅샷, 복제, 버전 관리)을 이해할 수 있습니다.',
          'AWS 서비스별 백업 방법(EBS 스냅샷, RDS 백업, S3 버전 관리)을 설명할 수 있습니다.',
          '주요 AWS 서비스의 백업 및 복원 절차를 이해할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'lab',
        title: '기본 백업 전략 구성',
        hasContent: true,
        markdownPath: '/content/week12/12-3-backup-strategy.md',
        description:
          'AWS Backup 서비스 소개, AWS Backup 핵심 기능 및 동작 방식, AWS 재해 복구 전략 유형 및 비교',
        awsServices: ['AWS Backup'],
        learningObjectives: [
          'AWS Backup 서비스의 주요 기능과 클라우드 리소스 보호 메커니즘을 이해할 수 있습니다.',
          'AWS Backup의 핵심 기능(백업 계획, 백업 볼트, 복구 시점)을 활용할 수 있습니다.',
          '다양한 AWS 재해 복구 전략 유형(백업/복원, 파일럿 라이트, 웜 스탠바이, 다중 사이트)을 비교할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-11 완료'],
    estimatedTime: '180분',
    difficulty: 'advanced',
  },
  {
    week: 13,
    title: '클라우드 비용 최적화 및 요금 분석',
    description:
      'AWS 요금 체계, 비용 모니터링 및 분석 도구, 클라우드 비용 최적화 전략을 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: 'AWS 요금 체계의 이해',
        hasContent: false,
        description:
          '클라우드 소비 모델, AWS 요금 모델 이해, 주요 AWS 서비스별 요금 구조',
        awsServices: [],
        learningObjectives: [
          '클라우드 소비 모델의 특성과 전통적인 IT 소비 모델과의 차이점을 이해할 수 있습니다.',
          'AWS 요금 모델(온디맨드, 예약, 스팟, Savings Plans)을 이해할 수 있습니다.',
          '주요 AWS 서비스별 요금 구조를 파악할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'lab',
        title: 'AWS Cost Explorer 기본 기능',
        hasContent: true,
        markdownPath: '/content/week13/13-2-cost-explorer.md',
        description:
          'AWS 비용 계획 및 관리 관련 서비스, AWS 비용 모니터링 및 분석 관련 서비스, AWS 비용 최적화 관련 서비스',
        awsServices: ['AWS Cost Explorer'],
        learningObjectives: [
          'AWS Cost Explorer를 활성화하고 비용 분석 대시보드의 주요 기능을 이해할 수 있습니다.',
          'Amazon SNS 토픽을 생성하고 이메일 구독을 구성하여 알림 채널을 설정할 수 있습니다.',
          'AWS Budgets를 생성하고 SNS와 연동하여 비용 알림 시스템을 구축할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'theory',
        title: '클라우드 비용 최적화 전략',
        hasContent: false,
        description:
          '효과적인 비용 관리 전략, 클라우드 재무 관리, AWS 프리 티어',
        awsServices: [],
        learningObjectives: [
          '태깅 전략, 비용 할당 태그 활용 등 효과적인 클라우드 비용 관리 방법을 구현할 수 있습니다.',
          '클라우드 재무 관리(FinOps)의 개념과 원칙을 이해할 수 있습니다.',
          'AWS 프리 티어의 유형과 활용 방법을 설명할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-12 완료'],
    estimatedTime: '180분',
    difficulty: 'advanced',
  },
  {
    week: 14,
    title: '다중 계정 및 조직 관리 설계',
    description:
      '다중 계정 아키텍처, AWS Organizations, AWS IAM Identity Center를 학습합니다',
    sessions: [
      {
        session: 1,
        type: 'theory',
        title: '다중 계정 아키텍처의 이해와 설계',
        hasContent: false,
        description:
          'AWS 계정 개요, 다중 계정 전략, 다중 계정 설계 패턴',
        awsServices: ['AWS Organizations'],
        learningObjectives: [
          'AWS 계정의 기본 개념과 조직 내 계정 관리의 중요성을 이해할 수 있습니다.',
          '다중 계정 전략의 이점과 설계 원칙을 설명할 수 있습니다.',
          '다중 계정 설계 패턴(보안, 로깅, 공유 서비스 계정)을 이해할 수 있습니다.',
        ],
      },
      {
        session: 2,
        type: 'theory',
        title: 'AWS Organizations를 활용한 계정 관리',
        hasContent: false,
        description:
          'AWS Organizations 개요, AWS Organizations 설정 및 관리, 정책을 통한 계정 관리',
        awsServices: ['AWS Organizations'],
        learningObjectives: [
          'AWS Organizations의 핵심 개념과 다중 계정 환경에서의 역할을 이해할 수 있습니다.',
          'AWS Organizations를 설정하고 OU(조직 단위)를 구성할 수 있습니다.',
          'SCP(서비스 제어 정책)를 통한 계정 관리 방법을 설명할 수 있습니다.',
        ],
      },
      {
        session: 3,
        type: 'lab',
        title: 'AWS IAM Identity Center 통합 인증',
        hasContent: true,
        markdownPath: '/content/week14/14-3-iam-identity-center.md',
        description:
          '다중 계정 액세스 관리 개요, AWS IAM Identity Center 서비스 소개, AWS IAM Identity Center 서비스 활용',
        awsServices: ['AWS IAM Identity Center'],
        learningObjectives: [
          '다중 계정 환경에서의 액세스 관리 과제와 해결 방안을 이해할 수 있습니다.',
          'AWS IAM Identity Center의 주요 기능과 중앙 집중식 ID 관리 메커니즘을 파악할 수 있습니다.',
          'AWS IAM Identity Center를 활용하여 SSO(Single Sign-On)를 구성할 수 있습니다.',
        ],
      },
    ],
    prerequisites: ['Week 1-13 완료'],
    estimatedTime: '180분',
    difficulty: 'advanced',
  },
  {
    week: 15,
    title: '기말고사',
    description: '기말고사',
    sessions: [
      { session: 1, type: 'none', title: '기말고사', hasContent: false },
    ],
    prerequisites: ['Week 1-14 완료'],
    estimatedTime: '180분',
    difficulty: 'advanced',
  },
];

// 세션 타입별 아이콘 및 레이블
export const sessionTypeConfig = {
  theory: { icon: 'file', label: '이론', color: 'grey', emoji: '📄' },
  lab: { icon: 'settings', label: '실습', color: 'blue', emoji: '🔬' },
  demo: { icon: 'video-on', label: '데모', color: 'green', emoji: '🎥' },
  none: { icon: 'edit', label: '시험', color: 'red', emoji: '📝' },
} as const;
