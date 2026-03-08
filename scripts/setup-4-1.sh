#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab05: Amazon EC2 인스턴스 배포 - 최적 서버 구성 및 관리
# 목적: EC2 실습을 위한 기본 VPC 네트워크 환경 생성 (NAT Gateway 제외)
# 예상 시간: 약 5분
# 예상 비용: 기본 VPC 리소스는 무료
# 
# 구성 요소:
# - VPC: CloudArchitect-Lab-VPC (10.0.0.0/16)
# - Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.0.0/24, ap-northeast-2a)
# - Internet Gateway: CloudArchitect-Lab-IGW
# - Security Group: CloudArchitect-Lab-Web-SG (HTTP, HTTPS, SSH)
# 
# 학생 실습 내용:
# - EC2 인스턴스는 실습 가이드에서 직접 생성
# - User Data를 통한 Apache 설치 실습
# - Security Group 규칙 설정 실습
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
    echo "  📋 네트워크 인프라 구성:"
    echo "    🌐 VPC: CloudArchitect-Lab-VPC (10.0.0.0/16)"
    echo "    🌍 Internet Gateway: CloudArchitect-Lab-IGW"
    echo ""
    echo "  🏢 서브넷 구성:"
    echo "    🔓 Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.0.0/24, ap-northeast-2a)"
    echo ""
    echo "  🛡️ 보안 구성:"
    echo "    🌐 Web Security Group: CloudArchitect-Lab-Web-SG"
    echo "      • HTTP (80), HTTPS (443), SSH (22) 허용"
    echo ""
    echo "  🎯 핵심 학습 목표:"
    echo "    • EC2 인스턴스 생성 및 관리"
    echo "    • User Data를 통한 자동 소프트웨어 설치"
    echo "    • Security Group을 통한 네트워크 보안"
    echo ""
    echo "  ⚠️ 주의사항:"
    echo "    • EC2 인스턴스 생성 시 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 5분"
    echo ""
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab05 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab05 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab05 리소스 생성을 시작합니다..."
    echo ""
}



# ===========================================
# VPC 생성/재사용 함수
# ===========================================
create_vpc() {
    show_info "VPC 확인/생성 중..."
    
    # 기존 VPC 확인
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
            "Name=cidr-block-association.cidr-block,Values=10.0.0.0/16" \
            "Name=state,Values=available" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        show_success "기존 VPC 재사용: CloudArchitect-Lab-VPC ($VPC_ID)"
        return 0
    fi
    
    show_info "새 VPC 생성 중..."
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab05},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab05-student.sh}]' \
        --query 'Vpc.VpcId' --output text)
    
    # DNS 설정 활성화
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
    
    show_success "VPC 생성 완료: CloudArchitect-Lab-VPC ($VPC_ID)"
}

# ===========================================
# Internet Gateway 생성/재사용 함수
# ===========================================
create_internet_gateway() {
    show_info "Internet Gateway 확인/생성 중..."
    
    # 기존 IGW 확인
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-IGW" \
            "Name=attachment.vpc-id,Values=$VPC_ID" \
            "Name=attachment.state,Values=available" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        show_success "기존 Internet Gateway 재사용: CloudArchitect-Lab-IGW ($IGW_ID)"
        return 0
    fi
    
    show_info "새 Internet Gateway 생성 중..."
    IGW_ID=$(aws ec2 create-internet-gateway \
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab05},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab05-student.sh}]' \
        --query 'InternetGateway.InternetGatewayId' --output text)
    
    # VPC에 연결
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
    
    show_success "Internet Gateway 생성 및 연결 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
}

# ===========================================
# Public Subnet 생성/재사용 함수
# ===========================================
create_public_subnet() {
    show_info "Public Subnet 확인/생성 중..."
    
    # 기존 Public Subnet 확인
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.0.0/24" \
            "Name=availability-zone,Values=${REGION}a" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
        show_success "기존 Public Subnet 재사용: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    else
        show_info "새 Public Subnet 생성 중..."
        PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.0.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab05},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2a},{Key=CreatedBy,Value=setup-lab05-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        show_success "Public Subnet 생성 완료: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    fi
    
    # Public IP 자동 할당 설정
    aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch
    
    # Route Table 생성 및 설정
    show_info "Route Table 설정 중..."
    
    # 기존 Route Table 확인
    PUBLIC_RT_ID=$(aws ec2 describe-route-tables \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_RT_ID" = "None" ] || [ -z "$PUBLIC_RT_ID" ]; then
        PUBLIC_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab05},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-lab05-student.sh}]' \
            --query 'RouteTable.RouteTableId' --output text)
    fi
    
    # 인터넷 게이트웨이로의 라우트 추가
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1 || true
    
    # 서브넷을 라우트 테이블에 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    
    show_success "Route Table 설정 완료"
}

# ===========================================
# Security Group 생성/재사용 함수
# ===========================================
create_security_group() {
    show_info "Security Group 확인/생성 중..."
    
    # 기존 Web Security Group 확인
    WEB_SG_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=CloudArchitect-Lab-Web-SG" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$WEB_SG_ID" != "None" ] && [ -n "$WEB_SG_ID" ]; then
        show_success "기존 Web Security Group 재사용: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    else
        show_info "새 Web Security Group 생성 중..."
        WEB_SG_ID=$(aws ec2 create-security-group \
            --group-name CloudArchitect-Lab-Web-SG \
            --description "CloudArchitect Lab05 - Web Server Security Group" \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-Web-SG},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab05},{Key=Component,Value=Security},{Key=Type,Value=Web},{Key=CreatedBy,Value=setup-lab05-student.sh}]' \
            --query 'GroupId' --output text)
        
        # 인바운드 규칙 추가
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null 2>&1
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
                
        show_success "Web Security Group 생성 완료: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    fi
}



# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab05 EC2 기초 인프라 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    echo "  ✅ Security Group: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "  • 이제 Lab05 EC2 인스턴스 생성 실습을 진행할 수 있습니다"
    echo "  • 실습 가이드에 따라 EC2 인스턴스를 직접 생성하세요"
    echo "  • User Data를 통한 Apache 설치 실습 가능"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Lab05 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    aws_info=$(get_aws_account_info)
    account_id=$(echo "$aws_info" | cut -d':' -f1)
    region=$(echo "$aws_info" | cut -d':' -f2)
    
    if [ -z "$region" ]; then
        show_error "AWS 리전이 설정되지 않았습니다."
        show_info "다음 명령어로 리전을 설정해주세요: aws configure set region ap-northeast-2"
        exit 1
    fi
    
    # REGION 변수를 전역으로 export
    export REGION="$region"
    
    # 헤더 표시
    echo "================================"
    echo "Lab05: Amazon EC2 인스턴스 배포 - 최적 서버 구성 및 관리"
    echo "================================"
    echo "목적: EC2 실습을 위한 기본 VPC 네트워크 환경 생성"
    echo "예상 시간: 약 5분"
    echo "예상 비용: 기본 VPC 리소스는 무료"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws ec2 describe-vpcs --max-items 1 >/dev/null 2>&1 && show_success "VPC 권한 확인 완료" || show_warning "VPC 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 4 "VPC 생성 중..."
    create_vpc
    echo ""
    
    show_progress 2 4 "Internet Gateway 생성 중..."
    create_internet_gateway
    echo ""
    
    show_progress 3 4 "Public Subnet 생성 중..."
    create_public_subnet
    echo ""
    
    show_progress 4 4 "Security Group 생성 중..."
    create_security_group
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"