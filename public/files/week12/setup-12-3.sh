#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Week 12-3: AWS Backup 서비스 - 자동화된 백업 및 복원
# ================================
# 목적: AWS Backup 실습을 위한 EC2 인스턴스 및 IAM 역할 생성
# 예상 시간: 약 8분
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
    local region=$(aws configure get region 2>/dev/null || echo "")
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
    local existing_ec2_sg=""
    local existing_ec2=""
    local existing_backup_role=""
    
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
        
        # EC2 Security Group 확인
        existing_ec2_sg=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$existing_vpc" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        # EC2 Instance 확인
        existing_ec2=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-TestInstance" "Name=instance-state-name,Values=running,pending" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null)
    fi
    
    # IAM Backup Role 확인
    existing_backup_role=$(aws iam get-role --role-name CloudArchitect-Lab-BackupRole --query 'Role.RoleName' --output text 2>/dev/null)
    
    echo "📋 AWS Backup 실습 인프라 구성:"
    
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
        echo "✨ Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.2.0/24, ${REGION}a) - 새로 생성"
    fi
    
    # EC2 Security Group 상태 표시
    if [ "$existing_ec2_sg" != "None" ] && [ -n "$existing_ec2_sg" ]; then
        echo "🔄 EC2 Security Group: CloudArchitect-Lab-EC2-SG ($existing_ec2_sg) - 기존 재사용"
    else
        echo "✨ EC2 Security Group: CloudArchitect-Lab-EC2-SG (SSH 허용) - 새로 생성"
    fi
    
    # EC2 Instance 상태 표시
    if [ "$existing_ec2" != "None" ] && [ -n "$existing_ec2" ]; then
        echo "🔄 EC2 Instance: CloudArchitect-Lab-TestInstance ($existing_ec2) - 기존 재사용"
    else
        echo "✨ EC2 Instance: CloudArchitect-Lab-TestInstance (t3.micro, 백업 대상) - 새로 생성"
        echo "  • 백업용 태그: Project=CloudArchitect, Week=Week12"
        echo "  • 웹서버 설치 및 샘플 데이터 생성"
    fi
    
    # IAM Backup Role 상태 표시
    if [ "$existing_backup_role" != "None" ] && [ -n "$existing_backup_role" ]; then
        echo "🔄 IAM Backup Role: CloudArchitect-Lab-BackupRole - 기존 재사용"
    else
        echo "✨ IAM Backup Role: CloudArchitect-Lab-BackupRole - 새로 생성"
        echo "  • AWS Backup 서비스 역할"
        echo "  • 백업 및 복원 권한 포함"
    fi
    
    echo ""
    echo "🎯 핵심 학습 목표:"
    echo "• AWS Backup 볼트 생성 및 관리"
    echo "• 백업 계획 및 정책 설정"
    echo "• 태그 기반 리소스 선택"
    echo "• 백업 작업 모니터링 및 복원"
    echo ""
    
    echo "⚠️ 주의사항:"
    echo "• EC2 인스턴스로 인해 과금될 수 있음"
    echo "• 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "• 예상 소요 시간: 약 8분"
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Week 12-3 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Week 12-3 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Week 12-3 리소스 생성을 시작합니다..."
    echo ""
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Week 12-3 사전 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    echo "  ✅ Security Group: CloudArchitect-Lab-Web-SG ($EC2_SG_ID)"
    echo "  ✅ EC2 인스턴스: CloudArchitect-Lab-TestInstance ($EC2_INSTANCE_ID)"
    echo "  ✅ IAM 역할: CloudArchitect-Lab-BackupRole"
    if [ -n "$EC2_PUBLIC_IP" ] && [ "$EC2_PUBLIC_IP" != "None" ]; then
        echo "  ✅ 웹 페이지: http://$EC2_PUBLIC_IP"
        echo ""
        show_warning "⏳ 중요: 웹서버 초기화 대기 필요"
        echo "  • 인스턴스는 실행 중이지만, 웹서버 설치 및 시작에 2-3분 추가 소요"
        echo "  • 웹 페이지 접속이 안 되면 2-3분 후 다시 시도하세요"
        echo "  • User Data 스크립트가 백그라운드에서 httpd를 설치하고 있습니다"
    fi
    echo ""
    
    echo "🔧 다음 단계:"
    echo "1. 실습 가이드를 참고하여 AWS Backup Vault를 생성하세요"
    echo "   • Vault 이름: CloudArchitect-Lab-BackupVault"
    echo "2. Backup Plan을 생성하고 백업 정책을 설정하세요"
    echo "   • Plan 이름: CloudArchitect-Lab-BackupPlan"
    echo "   • 백업 빈도: Daily (매일)"
    echo "   • 보관 기간: 7일"
    echo "3. 태그 기반으로 EC2 인스턴스를 백업 대상으로 선택하세요"
    echo "   • 리소스 할당: Tag 기반 선택"
    echo "   • 태그 조건: Lab = Week12"
    echo "4. 백업 작업을 실행하고 모니터링해보세요"
    echo "   • On-demand 백업으로 즉시 백업 테스트 가능"
    echo "   • ⏳ 백업 완료까지 약 5-10분 소요됩니다"
    echo ""
    
    echo "💰 비용 절약: 실습 완료 후 cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Week 12-3 스크립트 실행 완료"
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
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-12-3.sh}]' \
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
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-12-3.sh}]' \
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
        --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-12-3.sh}]' \
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
        --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-12-3.sh}]' \
        --query 'RouteTable.RouteTableId' --output text)
    
    # Internet Gateway로의 라우트 추가
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1
    
    # Public Subnet과 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1
    
    show_success "Public Route Table 생성 완료: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
}

# EC2 보안 그룹 생성
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
        --description "CloudArchitect Week 12-3 EC2 Security Group for Backup Testing" \
        --vpc-id $VPC_ID \
        --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-EC2-SG},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Security},{Key=CreatedBy,Value=setup-12-3.sh}]' \
        --query 'GroupId' --output text)
    
    # SSH 접근 허용 (EC2 Instance Connect 포함)
    aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    # HTTP 접근 허용 (웹서버 테스트용)
    aws ec2 authorize-security-group-ingress --group-id $EC2_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    show_success "EC2 보안 그룹 생성 완료: $sg_name ($EC2_SG_ID)"
}

# IAM Backup Role 생성
create_backup_role() {
    show_info "IAM Backup Role 생성 중..."
    
    local role_name="CloudArchitect-Lab-BackupRole"
    
    # 기존 역할 확인
    local existing_role=$(aws iam get-role --role-name $role_name --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$existing_role" != "None" ] && [ "$existing_role" != "" ]; then
        BACKUP_ROLE_ARN=$(aws iam get-role --role-name $role_name --query 'Role.Arn' --output text)
        show_success "기존 IAM Backup Role 재사용: $role_name"
        return 0
    fi
    
    # Trust Policy 생성
    local trust_policy='{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "backup.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
    
    # IAM Role 생성
    BACKUP_ROLE_ARN=$(aws iam create-role \
        --role-name $role_name \
        --assume-role-policy-document "$trust_policy" \
        --description "CloudArchitect Week 12-3 AWS Backup Service Role" \
        --tags Key=Name,Value=CloudArchitect-Lab-BackupRole Key=Project,Value=CloudArchitect Key=Week,Value=Week12 Key=Environment,Value=Lab Key=Component,Value=IAM Key=CreatedBy,Value=setup-12-3.sh \
        --query 'Role.Arn' --output text)
    
    # AWS 관리형 정책 연결
    aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup >/dev/null 2>&1
    aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores >/dev/null 2>&1
    
    show_success "IAM Backup Role 생성 완료: $role_name"
}

# EC2 인스턴스 생성 (백업 대상)
create_ec2_instance() {
    show_info "EC2 인스턴스 생성 중..."
    
    # 기존 인스턴스 확인
    local existing_instance=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=CloudArchitect-Lab-TestInstance" "Name=instance-state-name,Values=running,pending" --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null)
    if [ ! -z "$existing_instance" ] && [ "$existing_instance" != "None" ]; then
        EC2_INSTANCE_ID=$existing_instance
        show_success "기존 EC2 인스턴스 재사용: CloudArchitect-Lab-TestInstance ($EC2_INSTANCE_ID)"
        return 0
    fi
    
    # 최신 Amazon Linux 2023 AMI 조회 (SSM Parameter 사용)
    local AMI_ID=$(aws ssm get-parameter \
        --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
        --query Parameter.Value \
        --output text)
    
    # User Data 스크립트 (웹서버 설치 및 샘플 데이터 생성)
    local user_data='#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# 샘플 웹 페이지 생성
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>CloudArchitect Week 12-3 - Backup Test Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #232f3e; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .info { background-color: #f0f8ff; padding: 15px; border-left: 4px solid #007cba; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AWS Backup 실습용 테스트 인스턴스</h1>
        <p>CloudArchitect Week 12-3 - AWS Backup Service</p>
    </div>
    <div class="content">
        <div class="info">
            <h3>인스턴스 정보</h3>
            <p><strong>인스턴스 이름:</strong> CloudArchitect-Lab-TestInstance</p>
            <p><strong>목적:</strong> AWS Backup 서비스 실습</p>
            <p><strong>생성 시간:</strong> $(date)</p>
            <p><strong>백업 태그:</strong> Project=CloudArchitect, Week=Week12</p>
        </div>
        <h3>백업 실습 내용</h3>
        <ul>
            <li>AWS Backup 볼트 생성</li>
            <li>백업 계획 및 정책 설정</li>
            <li>태그 기반 리소스 선택</li>
            <li>백업 작업 모니터링</li>
            <li>백업 복원 실습</li>
        </ul>
    </div>
</body>
</html>
EOF

# 샘플 데이터 파일 생성
mkdir -p /home/ec2-user/backup-test-data
cat > /home/ec2-user/backup-test-data/sample-data.txt << EOF
CloudArchitect Week 12-3 - AWS Backup 실습 데이터
생성 시간: $(date)
이 파일은 백업 및 복원 테스트를 위한 샘플 데이터입니다.
EOF

chown -R ec2-user:ec2-user /home/ec2-user/backup-test-data
'
    
    # EC2 인스턴스 생성 (백업용 태그 포함)
    EC2_INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --subnet-id $PUBLIC_SUBNET_ID \
        --security-group-ids $EC2_SG_ID \
        --associate-public-ip-address \
        --user-data "$user_data" \
        --metadata-options "HttpTokens=optional,HttpPutResponseHopLimit=2,HttpEndpoint=enabled" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudArchitect-Lab-TestInstance},{Key=Project,Value=CloudArchitect},{Key=Week,Value=Week12},{Key=Environment,Value=Lab},{Key=Component,Value=Compute},{Key=Purpose,Value=Backup-Test},{Key=CreatedBy,Value=setup-12-3.sh}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    # 인스턴스 시작 대기
    show_info "EC2 인스턴스 시작 대기 중..."
    aws ec2 wait instance-running --instance-ids $EC2_INSTANCE_ID
    
    # Public IP 확인
    EC2_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    show_success "EC2 인스턴스 생성 완료: CloudArchitect-Lab-TestInstance ($EC2_INSTANCE_ID)"
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
    
    # IAM Role 상태 확인
    local role_exists=$(aws iam get-role --role-name CloudArchitect-Lab-BackupRole --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$role_exists" = "CloudArchitect-Lab-BackupRole" ]; then
        show_success "IAM Backup Role 상태 확인: 생성됨"
    else
        show_warning "IAM Backup Role 상태 이상"
    fi
}

# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    local aws_info=$(get_aws_account_info)
    local account_id=$(echo "$aws_info" | cut -d':' -f1)
    local region=$(echo "$aws_info" | cut -d':' -f2)
    local user_arn=$(echo "$aws_info" | cut -d':' -f3)
    
    # REGION 변수를 전역으로 export
    export REGION="$region"
    
    # 헤더 표시
    echo "================================"
    echo "Week 12-3: AWS Backup 서비스 - 자동화된 백업 및 복원"
    echo "================================"
    echo "목적: AWS Backup 실습을 위한 EC2 인스턴스 및 IAM 역할 생성"
    echo "예상 시간: 약 8분"
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
    aws backup list-backup-vaults --max-results 1 >/dev/null 2>&1 && show_success "AWS Backup 권한 확인 완료" || show_warning "AWS Backup 권한 제한됨"
    aws iam list-roles --max-items 1 >/dev/null 2>&1 && show_success "IAM 권한 확인 완료" || show_warning "IAM 권한 제한됨"
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
    
    show_progress 5 7 "EC2 보안 그룹 생성 중..."
    create_ec2_security_group
    echo ""
    
    show_progress 6 7 "IAM Backup Role 생성 중..."
    create_backup_role
    echo ""
    
    show_progress 7 7 "EC2 인스턴스 생성 중..."
    create_ec2_instance
    echo ""
    
    # 생성 결과 검증
    verify_creation_results
    echo ""
    
    # 완료 요약 표시
    show_completion_summary
}

# 스크립트 실행
main "$@"