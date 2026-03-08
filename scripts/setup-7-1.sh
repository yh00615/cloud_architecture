#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Lab10: CloudWatch 지표 모니터링 및 경보 설정 - 학생용 사전 환경 구축
# ================================
# 목적: CloudWatch 실습을 위한 EC2 인스턴스 및 기본 인프라 구성
# 예상 시간: 약 10분
# 예상 비용: EC2 인스턴스로 인해 과금될 수 있음
# ================================

# 로깅 설정 제거됨

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

# 변수 초기화
VPC_ID=""
IGW_ID=""
PUBLIC_SUBNET_ID=""
WEB_SG_ID=""
INSTANCE_ID=""
IAM_ROLE_NAME=""
INSTANCE_PROFILE_NAME=""

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
    
    echo "📋 EC2 인프라 구성 (CloudWatch 실습용):"
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        echo "🔄 VPC: CloudArchitect-Lab-VPC ($existing_vpc) - 기존 재사용"
    else
        echo "✨ VPC: CloudArchitect-Lab-VPC (10.0.0.0/16) - 새로 생성"
    fi
    echo "✨ Internet Gateway: CloudArchitect-Lab-IGW"
    echo "✨ Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.1.0/24, ap-northeast-2a)"
    echo "✨ Security Group: CloudArchitect-Lab-Web-SG (HTTP, HTTPS, SSH 허용)"
    echo "✨ EC2 Instance: CloudArchitect-Lab-MonitoringServer (t3.micro, Apache)"
    echo "✨ IAM Role: CloudArchitect-Lab-CloudWatchRole (CloudWatchAgentServerPolicy)"
    echo ""
    
    echo "🎯 학습 목표:"
    echo "• EC2 인스턴스 지표 모니터링 실습"
    echo "• CloudWatch 경보 설정 실습"
    echo "• SNS를 통한 알림 시스템 구성"
    echo "• 대시보드를 통한 통합 모니터링"
    echo "• 스트레스 테스트를 통한 경보 동작 확인"
    echo ""
    
    echo "📚 실습 내용:"
    echo "• 사전 스크립트: EC2 인스턴스 및 기본 인프라 자동 구성"
    echo "• 학생 실습: AWS 콘솔에서 CloudWatch 경보, 대시보드 직접 생성"
    echo "• 검증: 스트레스 테스트로 경보 동작 확인"
    echo ""
    
    echo "⚠️ 주의사항:"
    echo "• EC2 인스턴스로 인해 과금될 수 있음"
    echo "• 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "• 예상 소요 시간: 약 10분"
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab10 사전 환경을 구성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab10 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab10 사전 환경 구성을 시작합니다..."
    echo ""
}

# VPC 생성/재사용 함수
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
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
        --query 'Vpc.VpcId' --output text)
    
    # DNS 설정 활성화
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
    
    show_success "VPC 생성 완료: CloudArchitect-Lab-VPC ($VPC_ID)"
}

# Internet Gateway 생성/재사용 함수
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
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Network},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
        --query 'InternetGateway.InternetGatewayId' --output text)
    
    # VPC에 연결
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
    
    show_success "Internet Gateway 생성 및 연결 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
}

# Public Subnet 생성/재사용 함수
create_public_subnet() {
    show_info "Public Subnet 확인/생성 중..."
    
    # 기존 Public Subnet 확인
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.1.0/24" \
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
            --cidr-block 10.0.1.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2a},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        
        # Public IP 자동 할당 설정
        aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch
        
        show_success "Public Subnet 생성 완료: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    fi
    
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
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
            --query 'RouteTable.RouteTableId' --output text)
    fi
    
    # 인터넷 게이트웨이로의 라우트 추가
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1 || true
    
    # 서브넷을 라우트 테이블에 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    
    show_success "Route Table 설정 완료"
}

# IAM 역할 생성 함수
create_iam_role() {
    show_info "IAM 역할 확인/생성 중..."
    
    IAM_ROLE_NAME="CloudArchitect-Lab-CloudWatchRole"
    INSTANCE_PROFILE_NAME="CloudArchitect-Lab-CloudWatchProfile"
    
    # 기존 IAM 역할 확인
    existing_role=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query 'Role.RoleName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_role" != "None" ] && [ -n "$existing_role" ]; then
        show_success "기존 IAM 역할 재사용: $IAM_ROLE_NAME"
    else
        show_info "새 IAM 역할 생성 중..."
        
        # Trust Policy 생성
        cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
        
        # IAM 역할 생성
        aws iam create-role \
            --role-name "$IAM_ROLE_NAME" \
            --assume-role-policy-document file://trust-policy.json \
            --tags Key=Project,Value=CloudArchitect Key=Lab,Value=Lab10 Key=CreatedBy,Value=setup-lab10-student.sh \
            >/dev/null 2>&1
        
        # CloudWatchAgentServerPolicy 연결
        aws iam attach-role-policy \
            --role-name "$IAM_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
            >/dev/null 2>&1
        

        
        # 임시 파일 정리
        rm -f trust-policy.json
        
        show_success "IAM 역할 생성 완료: $IAM_ROLE_NAME"
    fi
    
    # 기존 Instance Profile 확인
    existing_profile=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_profile" != "None" ] && [ -n "$existing_profile" ]; then
        show_success "기존 Instance Profile 재사용: $INSTANCE_PROFILE_NAME"
    else
        show_info "새 Instance Profile 생성 중..."
        
        # Instance Profile 생성
        aws iam create-instance-profile \
            --instance-profile-name "$INSTANCE_PROFILE_NAME" \
            --tags Key=Project,Value=CloudArchitect Key=Lab,Value=Lab10 Key=CreatedBy,Value=setup-lab10-student.sh \
            >/dev/null 2>&1
        
        # IAM 역할을 Instance Profile에 추가
        aws iam add-role-to-instance-profile \
            --instance-profile-name "$INSTANCE_PROFILE_NAME" \
            --role-name "$IAM_ROLE_NAME" \
            >/dev/null 2>&1
        
        show_success "Instance Profile 생성 완료: $INSTANCE_PROFILE_NAME"
    fi
    
    # Instance Profile이 준비될 때까지 잠시 대기
    show_info "IAM 역할 준비 대기 중..."
    sleep 10
}

# Security Group 생성/재사용 함수
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
            --description "CloudArchitect Lab10 - Web Server Security Group" \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=CloudArchitect-Lab-Web-SG},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Security},{Key=Type,Value=Web},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
            --query 'GroupId' --output text)
        
        # 인바운드 규칙 추가
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null 2>&1
        aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
                
        show_success "Web Security Group 생성 완료: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    fi
}

# EC2 인스턴스 생성 함수
create_ec2_instance() {
    show_info "EC2 인스턴스 확인/생성 중..."
    
    # 기존 인스턴스 확인
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-MonitoringServer" \
            "Name=instance-state-name,Values=running,pending" \
            "Name=subnet-id,Values=$PUBLIC_SUBNET_ID" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null)
    
    if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
        show_success "기존 EC2 인스턴스 재사용: CloudArchitect-Lab-MonitoringServer ($INSTANCE_ID)"
        return 0
    fi
    
    show_info "새 EC2 인스턴스 생성 중..."
    
    # User Data 스크립트 생성 (Apache + CloudWatch Agent + stress 도구)
    USER_DATA=$(cat << 'EOF'
#!/bin/bash
dnf update -y
dnf install -y httpd stress

# Apache 시작
systemctl start httpd
systemctl enable httpd

# CloudWatch Agent 설치
dnf install -y amazon-cloudwatch-agent

# EC2 Instance Connect 설치 및 설정
dnf install -y ec2-instance-connect
systemctl enable ec2-instance-connect
systemctl start ec2-instance-connect

# SSH 서비스 재시작
systemctl restart sshd

# 메타데이터 정보 가져오기 (IMDSv2 방식)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s 2>/dev/null || echo "")
if [ -n "$TOKEN" ]; then
    INSTANCE_ID_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "N/A")
    AZ_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "N/A")
    PUBLIC_IP_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
    PRIVATE_IP_META=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "N/A")
else
    INSTANCE_ID_META="N/A"
    AZ_META="N/A"
    PUBLIC_IP_META="N/A"
    PRIVATE_IP_META="N/A"
fi

# CloudWatch 실습용 웹 페이지 생성
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html>
<head>
    <title>CloudArchitect Lab10 - CloudWatch 실습</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success { color: #27ae60; font-weight: bold; }
        .meta-value { color: #e74c3c; font-family: monospace; font-weight: bold; }
        .lab-guide { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #ffc107; }
        .stress-test { background: #f8d7da; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #dc3545; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 CloudArchitect Lab10 - CloudWatch 실습</h1>
        <div class="info">
            <h3>EC2 인스턴스 정보:</h3>
            <p><strong>인스턴스 ID:</strong> <span class="meta-value">$INSTANCE_ID_META</span></p>
            <p><strong>가용 영역:</strong> <span class="meta-value">$AZ_META</span></p>
            <p><strong>퍼블릭 IP:</strong> <span class="meta-value">$PUBLIC_IP_META</span></p>
            <p><strong>프라이빗 IP:</strong> <span class="meta-value">$PRIVATE_IP_META</span></p>
        </div>
        <div class="success">
            ✅ 사전 환경 구성이 완료되었습니다!
        </div>
        <div class="lab-guide">
            <h3>📚 실습 가이드:</h3>
            <p><strong>1단계:</strong> AWS 콘솔에서 CloudWatch 서비스로 이동</p>
            <p><strong>2단계:</strong> EC2 인스턴스 지표 확인 (CPU, 네트워크 등)</p>
            <p><strong>3단계:</strong> CloudWatch 경보 생성 (CPU 사용률 60% 임계값)</p>
            <p><strong>4단계:</strong> SNS 토픽 생성 및 이메일 구독 설정</p>
            <p><strong>5단계:</strong> CloudWatch 대시보드 생성</p>
            <p><strong>6단계:</strong> 스트레스 테스트로 경보 동작 확인</p>
        </div>
        <div class="stress-test">
            <h3>🔥 스트레스 테스트 명령어:</h3>
            <p><strong>CPU 부하 생성:</strong> <code>stress --cpu 2 --timeout 300s</code></p>
            <p><strong>메모리 부하 생성:</strong> <code>stress --vm 1 --vm-bytes 512M --timeout 300s</code></p>
            <p>EC2 Instance Connect로 접속하여 위 명령어를 실행하면 CloudWatch 경보를 테스트할 수 있습니다.</p>
        </div>
        <p>이 서버는 CloudWatch 모니터링 실습을 위해 구성되었습니다.</p>
        <p><small>생성 시간: $(date)</small></p>
    </div>
</body>
</html>
HTML

# 상태 확인 페이지 생성
cat > /var/www/html/health.html << HTML
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
    <h1>OK</h1>
    <p>CloudWatch Lab Server is running</p>
    <p>Timestamp: $(date)</p>
</body>
</html>
HTML
EOF
)
    
    # 최신 Amazon Linux 2023 AMI ID 조회 (SSM Parameter 사용)
    AMI_ID=$(aws ssm get-parameter \
        --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
        --query Parameter.Value \
        --output text)
    
    # EC2 인스턴스 생성 (키페어 없이, IAM Instance Profile 포함)
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --subnet-id $PUBLIC_SUBNET_ID \
        --security-group-ids $WEB_SG_ID \
        --iam-instance-profile Name=$INSTANCE_PROFILE_NAME \
        --user-data "$USER_DATA" \
        --metadata-options "HttpTokens=optional,HttpPutResponseHopLimit=2,HttpEndpoint=enabled" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudArchitect-Lab-MonitoringServer},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Lab10},{Key=Component,Value=Compute},{Key=Type,Value=MonitoringServer},{Key=CreatedBy,Value=setup-lab10-student.sh}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    show_success "EC2 인스턴스 생성 완료: CloudArchitect-Lab-MonitoringServer ($INSTANCE_ID)"
    
    # 인스턴스 시작 대기 (running 상태까지)
    show_info "EC2 인스턴스 시작 대기 중... (t3.micro, running 상태까지)"
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    
    show_success "EC2 인스턴스 시작 완료"
}

# 완료 요약 표시 함수
show_completion_summary() {
    # 인스턴스 퍼블릭 IP 조회
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null)
    
    echo ""
    show_success "🎉 Lab10 CloudWatch 실습 사전 환경 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Security Group: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    echo "  ✅ IAM Role: CloudArchitect-Lab-CloudWatchRole (CloudWatchAgentServerPolicy)"
    echo "  ✅ EC2 Instance: CloudArchitect-Lab-MonitoringServer ($INSTANCE_ID)"
    echo ""
    
    echo "🌐 웹 서버 접속 정보:"
    echo "  • 웹 브라우저: http://$PUBLIC_IP"
    echo "  • 상태 확인: http://$PUBLIC_IP/health.html"
    echo "  • 인스턴스 타입: t3.micro"
    echo "  • 운영체제: Amazon Linux 2023"
    echo "  • 웹 서버: Apache"
    echo "  • 접속 방법: EC2 Instance Connect (키페어 불필요)"
    echo ""
    
    echo "📚 다음 단계 - CloudWatch 실습:"
    echo "  1. AWS 콘솔 → CloudWatch → Metrics에서 EC2 지표 확인"
    echo "  2. CloudWatch → Alarms에서 CPU 사용률 경보 생성 (60% 임계값)"
    echo "  3. SNS → Topics에서 알림 토픽 생성 및 이메일 구독"
    echo "  4. CloudWatch → Dashboards에서 모니터링 대시보드 생성"
    echo "  5. EC2 Instance Connect로 접속하여 stress 명령어로 경보 테스트"
    echo ""
    
    echo "🔥 스트레스 테스트 명령어:"
    echo "  • CPU 부하: stress --cpu 2 --timeout 300s"
    echo "  • 메모리 부하: stress --vm 1 --vm-bytes 512M --timeout 300s"
    echo ""
    
    echo "💰 비용 절약: 실습 완료 후 cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    show_success "✅ Lab10 사전 환경 구성 완료"
}

# 메인 실행 함수
main() {
    # 헤더 표시
    echo "================================"
    echo "Lab10: CloudWatch 지표 모니터링 및 경보 설정 - 학생용 사전 환경 구축"
    echo "================================"
    echo "목적: CloudWatch 실습을 위한 EC2 인스턴스 및 기본 인프라 구성"
    echo "예상 시간: 약 10분"
    echo "예상 비용: EC2 인스턴스로 인해 과금될 수 있음"
    echo "================================"
    
    # AWS 계정 정보 확인
    aws_info=$(get_aws_account_info)
    account_id=$(echo "$aws_info" | cut -d':' -f1)
    region=$(echo "$aws_info" | cut -d':' -f2)
    user_arn=$(echo "$aws_info" | cut -d':' -f3)
    
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws ec2 describe-vpcs --max-items 1 >/dev/null 2>&1 && show_success "EC2 권한 확인 완료" || show_warning "EC2 권한 제한됨"
    aws iam list-roles --max-items 1 >/dev/null 2>&1 && show_success "IAM 권한 확인 완료" || show_warning "IAM 권한 제한됨"
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 1단계: VPC 생성
    show_progress 1 6 "VPC 생성 중..."
    create_vpc
    echo ""
    
    # 2단계: Internet Gateway 생성
    show_progress 2 6 "Internet Gateway 생성 중..."
    create_internet_gateway
    echo ""
    
    # 3단계: Public Subnet 생성
    show_progress 3 6 "Public Subnet 생성 중..."
    create_public_subnet
    echo ""
    
    # 4단계: IAM 역할 생성
    show_progress 4 6 "IAM 역할 생성 중..."
    create_iam_role
    echo ""
    
    # 5단계: Security Group 생성
    show_progress 5 6 "Security Group 생성 중..."
    create_security_group
    echo ""
    
    # 6단계: EC2 인스턴스 생성
    show_progress 6 6 "EC2 인스턴스 생성 중..."
    create_ec2_instance
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"