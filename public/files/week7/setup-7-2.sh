#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ===========================================
# Week7-2: CloudWatch Logs 실습 - 사전 환경 구축
# 목적: CloudWatch Logs 실습을 위한 EC2 + Nginx + CloudWatch Agent 환경 구축
# 예상 시간: 약 15분
# 예상 비용: EC2 인스턴스 및 CloudWatch Logs로 인해 과금될 수 있음
# 
# 구성 요소:
# - VPC (10.0.0.0/16) - 기본 네트워크 환경
# - Public Subnet (10.0.1.0/24, ap-northeast-2a) - EC2 인스턴스용
# - Internet Gateway - 인터넷 연결
# - Security Group - HTTP(80), SSH(22) 허용
# - IAM Role - CloudWatch Agent 권한
# - EC2 Instance (t3.micro) - Nginx 웹서버
# - CloudWatch Agent - 로그 수집 에이전트
# - CloudWatch Logs Groups - /aws/ec2/nginx/access, /aws/ec2/nginx/error
# ===========================================

# 로깅 설정 제거됨

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 전역 변수
VPC_NAME="CloudArchitect-Lab-VPC"
SUBNET_NAME="CloudArchitect-Lab-Public-Subnet"
SG_NAME="CloudArchitect-Lab-Web-SG"
ROLE_NAME="CloudArchitect-Lab-CloudWatchAgent-Role"
INSTANCE_PROFILE_NAME="CloudArchitect-Lab-CloudWatchAgent-InstanceProfile"
INSTANCE_NAME="CloudArchitect-Lab-LogServer"

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
    echo "🚀 생성 계획:"
    echo ""
    
    echo "  📋 네트워크 인프라 구성:"
    echo "    🌐 VPC: CloudArchitect-Lab-VPC (10.0.0.0/16)"
    echo "    🌍 Internet Gateway: CloudArchitect-Lab-IGW"
    echo ""
    
    echo "  🏢 서브넷 구성:"
    echo "    🔓 Public Subnet: CloudArchitect-Lab-Public-Subnet (10.0.1.0/24, ap-northeast-2a)"
    echo ""
    
    echo "  🛣️ 라우팅 및 연결:"
    echo "    🗺️ Public Route Table: CloudArchitect-Lab-Public-RT (0.0.0.0/0 → IGW)"
    echo ""
    
    echo "  🛡️ 보안 구성:"
    echo "    🌐 Web Security Group: CloudArchitect-Lab-Web-SG"
    echo "      • HTTP (80), SSH (22) 허용"
    echo ""
    
    echo "  🖥️ EC2 인스턴스 구성:"
    echo "    💻 인스턴스: CloudArchitect-Lab-LogServer (t3.micro)"
    echo "    🔐 IAM 역할: CloudArchitect-Lab-CloudWatchAgent-Role"
    echo "    📋 정책: CloudWatchAgentServerPolicy (AWS 관리형)"
    echo "    🌐 웹서버: Nginx 자동 설치 및 구성"
    echo ""
    
    echo "  📊 CloudWatch Agent 구성:"
    echo "    📄 로그 그룹: /aws/ec2/nginx/access, /aws/ec2/nginx/error"
    echo "    🔄 로그 스트림: 인스턴스 ID 기반 자동 생성"
    echo "    ⚙️ 설정 파일: /opt/aws/amazon-cloudwatch-agent/etc/"
    echo "    🚀 자동 시작: CloudWatch Agent 서비스 활성화"
    echo ""
    
    echo "  🎯 핵심 학습 목표:"
    echo "    • EC2 인스턴스에 CloudWatch Agent 설치 및 구성"
    echo "    • 실제 웹서버 로그의 실시간 수집"
    echo "    • CloudWatch Logs 그룹 및 스트림 개념 이해"
    echo "    • 로그 인사이트를 통한 로그 분석 및 쿼리"
    echo ""
    
    echo "  🤖 자동 트래픽 생성 시스템:"
    echo "    • 1분 후: 첫 번째 자동 트래픽 생성"
    echo "    • 이후 2분마다: 지속적 트래픽 자동 생성"
    echo "    • 로그 패턴: 정상 접속(200) + 404 에러 혼합"
    echo "    • 수동 트래픽: /home/ec2-user/generate-traffic.sh 스크립트 제공"
    echo ""
    
    echo "  📚 실습 내용:"
    echo "    • 사전 스크립트: EC2 + Nginx + CloudWatch Agent + 자동 트래픽 생성"
    echo "    • 실습: CloudWatch Logs 콘솔에서 자동 생성된 로그 분석"
    echo "    • 검증: 실시간 로그 수집 및 Live tail 모니터링"
    echo ""
    
    echo "  ⚠️ 주의사항:"
    echo "    • EC2 인스턴스 및 CloudWatch Logs로 인해 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 15분"
    echo ""
    echo "================================"
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Week7-2 사전 환경을 구성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Week7-2 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Week7-2 사전 환경 구성을 시작합니다..."
    echo ""
}

# VPC 및 네트워크 리소스 확인/생성
setup_network_resources() {
    show_info "VPC 및 네트워크 리소스 확인 중..."
    
    # VPC 확인/생성
    VPC_ID=$(aws ec2 describe-vpcs \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
            "Name=cidr-block-association.cidr-block,Values=10.0.0.0/16" \
            "Name=state,Values=available" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        show_success "기존 VPC 재사용: CloudArchitect-Lab-VPC ($VPC_ID)"
    else
        show_info "새 VPC 생성 중..."
        VPC_ID=$(aws ec2 create-vpc \
            --cidr-block 10.0.0.0/16 \
            --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]' \
            --query 'Vpc.VpcId' --output text)
        
        aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
        aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
        
        show_success "VPC 생성 완료: CloudArchitect-Lab-VPC ($VPC_ID)"
    fi
    
    # Internet Gateway 확인/생성
    IGW_ID=$(aws ec2 describe-internet-gateways \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-IGW" \
            "Name=attachment.vpc-id,Values=$VPC_ID" \
            "Name=attachment.state,Values=available" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text 2>/dev/null)
    
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        show_success "기존 Internet Gateway 재사용: CloudArchitect-Lab-IGW ($IGW_ID)"
    else
        show_info "새 Internet Gateway 생성 중..."
        IGW_ID=$(aws ec2 create-internet-gateway \
            --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]' \
            --query 'InternetGateway.InternetGatewayId' --output text)
        
        aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
        show_success "Internet Gateway 생성 및 연결 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
    fi
}

# 서브넷 및 보안그룹 생성 함수
create_subnet_and_security_group() {
    # Public Subnet 확인/생성
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=$SUBNET_NAME" \
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
            --vpc-id "$VPC_ID" \
            --cidr-block 10.0.1.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$SUBNET_NAME},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]" \
            --query 'Subnet.SubnetId' --output text)
        
        aws ec2 modify-subnet-attribute --subnet-id "$PUBLIC_SUBNET_ID" --map-public-ip-on-launch
        show_success "Public Subnet 생성 완료: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    fi
    
    # Route Table 설정
    RT_ID=$(aws ec2 describe-route-tables \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null)
    
    if [ "$RT_ID" != "None" ] && [ -n "$RT_ID" ]; then
        show_success "기존 Route Table 재사용: CloudArchitect-Lab-Public-RT ($RT_ID)"
    else
        show_info "새 Route Table 생성 중..."
        RT_ID=$(aws ec2 create-route-table \
            --vpc-id "$VPC_ID" \
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]' \
            --query 'RouteTable.RouteTableId' --output text)
        
        aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null 2>&1
        aws ec2 associate-route-table --subnet-id "$PUBLIC_SUBNET_ID" --route-table-id "$RT_ID" >/dev/null 2>&1
        show_success "Route Table 생성 및 연결 완료: CloudArchitect-Lab-Public-RT ($RT_ID)"
    fi
    
    # Security Group 확인/생성
    SG_ID=$(aws ec2 describe-security-groups \
        --filters \
            "Name=tag:Name,Values=$SG_NAME" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
        show_success "기존 Security Group 재사용: $SG_ID"
    else
        show_info "새 Security Group 생성 중..."
        SG_ID=$(aws ec2 create-security-group \
            --group-name "$SG_NAME" \
            --description "CloudArchitect Week7-2 Web Security Group" \
            --vpc-id "$VPC_ID" \
            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$SG_NAME},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]" \
            --query 'GroupId' --output text)
        
        # HTTP 허용
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 80 \
            --cidr 0.0.0.0/0 >/dev/null 2>&1
        
        # SSH 허용
        aws ec2 authorize-security-group-ingress \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 >/dev/null 2>&1
        
        show_success "Security Group 생성 완료: $SG_ID"
    fi
}

# IAM 역할 생성 함수
create_iam_role() {
    
    # 기존 IAM 역할 확인
    existing_role=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.RoleName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_role" != "None" ] && [ -n "$existing_role" ]; then
        show_success "기존 IAM 역할 재사용: $ROLE_NAME"
    else
        show_info "새 IAM 역할 생성 중..."
        
        # Trust Policy 생성
        cat > trust-policy.json << 'EOF'
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
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://trust-policy.json \
            --tags Key=Project,Value=CloudArchitect Key=Lab,Value=Week7-2 \
            >/dev/null 2>&1
        
        # CloudWatchAgentServerPolicy 연결
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
            >/dev/null 2>&1
        
        rm -f trust-policy.json
        show_success "IAM 역할 생성 완료: $ROLE_NAME"
    fi
    
    # Instance Profile 생성
    existing_profile=$(aws iam get-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_profile" != "None" ] && [ -n "$existing_profile" ]; then
        show_success "기존 Instance Profile 재사용: $INSTANCE_PROFILE_NAME"
    else
        show_info "새 Instance Profile 생성 중..."
        
        aws iam create-instance-profile \
            --instance-profile-name "$INSTANCE_PROFILE_NAME" \
            >/dev/null 2>&1
        
        aws iam add-role-to-instance-profile \
            --instance-profile-name "$INSTANCE_PROFILE_NAME" \
            --role-name "$ROLE_NAME" \
            >/dev/null 2>&1
        
        show_success "Instance Profile 생성 완료: $INSTANCE_PROFILE_NAME"
    fi
    
    show_info "IAM 역할 준비 대기 중..."
    sleep 10
}

# EC2 인스턴스 생성 함수
create_ec2_instance() {
    # 기존 인스턴스 확인
    existing_instance=$(aws ec2 describe-instances \
        --filters \
            "Name=tag:Name,Values=$INSTANCE_NAME" \
            "Name=instance-state-name,Values=running,pending" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null)
    
    if [ "$existing_instance" != "None" ] && [ -n "$existing_instance" ]; then
        show_success "기존 EC2 인스턴스 재사용: $existing_instance"
        INSTANCE_ID="$existing_instance"
        
        # Public IP 조회
        PUBLIC_IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    else
        show_info "새 EC2 인스턴스 생성 중..."
        
        # 최신 Amazon Linux 2023 AMI 조회
        # 최신 Amazon Linux 2023 AMI 조회 (SSM Parameter 사용)
        AMI_ID=$(aws ssm get-parameter \
            --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
            --query Parameter.Value \
            --output text)
        
        # User Data 스크립트 생성
        cat > user-data.sh << 'EOF'
#!/bin/bash
yum update -y

# Nginx 설치
yum install -y nginx

# 기본 웹페이지 생성 (Nginx 시작 전에)
cat > /usr/share/nginx/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>CloudArchitect Week7-2 - CloudWatch Logs</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #232f3e; }
        .info { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .logs { background: #f8f9fa; padding: 15px; border-radius: 5px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 CloudWatch Logs 실습 환경</h1>
        <div class="info">
            <h3>실습 목표</h3>
            <ul>
                <li>CloudWatch Logs 그룹 및 스트림 확인</li>
                <li>실시간 로그 모니터링</li>
                <li>로그 인사이트 쿼리 실습</li>
                <li>메트릭 필터 생성</li>
            </ul>
        </div>
        <div class="logs">
            <strong>로그 수집 상태:</strong><br>
            • Nginx Access Log: /var/log/nginx/access.log<br>
            • Nginx Error Log: /var/log/nginx/error.log<br>
            • CloudWatch Agent: 실행 중
        </div>
        <p><strong>현재 시간:</strong> <span id="datetime"></span></p>
        <p><strong>서버 정보:</strong> Amazon Linux 2023 + Nginx</p>
    </div>
    <script>
        document.getElementById('datetime').textContent = new Date().toLocaleString();
        setInterval(() => {
            document.getElementById('datetime').textContent = new Date().toLocaleString();
        }, 1000);
    </script>
</body>
</html>
HTML

# Nginx 시작 (로그 파일 자동 생성)
systemctl start nginx
systemctl enable nginx

# 초기 로그 생성을 위한 테스트 요청
sleep 2
curl -s http://localhost/ > /dev/null 2>&1 || true
curl -s http://localhost/test404 > /dev/null 2>&1 || true

# CloudWatch Agent 설치
yum install -y amazon-cloudwatch-agent

# CloudWatch Agent 설정 파일 생성
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'JSON'
{
    "agent": {
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/nginx/access",
                        "log_stream_name": "{instance_id}",
                        "timezone": "Asia/Seoul"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/nginx/error",
                        "log_stream_name": "{instance_id}",
                        "timezone": "Asia/Seoul"
                    }
                ]
            }
        }
    }
}
JSON

# CloudWatch Agent 시작
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 테스트 트래픽 생성을 위한 스크립트 생성
cat > /home/ec2-user/generate-traffic.sh << 'TRAFFIC'
#!/bin/bash
echo "웹 트래픽 생성 중..."
for i in {1..10}; do
    curl -s http://localhost/ > /dev/null
    curl -s http://localhost/test404 > /dev/null
    curl -s http://localhost/api/users > /dev/null
    curl -s http://localhost/notfound > /dev/null
    sleep 1
done
echo "트래픽 생성 완료"
TRAFFIC

chmod +x /home/ec2-user/generate-traffic.sh

# 자동 트래픽 생성 서비스 생성 (systemd)
cat > /etc/systemd/system/auto-traffic.service << 'SERVICE'
[Unit]
Description=Auto Traffic Generator for CloudWatch Logs Demo
After=nginx.service
Requires=nginx.service

[Service]
Type=oneshot
User=ec2-user
ExecStart=/home/ec2-user/generate-traffic.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
SERVICE

# 주기적 트래픽 생성 타이머 생성 (2분마다 실행)
cat > /etc/systemd/system/auto-traffic.timer << 'TIMER'
[Unit]
Description=Run auto traffic generator every 2 minutes
Requires=auto-traffic.service

[Timer]
OnUnitActiveSec=2min
Unit=auto-traffic.service

[Install]
WantedBy=timers.target
TIMER

# systemd 서비스 활성화
systemctl daemon-reload
systemctl enable auto-traffic.timer

# 타이머 시작 (2분마다 자동 트래픽 생성)
systemctl start auto-traffic.timer

# 완료 표시
echo "CloudWatch Logs 실습 환경 구축 완료" > /tmp/setup-complete.txt
EOF
        
        # EC2 인스턴스 생성
        INSTANCE_ID=$(aws ec2 run-instances \
            --image-id "$AMI_ID" \
            --count 1 \
            --instance-type t3.micro \
            --subnet-id "$PUBLIC_SUBNET_ID" \
            --security-group-ids "$SG_ID" \
            --iam-instance-profile Name="$INSTANCE_PROFILE_NAME" \
            --user-data file://user-data.sh \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=CloudArchitect},{Key=Lab,Value=Week7-2}]" \
            --query 'Instances[0].InstanceId' \
            --output text)
        
        rm -f user-data.sh
        show_success "EC2 인스턴스 생성 완료: $INSTANCE_ID"
    fi
    
    # 인스턴스 상태 확인
    show_info "인스턴스 시작 대기 중..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
    show_success "인스턴스 running 상태 도달"
    
    # User Data 스크립트 실행 완료 대기 (status check 통과까지)
    show_info "User Data 스크립트 실행 대기 중... (Nginx, CloudWatch Agent 설치 완료까지, 약 3-4분)"
    aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"
    
    show_success "User Data 스크립트 실행 완료"
    
    # Public IP 조회
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    show_success "인스턴스 준비 완료: $INSTANCE_ID (IP: $PUBLIC_IP)"
}

# CloudWatch Agent 상태 확인 함수
verify_cloudwatch_agent() {
    
    show_info "CloudWatch Agent 초기화 및 로그 그룹 생성 대기 중..."
    
    local max_attempts=30
    local attempt=0
    local access_log_found=false
    local error_log_found=false
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        # 로그 그룹 확인
        local access_log_group=$(aws logs describe-log-groups \
            --log-group-name-prefix "/aws/ec2/nginx/access" \
            --query 'logGroups[0].logGroupName' \
            --output text 2>/dev/null || echo "None")
        
        local error_log_group=$(aws logs describe-log-groups \
            --log-group-name-prefix "/aws/ec2/nginx/error" \
            --query 'logGroups[0].logGroupName' \
            --output text 2>/dev/null || echo "None")
        
        if [ "$access_log_group" != "None" ] && [ -n "$access_log_group" ]; then
            access_log_found=true
        fi
        
        if [ "$error_log_group" != "None" ] && [ -n "$error_log_group" ]; then
            error_log_found=true
        fi
        
        # 둘 다 생성되면 종료
        if [ "$access_log_found" = true ] && [ "$error_log_found" = true ]; then
            show_success "Access 로그 그룹 생성됨: $access_log_group"
            show_success "Error 로그 그룹 생성됨: $error_log_group"
            return 0
        fi
        
        # 진행 상황 표시
        if [ $((attempt % 5)) -eq 0 ]; then
            show_info "로그 그룹 생성 대기 중... ($attempt/$max_attempts, 약 $((max_attempts - attempt))초 남음)"
        fi
        
        sleep 10
    done
    
    # 타임아웃 후에도 확인
    if [ "$access_log_found" = true ]; then
        show_success "Access 로그 그룹 생성됨"
    else
        show_warning "Access 로그 그룹이 아직 생성되지 않았습니다. 실습 진행 중 자동으로 생성됩니다."
    fi
    
    if [ "$error_log_found" = true ]; then
        show_success "Error 로그 그룹 생성됨"
    else
        show_warning "Error 로그 그룹이 아직 생성되지 않았습니다. 실습 진행 중 자동으로 생성됩니다."
    fi
}

# 완료 요약 표시 함수
show_completion_summary() {
    # 변수 별칭 (일관성을 위해)
    PUBLIC_RT_ID="$RT_ID"
    WEB_SG_ID="$SG_ID"
    
    echo ""
    show_success "🎉 Week7-2 CloudWatch Logs 실습 환경 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    echo "  ✅ Security Group: CloudArchitect-Lab-Web-SG ($WEB_SG_ID)"
    echo "  ✅ IAM Role: $ROLE_NAME"
    echo "  ✅ EC2 Instance: $INSTANCE_NAME ($INSTANCE_ID)"
    echo "  ✅ Public IP: $PUBLIC_IP"
    echo ""
    
    echo "🌐 웹서버 접속 정보:"
    echo "• URL: http://$PUBLIC_IP"
    echo "• 웹서버: Nginx (자동 설치 완료)"
    echo "• 상태: 실행 중"
    echo ""
    
    echo "📊 CloudWatch Logs 설정:"
    echo "• Access Log Group: /aws/ec2/nginx/access"
    echo "• Error Log Group: /aws/ec2/nginx/error"
    echo "• Log Stream: $INSTANCE_ID"
    echo "• CloudWatch Agent: 실행 중"
    echo ""
    
    echo "🤖 자동 트래픽 생성 설정:"
    echo "• 1분 후: 첫 번째 자동 트래픽 생성 시작"
    echo "• 이후 2분마다: 지속적으로 트래픽 자동 생성"
    echo "• 로그 패턴: 정상 접속(200) + 404 에러 혼합"
    echo "• CloudWatch Logs에서 실시간 로그 수집 확인 가능"
    echo ""
    
    echo "🎯 다음 단계 (실습):"
    echo "1. 약 3-4분 후 CloudWatch Logs 콘솔에서 로그 그룹 확인"
    echo "2. 자동 생성된 로그 데이터로 실시간 스트림 모니터링"
    echo "3. 로그 인사이트 쿼리 실습 (200, 404 상태 코드 분석)"
    echo "4. 메트릭 필터 생성 (404 에러 카운트)"
    echo "5. Live tail로 실시간 로그 모니터링"
    echo ""
    
    echo "🔧 추가 트래픽 생성 방법:"
    echo "• 웹브라우저로 http://$PUBLIC_IP 접속 (수동)"
    echo "• SSH 접속 후 /home/ec2-user/generate-traffic.sh 실행 (수동)"
    echo "• 자동 트래픽은 2분마다 계속 생성됨 (별도 작업 불필요)"
    echo ""
    
    echo "💰 비용 절약: 실습 완료 후 cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Week7-2 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    aws_info=$(get_aws_account_info)
    account_id=$(echo "$aws_info" | cut -d':' -f1)
    region=$(echo "$aws_info" | cut -d':' -f2)
    user_arn=$(echo "$aws_info" | cut -d':' -f3)
    
    # REGION 변수를 전역으로 export
    export REGION="$region"
    
    # 헤더 표시
    echo "================================"
    echo "Week7-2: CloudWatch Logs 실습 - 사전 환경 구축"
    echo "================================"
    echo ""
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo "사용자: $user_arn"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 4 "네트워크 리소스 설정 중..."
    setup_network_resources
    create_subnet_and_security_group
    echo ""
    
    show_progress 2 4 "IAM 역할 생성 중..."
    create_iam_role
    echo ""
    
    show_progress 3 4 "EC2 인스턴스 생성 중..."
    create_ec2_instance
    echo ""
    
    show_progress 4 4 "CloudWatch Agent 상태 확인 중..."
    verify_cloudwatch_agent
    echo ""
    
    # 완료 요약
    show_completion_summary
    
    # 임시 파일 정리
    rm -f /tmp/week7-2-resources.env
}

# 스크립트 실행
main "$@"