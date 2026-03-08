#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab15: Amazon ECS 서비스 배포 - 컨테이너 오케스트레이션 관리
# 목적: ECS 실습을 위한 완전한 인프라 구축 (VPC, ECR, Docker 이미지)
# 예상 시간: 약 10분
# 예상 비용: ECR 스토리지 및 NAT Gateway로 인해 과금될 수 있음
# 
# 구성 요소:
# - VPC: CloudArchitect-Lab-VPC (10.0.0.0/16)
# - Public Subnet 2개 (Multi-AZ)
# - Private Subnet 2개 (Multi-AZ)
# - Internet Gateway, NAT Gateway
# - 보안 그룹: ECS 서비스용
# - ECR 리포지토리: cloudarchitect-lab-webapp
# - Docker 이미지 빌드 및 푸시
# 
# 학생 실습 내용:
# - ECS 클러스터 생성 및 구성
# - 태스크 정의 및 서비스 생성 실습
# - 컨테이너 오케스트레이션 관리
# ===========================================



# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 공통 함수들
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    echo -e "${PURPLE}🔥 [$current/$total] $message${NC}"
}

show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_info() {
    echo -e "${CYAN}ℹ️ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

show_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

show_important() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

# 의존성 체크 함수
check_dependencies() {
    local missing_deps=()
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        show_error "필수 도구가 설치되어 있지 않습니다: ${missing_deps[*]}"
        show_info "CloudShell에서는 jq와 docker가 기본 제공됩니다."
        show_info "로컬 환경에서는 다음 명령어로 설치하세요:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                jq) echo "  • jq: sudo yum install -y jq" ;;
                docker) echo "  • docker: sudo yum install -y docker && sudo systemctl start docker" ;;
            esac
        done
        exit 1
    fi
}

# 단계별 대기 함수
wait_for_next_step() {
    echo ""
    echo -e "${CYAN}⏳ 다음 단계 준비 중...${NC}"
    sleep 2
    echo ""
}

# AWS CLI 프로필 및 리전 확인
get_aws_account_info() {
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local region=$(aws configure get region 2>/dev/null)
    
    if [ -z "$account_id" ]; then
        show_error "AWS 자격 증명을 확인할 수 없습니다."
        show_info "다음 명령어로 AWS CLI를 설정해주세요:"
        echo "  aws configure"
        exit 1
    fi
    
    echo "$account_id:$region"
}

# 생성 계획 표시 함수
show_creation_plan() {
    echo ""
    show_important "🚀 생성 계획:"
    echo ""
    
    # 기존 리소스 확인
    local existing_vpc=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    local existing_repo=$(aws ecr describe-repositories --repository-names "cloudarchitect-lab-webapp" --query 'repositories[0].repositoryName' --output text 2>/dev/null)
    
    echo "  📋 네트워크 인프라 구성:"
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        echo "  🔄 VPC: CloudArchitect-Lab-VPC ($existing_vpc) - 기존 재사용"
    else
        echo "  ✨ VPC: CloudArchitect-Lab-VPC (10.0.0.0/16) - 새로 생성"
    fi
    echo "  🌍 Internet Gateway: CloudArchitect-Lab-IGW"
    echo "  🔄 NAT Gateway: CloudArchitect-Lab-NAT-GW"
    echo "  🏢 Public Subnet 2개 (Multi-AZ)"
    echo "  🔒 Private Subnet 2개 (Multi-AZ)"
    echo "  🛡️ Security Group: ECS 서비스용"
    echo ""
    
    echo "  📋 컨테이너 인프라 구성:"
    if [ "$existing_repo" = "cloudarchitect-lab-webapp" ]; then
        local repo_uri=$(aws ecr describe-repositories --repository-names "cloudarchitect-lab-webapp" --query 'repositories[0].repositoryUri' --output text)
        echo "  🔄 ECR 리포지토리: cloudarchitect-lab-webapp ($repo_uri) - 기존 재사용"
    else
        echo "  ✨ ECR 리포지토리: cloudarchitect-lab-webapp - 새로 생성"
    fi
    echo "  🐳 Docker 이미지: Node.js 웹 애플리케이션"
    echo "  🔐 이미지 스캔: 활성화"
    echo "  🔒 암호화: AES256"
    echo ""
    
    echo "  🎯 핵심 학습 목표:"
    echo "    • VPC 네트워크 인프라 구성"
    echo "    • ECR 리포지토리 생성 및 관리"
    echo "    • Docker 이미지 빌드 및 푸시"
    echo "    • ECS 클러스터 및 서비스 구성"
    echo "    • 컨테이너 오케스트레이션 관리"
    echo ""
    
    echo "  ⚠️ 주의사항:"
    echo "    • NAT Gateway 및 ECR 스토리지로 인해 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 10분"
    echo ""
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab15 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab15 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab15 리소스 생성을 시작합니다..."
    echo ""
}

# VPC 생성/재사용 함수 (Demo04 기반)
create_vpc_infrastructure() {
    show_info "VPC 확인/생성 중..."
    
    # 간단한 필터링으로 기존 VPC 확인
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
            "Name=cidr-block-association.cidr-block,Values=10.0.0.0/16" \
            "Name=state,Values=available" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        show_success "🔄 기존 VPC 재사용: CloudArchitect-Lab-VPC ($VPC_ID)"
    else
        # 새 VPC 생성
        show_info "새 VPC 생성 중..."
        VPC_ID=$(aws ec2 create-vpc \
            --cidr-block 10.0.0.0/16 \
            --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'Vpc.VpcId' --output text)
        
        if [ -n "$VPC_ID" ]; then
            # DNS 호스트명 활성화
            aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
            aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
            show_success "✨ VPC 생성 완료: CloudArchitect-Lab-VPC ($VPC_ID)"
        else
            show_error "VPC 생성 실패"
            exit 1
        fi
    fi
    
    # Internet Gateway 생성/연결
    create_internet_gateway
    
    # 서브넷 생성
    create_subnets
    
    # NAT Gateway 생성
    create_nat_gateway
    
    # Route Table 설정
    create_route_tables
    
    # Security Group 생성
    create_security_groups
}

# Internet Gateway 생성 및 연결 (Demo04 기반)
create_internet_gateway() {
    show_info "Internet Gateway 확인/생성 중..."
    
    # VPC 의존성 체크
    if [ -z "$VPC_ID" ]; then
        show_error "VPC ID가 설정되지 않았습니다."
        exit 1
    fi
    
    # VPC에 연결된 IGW 확인 (이름 태그 우선, 없으면 아무 IGW나)
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-IGW" \
            "Name=attachment.vpc-id,Values=$VPC_ID" \
            "Name=attachment.state,Values=available" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        show_success "🔄 기존 Internet Gateway 재사용: CloudArchitect-Lab-IGW ($IGW_ID)"
        return 0
    fi
    
    # 이름 태그가 없어도 VPC에 이미 연결된 IGW가 있으면 재사용
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" "Name=attachment.state,Values=available" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        show_success "🔄 기존 Internet Gateway 재사용: $IGW_ID (VPC에 이미 연결됨)"
        return 0
    fi
    
    # 새 Internet Gateway 생성
    show_info "새 Internet Gateway 생성 중..."
    IGW_ID=$(aws ec2 create-internet-gateway \
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
        --query 'InternetGateway.InternetGatewayId' --output text)
    
    # VPC에 연결
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
    show_success "✨ Internet Gateway 생성 및 연결 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
}

# 서브넷 생성 (4개 서브넷) - Demo04 기반
create_subnets() {
    show_info "서브넷 확인/생성 중... (4개 서브넷)"
    
    # VPC 의존성 체크
    if [ -z "$VPC_ID" ]; then
        show_error "VPC ID가 설정되지 않았습니다."
        exit 1
    fi
    
    # Public Subnet 1 확인/생성 (ap-northeast-2a)
    PUBLIC_SUBNET_1_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-1" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.0.0/24" \
            "Name=availability-zone,Values=${REGION}a" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_SUBNET_1_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_1_ID" ]; then
        show_success "🔄 기존 Public Subnet 1 재사용: CloudArchitect-Lab-Public-Subnet-1 ($PUBLIC_SUBNET_1_ID)"
    else
        show_info "새 Public Subnet 1 생성 중..."
        PUBLIC_SUBNET_1_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.0.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet-1},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2a},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        
        # 자동 IP 할당 활성화
        aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_1_ID --map-public-ip-on-launch
        show_success "✨ Public Subnet 1 생성 완료: CloudArchitect-Lab-Public-Subnet-1 ($PUBLIC_SUBNET_1_ID)"
    fi
    
    # Public Subnet 2 확인/생성 (ap-northeast-2b)
    PUBLIC_SUBNET_2_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-2" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.1.0/24" \
            "Name=availability-zone,Values=ap-northeast-2b" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_SUBNET_2_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_2_ID" ]; then
        show_success "🔄 기존 Public Subnet 2 재사용: CloudArchitect-Lab-Public-Subnet-2 ($PUBLIC_SUBNET_2_ID)"
    else
        show_info "새 Public Subnet 2 생성 중..."
        PUBLIC_SUBNET_2_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.1.0/24 \
            --availability-zone ap-northeast-2b \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet-2},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2b},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        
        # 자동 IP 할당 활성화
        aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_2_ID --map-public-ip-on-launch
        show_success "✨ Public Subnet 2 생성 완료: CloudArchitect-Lab-Public-Subnet-2 ($PUBLIC_SUBNET_2_ID)"
    fi
    
    # Private Subnet 1 확인/생성 (ap-northeast-2a)
    PRIVATE_SUBNET_1_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-1" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.128.0/24" \
            "Name=availability-zone,Values=${REGION}a" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PRIVATE_SUBNET_1_ID" != "None" ] && [ -n "$PRIVATE_SUBNET_1_ID" ]; then
        show_success "🔄 기존 Private Subnet 1 재사용: CloudArchitect-Lab-Private-Subnet-1 ($PRIVATE_SUBNET_1_ID)"
    else
        show_info "새 Private Subnet 1 생성 중..."
        PRIVATE_SUBNET_1_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.128.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Private-Subnet-1},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Private},{Key=AZ,Value=2a},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        show_success "✨ Private Subnet 1 생성 완료: CloudArchitect-Lab-Private-Subnet-1 ($PRIVATE_SUBNET_1_ID)"
    fi
    
    # Private Subnet 2 확인/생성 (ap-northeast-2b)
    PRIVATE_SUBNET_2_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-2" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.129.0/24" \
            "Name=availability-zone,Values=ap-northeast-2b" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PRIVATE_SUBNET_2_ID" != "None" ] && [ -n "$PRIVATE_SUBNET_2_ID" ]; then
        show_success "🔄 기존 Private Subnet 2 재사용: CloudArchitect-Lab-Private-Subnet-2 ($PRIVATE_SUBNET_2_ID)"
    else
        show_info "새 Private Subnet 2 생성 중..."
        PRIVATE_SUBNET_2_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.129.0/24 \
            --availability-zone ap-northeast-2b \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Private-Subnet-2},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Private},{Key=AZ,Value=2b},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        show_success "✨ Private Subnet 2 생성 완료: CloudArchitect-Lab-Private-Subnet-2 ($PRIVATE_SUBNET_2_ID)"
    fi
    
    show_success "모든 서브넷 확인/생성 완료"
}

# NAT Gateway 생성 - Demo04 기반
create_nat_gateway() {
    show_info "NAT Gateway 확인/생성 중..."
    
    # 의존성 체크
    if [ -z "$VPC_ID" ] || [ -z "$PUBLIC_SUBNET_1_ID" ]; then
        show_error "VPC ID 또는 Public Subnet 1 ID가 설정되지 않았습니다."
        exit 1
    fi
    
    # 간단한 필터링으로 기존 NAT Gateway 확인
    NAT_GW_ID=$(aws ec2 describe-nat-gateways \
        --filter \
            "Name=tag:Name,Values=CloudArchitect-Lab-NAT-GW" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=state,Values=available" \
        --query 'NatGateways[0].NatGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$NAT_GW_ID" != "None" ] && [ -n "$NAT_GW_ID" ]; then
        show_success "🔄 기존 NAT Gateway 재사용: CloudArchitect-Lab-NAT-GW ($NAT_GW_ID)"
        # EIP 정보도 가져오기
        EIP_ALLOC_ID=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$NAT_GW_ID" --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text 2>/dev/null)
        return 0
    fi
    
    # 이름 태그가 없어도 VPC에 있는 NAT Gateway 재사용
    NAT_GW_ID=$(aws ec2 describe-nat-gateways \
        --filter \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=state,Values=available" \
        --query 'NatGateways[0].NatGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$NAT_GW_ID" != "None" ] && [ -n "$NAT_GW_ID" ]; then
        show_success "🔄 기존 NAT Gateway 재사용: $NAT_GW_ID (VPC에 이미 존재)"
        # EIP 정보도 가져오기
        EIP_ALLOC_ID=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$NAT_GW_ID" --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text 2>/dev/null)
        return 0
    fi
    
    # 새 NAT Gateway 생성
    show_info "새 NAT Gateway 생성 중..."
    
    # Elastic IP 할당
    EIP_ALLOC_ID=$(aws ec2 allocate-address \
        --domain vpc \
        --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=CloudArchitect-Lab-NAT-EIP},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
        --query 'AllocationId' --output text)
    
    # NAT Gateway 생성 (첫 번째 Public 서브넷에 배치)
    NAT_GW_ID=$(aws ec2 create-nat-gateway \
        --subnet-id $PUBLIC_SUBNET_1_ID \
        --allocation-id $EIP_ALLOC_ID \
        --query 'NatGateway.NatGatewayId' --output text)
    
    # NAT Gateway 사용 가능 상태까지 대기
    show_info "NAT Gateway 생성 대기 중... (약 2-3분 소요)"
    aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
    
    # NAT Gateway에 태그 추가 (생성 후)
    aws ec2 create-tags --resources $NAT_GW_ID --tags \
        Key=Name,Value=CloudArchitect-Lab-NAT-GW \
        Key=Project,Value=CloudArchitect \
        Key=Lab,Value=Lab15 \
        Key=Component,Value=Network \
        Key=CreatedBy,Value=setup-lab15-student.sh
    
    show_success "✨ NAT Gateway 생성 완료: CloudArchitect-Lab-NAT-GW ($NAT_GW_ID)"
}

# Route Table 생성 및 설정 - Demo04 기반
create_route_tables() {
    show_info "Route Table 확인/생성 중..."
    
    # 의존성 체크
    if [ -z "$VPC_ID" ] || [ -z "$IGW_ID" ] || [ -z "$NAT_GW_ID" ]; then
        show_error "VPC, IGW, NAT Gateway가 설정되지 않았습니다."
        exit 1
    fi
    
    # Public Route Table 확인/생성
    PUBLIC_RT_ID=$(aws ec2 describe-route-tables \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
        show_success "기존 Public Route Table 재사용: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    else
        show_info "새 Public Route Table 생성 중..."
        PUBLIC_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'RouteTable.RouteTableId' --output text)
        show_success "Public Route Table 생성 완료: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    fi
    
    # Private Route Table 확인/생성
    PRIVATE_RT_ID=$(aws ec2 describe-route-tables \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Private-RT" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null)
    
    if [ "$PRIVATE_RT_ID" != "None" ] && [ -n "$PRIVATE_RT_ID" ]; then
        show_success "기존 Private Route Table 재사용: CloudArchitect-Lab-Private-RT ($PRIVATE_RT_ID)"
    else
        show_info "새 Private Route Table 생성 중..."
        PRIVATE_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Private-RT},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Network},{Key=Type,Value=Private},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'RouteTable.RouteTableId' --output text)
        show_success "Private Route Table 생성 완료: CloudArchitect-Lab-Private-RT ($PRIVATE_RT_ID)"
    fi
    
    # 라우트 추가 (중복 방지)
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1 || true
    aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID >/dev/null 2>&1 || true
    
    # 서브넷 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_1_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_2_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_1_ID --route-table-id $PRIVATE_RT_ID >/dev/null 2>&1 || true
    aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_2_ID --route-table-id $PRIVATE_RT_ID >/dev/null 2>&1 || true
    
    show_success "Route Table 설정 완료"
}

# Security Group 생성 - Demo04 기반
create_security_groups() {
    show_info "Security Group 생성 중..."
    
    # VPC 의존성 체크
    if [ -z "$VPC_ID" ] || ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" >/dev/null 2>&1; then
        show_error "VPC가 존재하지 않습니다. VPC를 먼저 생성해주세요."
        exit 1
    fi
    
    # ALB Security Group 확인 또는 생성
    local existing_alb_sg=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=CloudArchitect-Lab-ALB-SG" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    if [ "$existing_alb_sg" != "None" ] && [ "$existing_alb_sg" != "" ]; then
        ALB_SG_ID=$existing_alb_sg
        show_success "🔄 기존 ALB Security Group 재사용: CloudArchitect-Lab-ALB-SG ($ALB_SG_ID)"
    else
        ALB_SG_ID=$(aws ec2 create-security-group \
            --group-name CloudArchitect-Lab-ALB-SG \
            --description "CloudArchitect Lab15 - Application Load Balancer Security Group" \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-ALB-SG},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Security},{Key=Type,Value=LoadBalancer},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'GroupId' --output text)
        
        # ALB SG 규칙 추가 (HTTP, HTTPS)
        aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1
        aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null 2>&1
        show_success "✨ ALB Security Group 생성 완료: CloudArchitect-Lab-ALB-SG ($ALB_SG_ID)"
    fi
    
    # ECS Security Group 확인 또는 생성
    local existing_ecs_sg=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=CloudArchitect-Lab-ECS-SG" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    if [ "$existing_ecs_sg" != "None" ] && [ "$existing_ecs_sg" != "" ]; then
        ECS_SG_ID=$existing_ecs_sg
        show_success "🔄 기존 ECS Security Group 재사용: CloudArchitect-Lab-ECS-SG ($ECS_SG_ID)"
    else
        ECS_SG_ID=$(aws ec2 create-security-group \
            --group-name CloudArchitect-Lab-ECS-SG \
            --description "CloudArchitect Lab15 - ECS Service Security Group" \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-ECS-SG},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab15},{Key=Component,Value=Security},{Key=Type,Value=ECS},{Key=CreatedBy,Value=setup-lab15-student.sh}]' \
            --query 'GroupId' --output text)
        
        # ECS SG 규칙 추가 (컨테이너 포트 3000, ALB에서만 접근 허용)
        aws ec2 authorize-security-group-ingress --group-id $ECS_SG_ID --protocol tcp --port 3000 --source-group $ALB_SG_ID >/dev/null 2>&1
        show_success "✨ ECS Security Group 생성 완료: CloudArchitect-Lab-ECS-SG ($ECS_SG_ID)"
    fi
}

# ECR 리포지토리 생성/재사용 함수
create_ecr_repository() {
    show_info "ECR 리포지토리 확인/생성 중..."
    
    local repo_name="cloudarchitect-lab-webapp"
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    # 기존 리포지토리 확인
    local existing_repo=$(aws ecr describe-repositories --repository-names "$repo_name" --query 'repositories[0].repositoryName' --output text 2>/dev/null)
    
    if [ "$existing_repo" = "$repo_name" ]; then
        show_success "기존 ECR 리포지토리 재사용: $repo_name"
        local repo_uri=$(aws ecr describe-repositories --repository-names "$repo_name" --query 'repositories[0].repositoryUri' --output text)
        REPO_URI="$repo_uri"
        return 0
    fi
    
    show_info "새 ECR 리포지토리 생성 중: $repo_name"
    
    # ECR 리포지토리 생성
    local repo_result=$(aws ecr create-repository \
        --repository-name "$repo_name" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256 \
        --region "$region" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        show_success "ECR 리포지토리 생성 완료: $repo_name"
        
        # 리포지토리 URI 추출
        REPO_URI=$(echo "$repo_result" | jq -r '.repository.repositoryUri')
        
        # 태그 추가
        local repo_arn="arn:aws:ecr:$region:$account_id:repository/$repo_name"
        aws ecr tag-resource \
            --resource-arn "$repo_arn" \
            --tags \
                Key=Project,Value=CloudArchitect \
                Key=Lab,Value=Lab15 \
                Key=Component,Value=Container \
                Key=Environment,Value=Lab \
                Key=CreatedBy,Value=setup-lab15-student.sh \
            2>/dev/null || true
        
        show_success "ECR 리포지토리 태그 설정 완료"
    else
        show_error "ECR 리포지토리 생성 실패: $repo_name"
        show_info "가능한 원인:"
        echo "  • ECR 권한 부족"
        echo "  • 리포지토리 이름 중복"
        echo "  • 네트워크 연결 문제"
        exit 1
    fi
}

# Docker 이미지 빌드 및 푸시 함수
build_and_push_docker_image() {
    show_info "Docker 이미지 빌드 및 푸시 중..."
    
    local repo_name="cloudarchitect-lab-webapp"
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local image_tag="latest"
    
    # 임시 디렉토리 생성
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Dockerfile 생성
    cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# package.json 생성
RUN echo '{"name": "cloudarchitect-lab-webapp", "version": "1.0.0", "main": "server.js", "scripts": {"start": "node server.js"}, "dependencies": {"express": "^4.18.0"}}' > package.json

# 의존성 설치
RUN npm install

# 애플리케이션 파일 생성
COPY server.js .

EXPOSE 3000

CMD ["npm", "start"]
EOF
    
    # Node.js 애플리케이션 파일 생성
    cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send(`
        <html>
            <head>
                <title>CloudArchitect Lab15 - ECS Container</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; background: #f0f8ff; }
                    .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                    h1 { color: #2c3e50; text-align: center; }
                    .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
                    .success { color: #27ae60; font-weight: bold; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🐳 CloudArchitect Lab15 - ECS Container Service</h1>
                    <div class="info">
                        <h3>컨테이너 정보:</h3>
                        <ul>
                            <li><strong>애플리케이션:</strong> Node.js + Express</li>
                            <li><strong>컨테이너 포트:</strong> 3000</li>
                            <li><strong>실행 환경:</strong> Amazon ECS</li>
                            <li><strong>이미지 저장소:</strong> Amazon ECR</li>
                        </ul>
                    </div>
                    <div class="success">
                        ✅ ECS 컨테이너 서비스가 성공적으로 실행 중입니다!
                    </div>
                    <p>이 웹 애플리케이션은 Amazon ECS에서 실행되는 Docker 컨테이너입니다.</p>
                    <p><strong>현재 시간:</strong> ${new Date().toLocaleString('ko-KR', {timeZone: 'Asia/Seoul'})}</p>
                </div>
            </body>
        </html>
    `);
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`CloudArchitect Lab15 app listening at http://0.0.0.0:${port}`);
});
EOF
    
    # Docker 이미지 빌드
    show_info "Docker 이미지 빌드 중..."
    if docker build -t "$repo_name:$image_tag" . >/dev/null 2>&1; then
        show_success "Docker 이미지 빌드 완료"
    else
        show_error "Docker 이미지 빌드 실패"
        show_info "Docker가 설치되어 있고 실행 중인지 확인해주세요"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # ECR 로그인
    show_info "ECR 로그인 중..."
    aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com" >/dev/null 2>&1
    
    # 이미지 태그 지정
    docker tag "$repo_name:$image_tag" "$REPO_URI:$image_tag" >/dev/null 2>&1
    
    # 이미지 푸시
    show_info "ECR에 이미지 푸시 중..."
    if docker push "$REPO_URI:$image_tag" >/dev/null 2>&1; then
        show_success "Docker 이미지 푸시 완료: $REPO_URI:$image_tag"
    else
        show_error "Docker 이미지 푸시 실패"
        cd - >/dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 정리
    cd - >/dev/null
    rm -rf "$temp_dir"
    docker rmi "$repo_name:$image_tag" >/dev/null 2>&1 || true
    docker rmi "$REPO_URI:$image_tag" >/dev/null 2>&1 || true
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab15 ECS 컨테이너 인프라 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 네트워크 인프라:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ NAT Gateway: CloudArchitect-Lab-NAT-GW ($NAT_GW_ID)"
    echo "  ✅ Public Subnets: 2개 (Multi-AZ)"
    echo "  ✅ Private Subnets: 2개 (Multi-AZ)"
    echo "  ✅ Security Group: CloudArchitect-Lab-ECS-SG ($ECS_SG_ID)"
    echo ""
    
    echo "📋 생성된 컨테이너 인프라:"
    echo "  ✅ ECR 리포지토리: cloudarchitect-lab-webapp"
    echo "  ✅ 리포지토리 URI: $REPO_URI"
    echo "  ✅ Docker 이미지: Node.js 웹 애플리케이션 (latest)"
    echo "  ✅ 이미지 스캔: 활성화"
    echo "  ✅ 암호화: AES256"
    echo ""
    
    echo "🐳 컨테이너 애플리케이션 정보:"
    echo "  • 애플리케이션: Node.js + Express"
    echo "  • 컨테이너 포트: 3000"
    echo "  • Health Check: /health 엔드포인트"
    echo "  • 이미지 태그: latest"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "  1. AWS 콘솔에서 ECS 서비스로 이동하세요"
    echo "  2. ECS 클러스터 생성:"
    echo "     • 클러스터 이름: CloudArchitect-Lab-Cluster-[고유번호] (예: CloudArchitect-Lab-Cluster-123)"
    echo "     • ⚠️ 중요: 클러스터 이름은 리전 내에서 고유해야 합니다"
    echo "     • 인프라: AWS Fargate (서버리스) 선택"
    echo "  3. Task Definition 생성:"
    echo "     • 이름: CloudArchitect-Lab-Task"
    echo "     • 컨테이너 이미지: $REPO_URI:latest"
    echo "     • 컨테이너 포트: 3000"
    echo "     • CPU: 0.25 vCPU, 메모리: 0.5 GB"
    echo "  4. IAM 역할 설정:"
    echo "     • Task Execution Role: ecsTaskExecutionRole 선택"
    echo "     • ⚠️ 역할이 없으면 자동 생성됩니다"
    echo "  5. ECS 서비스 생성 및 배포:"
    echo "     • 서비스 이름: CloudArchitect-Lab-Service"
    echo "     • 원하는 작업 수: 2"
    echo "     • 네트워킹: Private 서브넷 선택"
    echo "     • 로드 밸런서: Application Load Balancer 연결 (선택사항)"
    echo "  6. 컨테이너 오케스트레이션 기능을 경험하세요"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Lab15 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # 의존성 체크
    check_dependencies
    
    # AWS 계정 정보 확인
    local aws_info=$(get_aws_account_info)
    local account_id=$(echo "$aws_info" | cut -d':' -f1)
    local region=$(echo "$aws_info" | cut -d':' -f2)
    
    if [ -z "$region" ]; then
        show_error "AWS 리전이 설정되지 않았습니다."
        show_info "다음 명령어로 리전을 설정해주세요: aws configure set region ap-northeast-2"
        exit 1
    fi
    
    # 헤더 표시
    echo "================================"
    echo "Lab15: Amazon ECS 서비스 배포 - 컨테이너 오케스트레이션 관리"
    echo "================================"
    echo "목적: ECS 실습을 위한 완전한 인프라 구축 (VPC, ECR, Docker 이미지)"
    echo "예상 시간: 약 10분"
    echo "예상 비용: NAT Gateway 및 ECR 스토리지로 인해 과금될 수 있음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "미설정")
    echo "사용자: $user_arn"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws ec2 describe-vpcs --max-items 1 >/dev/null 2>&1 && show_success "VPC 권한 확인 완료" || show_warning "VPC 권한 제한됨"
    aws ecr describe-repositories --max-items 1 >/dev/null 2>&1 && show_success "ECR 권한 확인 완료" || show_warning "ECR 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 3 "VPC 네트워크 인프라 생성 중..."
    create_vpc_infrastructure
    echo ""
    
    show_progress 2 3 "ECR 리포지토리 생성 중..."
    create_ecr_repository
    echo ""
    
    show_progress 3 3 "Docker 이미지 빌드 및 푸시 중..."
    build_and_push_docker_image
    echo ""
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"