#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Lab08: Amazon RDS MySQL 데이터베이스 구축 - 관계형 데이터베이스 서비스
# ================================
# 목적: RDS 실습을 위한 VPC 네트워크 환경 및 EC2 클라이언트 생성
# 예상 시간: 약 10분
# 예상 비용: EC2 인스턴스로 인해 과금될 수 있음
# ================================



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

show_important() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

show_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

# AWS CLI 프로필 및 리전 확인
get_aws_account_info() {
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
    
    if [ -z "$account_id" ] || [ "$account_id" = "None" ]; then
        show_error "AWS 자격 증명을 확인할 수 없습니다."
        show_info "다음 명령어로 AWS CLI를 설정해주세요:"
        echo "  aws configure"
        exit 1
    fi
    
    echo "$account_id:$region:$user_arn"
}

# 생성 계획 표시 함수
show_creation_plan() {
    echo ""
    show_important "🚀 생성 계획:"
    echo ""
    
    # 기존 리소스 확인
    local existing_vpc=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    local existing_igw=""
    local existing_public_subnet=""
    local existing_private_subnet1=""
    local existing_private_subnet2=""
    local existing_ec2_sg=""
    local existing_ec2=""
    
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        # Internet Gateway 확인
        existing_igw=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$existing_vpc" "Name=attachment.state,Values=available" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
        
        # Public Subnet 확인
        existing_public_subnet=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        # Private Subnets 확인
        existing_private_subnet1=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-1" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        existing_private_subnet2=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-2" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        # EC2 Security Group 확인
        existing_ec2_sg=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$existing_vpc" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        # EC2 Instance 확인
        existing_ec2=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-RDS-Client" "Name=instance-state-name,Values=running,pending" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null)
    fi
    
    echo "📋 RDS 실습 인프라 구성:"
    
    # VPC 상태 표시
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        echo "🔄 VPC: CloudArchitect-Lab-VPC ($existing_vpc) - 기존 재사용"
    else
        echo "✨ VPC: CloudArchitect-Lab-VPC (10.0.0.0/16) - 새로 생성"
    fi
    
    # Internet Gateway 상태 표시
    if [ "$existing_igw" != "None" ] && [ -n "$existing_igw" ]; then
        echo "🔄 Internet Gateway: CloudArchitect-Lab-IGW ($existing_igw) - 기존 재사용"
    else
        echo "✨ Internet Gateway: CloudArchitect-Lab-IGW - 새로 생성"
    fi
    
    # Public Subnet 상태 표시
    if [ "$existing_public_subnet" != "None" ] && [ -n "$existing_public_subnet" ]; then
        echo "🔄 Public Subnet: CloudArchitect-Lab-Public-Subnet ($existing_public_subnet) - 기존 재사용"
    else
        echo "✨ Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.2.0/24, ap-northeast-2a) - 새로 생성"
    fi
    
    # Private Subnets 상태 표시
    if [ "$existing_private_subnet1" != "None" ] && [ -n "$existing_private_subnet1" ] && [ "$existing_private_subnet2" != "None" ] && [ -n "$existing_private_subnet2" ]; then
        echo "🔄 Private Subnets: CloudArchitect-Lab-Private-Subnet-1/2 - 기존 재사용"
    else
        echo "✨ Private Subnets: CloudArchitect-Lab-Private-Subnet-1/2 (RDS용, Multi-AZ) - 새로 생성"
    fi
    
    # EC2 Security Group 상태 표시
    if [ "$existing_ec2_sg" != "None" ] && [ -n "$existing_ec2_sg" ]; then
        echo "🔄 EC2 Security Group: CloudArchitect-Lab-EC2-SG ($existing_ec2_sg) - 기존 재사용"
    else
        echo "✨ EC2 Security Group: CloudArchitect-Lab-EC2-SG (SSH 허용) - 새로 생성"
    fi
    
    # EC2 Instance 상태 표시
    if [ "$existing_ec2" != "None" ] && [ -n "$existing_ec2" ]; then
        echo "🔄 EC2 Instance: CloudArchitect-Lab-RDS-Client ($existing_ec2) - 기존 재사용"
    else
        echo "✨ EC2 Instance: CloudArchitect-Lab-RDS-Client (t3.micro, MySQL 클라이언트) - 새로 생성"
    fi
    
    echo ""
    echo "🎯 핵심 학습 목표:"
    echo "• VPC 내 Private 서브넷에 RDS 배치"
    echo "• RDS MySQL 인스턴스 생성 및 관리"
    echo "• EC2에서 RDS로의 보안 연결 설정"
    echo "• DB 서브넷 그룹 및 보안 그룹 구성"
    echo ""
    
    echo "⚠️ 주의사항:"
    echo "• EC2 인스턴스로 인해 과금될 수 있음"
    echo "• 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "• 예상 소요 시간: 약 10분"
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab08 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab08 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab08 리소스 생성을 시작합니다..."
    echo ""
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab08 RDS 실습 인프라 구축이 완료되었습니다!"
    echo ""
    
    # 생성된 주요 리소스 정리
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Private Subnets: 2개 (RDS용, Multi-AZ)"
    echo "  ✅ EC2 Security Group: CloudArchitect-Lab-EC2-SG ($EC2_SG_ID)"
    echo "  ✅ EC2 Instance: CloudArchitect-Lab-RDS-Client ($EC2_INSTANCE_ID)"
    if [ -n "$EC2_PUBLIC_IP" ] && [ "$EC2_PUBLIC_IP" != "None" ]; then
        echo "  ✅ EC2 Public IP: $EC2_PUBLIC_IP"
    fi
    echo ""
    
    echo "🎯 다음 단계 (실습 가이드 참조):"
    echo "1. DB 서브넷 그룹 생성"
    echo "2. RDS 보안 그룹 생성"
    echo "3. MySQL 인스턴스 생성"
    echo "4. EC2 Instance Connect로 데이터베이스 연결 테스트"
    echo ""
    
    echo "🔗 EC2 인스턴스 접속 방법:"
    echo "• AWS 콘솔 → EC2 → Instances"
    echo "• CloudArchitect-Lab-RDS-Client 인스턴스 선택"
    echo "• 'Connect' 버튼 → 'EC2 Instance Connect' 탭"
    echo "• 'Connect' 클릭하여 브라우저에서 터미널 접속"
    echo ""
    
    echo "💡 참고사항:"
    echo "• VPC 및 EC2 사전 구축 환경만 생성되었습니다"
    echo "• RDS 관련 리소스는 실습 가이드를 보고 직접 생성하세요"
    echo "• EC2 인스턴스에는 MySQL 클라이언트가 자동 설치됩니다"
    echo "• EC2 Instance Connect를 통해 키 페어 없이 접속 가능합니다"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    echo "✅ Lab08 스크립트 실행 완료"
}

# VPC 생성 또는 재사용
create_vpc() {
    show_info "VPC 생성 중..."
    
    # 기존 CloudArchitect-Lab-VPC 확인
    local existing_vpc=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    if [ "$existing_vpc" != "None" ] && [ "$existing_vpc" != "" ]; then
        VPC_ID=$existing_vpc
        show_success "기존 VPC 재사용: CloudArchitect-Lab-VPC ($VPC_ID)"
        return 0
    fi
    
    # 새 VPC 생성
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/16 \
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'Vpc.VpcId' --output text)
    
    # DNS 설정 활성화
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames >/dev/null 2>&1
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support >/dev/null 2>&1
    
    show_success "VPC 생성 완료: CloudArchitect-Lab-VPC ($VPC_ID)"
}

# Internet Gateway 생성
create_internet_gateway() {
    show_info "Internet Gateway 생성 중..."
    
    # 기존 IGW 확인
    local existing_igw=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ "$existing_igw" != "None" ] && [ "$existing_igw" != "" ]; then
        IGW_ID=$existing_igw
        show_success "기존 Internet Gateway 재사용: CloudArchitect-Lab-IGW ($IGW_ID)"
        return 0
    fi
    
    # 새 IGW 생성
    IGW_ID=$(aws ec2 create-internet-gateway \
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'InternetGateway.InternetGatewayId' --output text)
    
    # VPC에 연결
    aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID >/dev/null 2>&1
    
    show_success "Internet Gateway 생성 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
}

# Public Subnet 생성
create_public_subnet() {
    show_info "Public Subnet 생성 중..."
    
    # 기존 Public Subnet 확인
    local existing_subnet=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
    if [ "$existing_subnet" != "None" ] && [ "$existing_subnet" != "" ]; then
        PUBLIC_SUBNET_ID=$existing_subnet
        show_success "기존 Public Subnet 재사용: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
        return 0
    fi
    
    # 새 Public Subnet 생성
    PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id $VPC_ID \
        --cidr-block 10.0.2.0/24 \
        --availability-zone ${REGION}a \
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'Subnet.SubnetId' --output text 2>/dev/null)
    
    if [ -z "$PUBLIC_SUBNET_ID" ] || [ "$PUBLIC_SUBNET_ID" = "None" ]; then
        show_error "Public Subnet 생성 실패"
        return 1
    fi
    
    # Public IP 자동 할당 활성화
    aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch >/dev/null 2>&1
    
    show_success "Public Subnet 생성 완료: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
}

# Route Table 생성
create_route_table() {
    show_info "Route Table 생성 중..."
    
    # 기존 Route Table 확인
    local existing_rt=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
    if [ "$existing_rt" != "None" ] && [ "$existing_rt" != "" ]; then
        PUBLIC_RT_ID=$existing_rt
        show_success "기존 Public Route Table 재사용: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
        return 0
    fi
    
    # Public Route Table 생성
    PUBLIC_RT_ID=$(aws ec2 create-route-table \
        --vpc-id $VPC_ID \
        --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'RouteTable.RouteTableId' --output text)
    
    # Internet Gateway로의 라우트 추가
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1
    
    # Public Subnet과 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1
    
    show_success "Public Route Table 생성 완료: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
}

# Private Subnets 생성 (RDS용)
create_private_subnets() {
    show_info "Private Subnets 생성 중..."
    
    # Private Subnet 1 (ap-northeast-2a)
    local existing_subnet1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-1" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
    if [ "$existing_subnet1" != "None" ] && [ "$existing_subnet1" != "" ]; then
        PRIVATE_SUBNET_1_ID=$existing_subnet1
    else
        PRIVATE_SUBNET_1_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.128.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Private-Subnet-1},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Private},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
    fi
    
    # Private Subnet 2 (ap-northeast-2c)
    local existing_subnet2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-2" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
    if [ "$existing_subnet2" != "None" ] && [ "$existing_subnet2" != "" ]; then
        PRIVATE_SUBNET_2_ID=$existing_subnet2
    else
        PRIVATE_SUBNET_2_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.129.0/24 \
            --availability-zone ap-northeast-2b \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Private-Subnet-2},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Private},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
    fi
    
    show_success "Private Subnets 생성 완료: $PRIVATE_SUBNET_1_ID $PRIVATE_SUBNET_2_ID"
}



# EC2 보안 그룹 생성 (RDS 접속용)
create_ec2_security_group() {
    show_info "EC2 보안 그룹 생성 중..."
    
    local sg_name="CloudArchitect-Lab-EC2-SG"
    
    # 기존 보안 그룹 확인
    local existing_sg=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$sg_name" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    if [ "$existing_sg" != "None" ] && [ "$existing_sg" != "" ]; then
        EC2_SG_ID=$existing_sg
        show_success "기존 EC2 보안 그룹 재사용: $sg_name ($EC2_SG_ID)"
        return 0
    fi
    
    # 새 보안 그룹 생성
    EC2_SG_ID=$(aws ec2 create-security-group \
        --group-name $sg_name \
        --description "CloudArchitect Lab08 EC2 Security Group for RDS Access" \
        --vpc-id $VPC_ID \
        --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-EC2-SG},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Security},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'GroupId' --output text)
    
    # SSH 접근 허용 (EC2 Instance Connect 포함)
    aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    show_success "EC2 보안 그룹 생성 완료: $sg_name ($EC2_SG_ID)"
}

# EC2 인스턴스 생성 (RDS 접속용)
create_ec2_instance() {
    show_info "EC2 인스턴스 생성 중..."
    
    # 기존 인스턴스 확인
    local existing_instance=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=CloudArchitect-Lab-RDS-Client" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null)
    if [ ! -z "$existing_instance" ] && [ "$existing_instance" != "None" ]; then
        EC2_INSTANCE_ID=$existing_instance
        show_success "기존 EC2 인스턴스 재사용: CloudArchitect-Lab-RDS-Client ($EC2_INSTANCE_ID)"
        return 0
    fi
    
    # 최신 Amazon Linux 2023 AMI 조회 (SSM Parameter 사용)
    local AMI_ID=$(aws ssm get-parameter \
        --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
        --query Parameter.Value \
        --output text)
    
    # User Data 스크립트 생성 (MySQL 클라이언트 및 EC2 Instance Connect 설정)
    local user_data=$(cat << 'EOF'
#!/bin/bash
# 시스템 업데이트
dnf update -y

# MySQL 클라이언트 설치
dnf install -y mysql

# EC2 Instance Connect 설정 (Amazon Linux 2023에는 기본 설치됨)
dnf install -y ec2-instance-connect
systemctl enable ec2-instance-connect
systemctl start ec2-instance-connect

# SSH 서비스 재시작
systemctl restart sshd

# 유용한 도구들 설치
dnf install -y htop curl wget telnet

# MySQL 클라이언트 설치 확인
mysql --version > /tmp/mysql-version.txt

# 설치 완료 로그
echo "$(date): EC2 Instance Connect 및 MySQL 클라이언트 설치 완료" >> /tmp/setup-complete.log
EOF
)
    
    # EC2 인스턴스 생성 (EC2 Instance Connect 호환성을 위해 IMDSv1/v2 모두 허용)
    EC2_INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --subnet-id $PUBLIC_SUBNET_ID \
        --security-group-ids $EC2_SG_ID \
        --associate-public-ip-address \
        --user-data "$user_data" \
        --metadata-options "HttpTokens=optional,HttpPutResponseHopLimit=3,HttpEndpoint=enabled,InstanceMetadataTags=enabled" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudArchitect-Lab-RDS-Client},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Compute},{Key=Purpose,Value=RDS-Client},{Key=CreatedBy,Value=setup-lab08-student.sh}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    # 인스턴스 시작 대기
    show_info "EC2 인스턴스 시작 대기 중..."
    aws ec2 wait instance-running --instance-ids $EC2_INSTANCE_ID
    
    # Public IP 확인
    EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    show_success "EC2 인스턴스 생성 완료: CloudArchitect-Lab-RDS-Client ($EC2_INSTANCE_ID)"
    

    
    # EC2 Instance Connect 준비 대기
    show_info "EC2 Instance Connect 준비 대기 중... (약 1분)"
    sleep 60
    
    show_success "✅ EC2 Instance Connect 준비 완료!"
}

# 생성 결과 검증
verify_creation_results() {
    show_info "생성 결과 검증 중..."
    
    # VPC 상태 확인
    local vpc_state=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].State' --output text 2>/dev/null)
    if [ "$vpc_state" = "available" ]; then
        show_success "VPC 상태 확인: $vpc_state"
    else
        show_warning "VPC 상태 이상: $vpc_state"
    fi
    
    # EC2 인스턴스 상태 확인
    local instance_state=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
    if [ "$instance_state" = "running" ]; then
        show_success "EC2 인스턴스 상태 확인: $instance_state"
    else
        show_warning "EC2 인스턴스 상태 이상: $instance_state"
    fi
}



# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    local aws_info=$(get_aws_account_info)
    local account_id=$(echo "$aws_info" | cut -d':' -f1)
    local region=$(echo "$aws_info" | cut -d':' -f2)
    local user_arn=$(echo "$aws_info" | cut -d':' -f3)
    
    # 헤더 표시
    echo "================================"
    echo "Lab08: Amazon RDS MySQL 데이터베이스 구축 - 관계형 데이터베이스 서비스"
    echo "================================"
    echo "목적: RDS 실습을 위한 VPC 네트워크 환경 및 EC2 클라이언트 생성"
    echo "예상 시간: 약 10분"
    echo "예상 비용: EC2 인스턴스로 인해 과금될 수 있음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo "사용자: $user_arn"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws ec2 describe-vpcs --max-items 1 >/dev/null 2>&1 && show_success "VPC 권한 확인 완료" || show_warning "VPC 권한 제한됨"
    aws rds describe-db-instances --max-items 1 >/dev/null 2>&1 && show_success "RDS 권한 확인 완료" || show_warning "RDS 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 7 "VPC 생성 중..."
    create_vpc
    echo ""
    
    show_progress 2 7 "Internet Gateway 생성 중..."
    create_internet_gateway
    echo ""
    
    show_progress 3 7 "Public Subnet 생성 중..."
    create_public_subnet
    echo ""
    
    show_progress 4 7 "Route Table 생성 중..."
    create_route_table
    echo ""
    
    show_progress 5 7 "Private Subnets 생성 중..."
    create_private_subnets
    echo ""
    
    show_progress 6 7 "EC2 보안 그룹 생성 중..."
    create_ec2_security_group
    echo ""
    
    show_progress 7 7 "EC2 인스턴스 생성 중..."
    create_ec2_instance
    echo ""
    
    # 완료 요약 표시
    show_completion_summary
}

# 스크립트 실행
main "$@"