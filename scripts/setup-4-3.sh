#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Lab06: Amazon EC2 Auto Scaling 구성 - 탄력적 인프라 구현
# ================================
# 목적: Auto Scaling 실습을 위한 VPC 네트워크 환경 및 EC2 템플릿 생성
# 예상 시간: 약 15분
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

show_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

show_important() {
    echo -e "${PURPLE}🔥 $1${NC}"
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
    local existing_public_subnet1=""
    local existing_public_subnet2=""
    local existing_sg=""
    local existing_ec2=""
    
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        # Internet Gateway 확인
        existing_igw=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$existing_vpc" "Name=attachment.state,Values=available" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
        
        # Public Subnets 확인
        existing_public_subnet1=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-1" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        existing_public_subnet2=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-2" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        # Security Group 확인
        existing_sg=$(aws ec2 describe-security-groups \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-WebServer-SG" "Name=vpc-id,Values=$existing_vpc" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        # EC2 Instance 확인
        existing_ec2=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-WebServer" "Name=instance-state-name,Values=running,pending" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null)
    fi
    
    echo "📋 Auto Scaling 실습 인프라 구성:"
    
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
    
    # Public Subnets 상태 표시
    if [ "$existing_public_subnet1" != "None" ] && [ -n "$existing_public_subnet1" ] && [ "$existing_public_subnet2" != "None" ] && [ -n "$existing_public_subnet2" ]; then
        echo "🔄 Public Subnets: CloudArchitect-Lab-Public-Subnet-1/2 - 기존 재사용"
    else
        echo "✨ Public Subnets: CloudArchitect-Lab-Public-Subnet-1/2 (Multi-AZ) - 새로 생성"
    fi
    
    # Security Group 상태 표시
    if [ "$existing_sg" != "None" ] && [ -n "$existing_sg" ]; then
        echo "🔄 Security Group: CloudArchitect-Lab-WebServer-SG ($existing_sg) - 기존 재사용"
    else
        echo "✨ Security Group: CloudArchitect-Lab-WebServer-SG (HTTP/SSH 허용) - 새로 생성"
    fi
    
    # EC2 Instance 상태 표시
    if [ "$existing_ec2" != "None" ] && [ -n "$existing_ec2" ]; then
        echo "🔄 EC2 Instance: CloudArchitect-Lab-WebServer ($existing_ec2) - 기존 재사용"
    else
        echo "✨ EC2 Instance: CloudArchitect-Lab-WebServer (t3.micro, Apache) - 새로 생성"
    fi
    
    echo ""
    echo "🎯 핵심 학습 목표:"
    echo "• Multi-AZ VPC 네트워크 구성 이해"
    echo "• Auto Scaling 실습을 위한 기반 환경 구축"
    echo "• Launch Template, ASG, ALB 실습 준비"
    echo "• 탄력적 인프라 구현 및 관리"
    echo ""
    
    echo "⚠️ 주의사항:"
    echo "• EC2 인스턴스로 인해 과금될 수 있음"
    echo "• 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "• 예상 소요 시간: 약 15분"
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab06 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab06 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab06 리소스 생성을 시작합니다..."
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
        --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=CloudArchitect-Lab-VPC},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
        --query 'Vpc.VpcId' --output text)
    
    # DNS 설정 활성화
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames >/dev/null 2>&1
    aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support >/dev/null 2>&1
    
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
        --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=CloudArchitect-Lab-IGW},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
        --query 'InternetGateway.InternetGatewayId' --output text)
    
    # VPC에 연결
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID >/dev/null 2>&1
    
    show_success "Internet Gateway 생성 및 연결 완료: CloudArchitect-Lab-IGW ($IGW_ID)"
}

# ===========================================
# Public Subnet 생성/재사용 함수 (2개)
# ===========================================
create_public_subnets() {
    show_info "Public Subnet 확인/생성 중..."
    
    # 첫 번째 Public Subnet 확인/생성
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-1" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.0.0/24" \
            "Name=availability-zone,Values=${REGION}a" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
        show_success "기존 Public Subnet 1 사용: CloudArchitect-Lab-Public-Subnet-1 ($PUBLIC_SUBNET_ID)"
    else
        show_info "새 Public Subnet 1 생성 중..."
        PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.0.0/24 \
            --availability-zone ${REGION}a \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet-1},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2a},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        show_success "Public Subnet 1 생성 완료: CloudArchitect-Lab-Public-Subnet-1 ($PUBLIC_SUBNET_ID)"
    fi
    
    # Public IP 자동 할당 설정
    aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch >/dev/null 2>&1
    
    # 두 번째 Public Subnet 확인/생성 (ALB를 위한 Multi-AZ)
    PUBLIC_SUBNET2_ID=$(aws ec2 describe-subnets \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet-2" \
            "Name=vpc-id,Values=$VPC_ID" \
            "Name=cidr-block,Values=10.0.1.0/24" \
            "Name=availability-zone,Values=ap-northeast-2b" \
            "Name=state,Values=available" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_SUBNET2_ID" != "None" ] && [ -n "$PUBLIC_SUBNET2_ID" ]; then
        show_success "기존 Public Subnet 2 재사용: CloudArchitect-Lab-Public-Subnet-2 ($PUBLIC_SUBNET2_ID)"
    else
        show_info "새 Public Subnet 2 생성 중..."
        PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block 10.0.1.0/24 \
            --availability-zone ap-northeast-2b \
            --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-Subnet-2},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=AZ,Value=2b},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
            --query 'Subnet.SubnetId' --output text)
        show_success "Public Subnet 2 생성 완료: CloudArchitect-Lab-Public-Subnet-2 ($PUBLIC_SUBNET2_ID)"
    fi
    
    # Public IP 자동 할당 설정
    aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET2_ID --map-public-ip-on-launch >/dev/null 2>&1
}

# ===========================================
# Route Table 생성/설정 함수
# ===========================================
create_route_table() {
    show_info "Route Table 설정 중..."
    
    # 기존 Route Table 확인
    PUBLIC_RT_ID=$(aws ec2 describe-route-tables \
        --filters \
            "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
        show_success "기존 Route Table 재사용: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    else
        show_info "새 Route Table 생성 중..."
        PUBLIC_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=CloudArchitect-Lab-Public-RT},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Network},{Key=Type,Value=Public},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
            --query 'RouteTable.RouteTableId' --output text)
        show_success "Route Table 생성 완료: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    fi
    
    # Internet Gateway 라우트 추가
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID >/dev/null 2>&1 || true
    
    # 서브넷들과 연결
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET2_ID --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1 || true
    
    show_success "Route Table 설정 완료"
}

# ===========================================
# 보안 그룹 생성/재사용 함수
# ===========================================
create_security_group() {
    show_info "보안 그룹 확인/생성 중..."
    
    local sg_name="CloudArchitect-Lab-WebServer-SG"
    
    # 기존 보안 그룹 확인
    SG_ID=$(aws ec2 describe-security-groups \
        --filters \
            "Name=tag:Name,Values=$sg_name" \
            "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
        show_success "기존 보안 그룹 재사용: $sg_name ($SG_ID)"
        return 0
    fi
    
    show_info "새 보안 그룹 생성 중..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name $sg_name \
        --description "CloudArchitect Lab06 Web Server Security Group" \
        --vpc-id $VPC_ID \
        --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value='$sg_name'},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Security},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
        --query 'GroupId' --output text)
    
    show_info "보안 그룹 규칙 추가 중..."
    
    # SSH 접근 (22번 포트)
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    # HTTP 접근 (80번 포트)
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    # HTTPS 접근 (443번 포트)
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 >/dev/null 2>&1
    
    show_success "보안 그룹 생성 완료: $sg_name ($SG_ID)"
}

# ===========================================
# User Data 스크립트 생성 함수
# ===========================================
create_user_data() {
    show_info "User Data 스크립트 생성 중..."
    
    cat > user-data.sh << 'EOF'
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# EC2 Instance Connect 설정
dnf install -y ec2-instance-connect
systemctl enable ec2-instance-connect
systemctl start ec2-instance-connect

# SSH 서비스 재시작
systemctl restart sshd

# 인스턴스 메타데이터 미리 조회 (IMDSv2 사용)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "정보 없음")
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "정보 없음")
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "정보 없음")
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "정보 없음")

# 웹 페이지 생성 (메타데이터 직접 삽입)
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudArchitect Lab06 - 웹 서버</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .info-box {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .status {
            color: #4CAF50;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 CloudArchitect Lab06</h1>
            <h2>Auto Scaling 실습 환경</h2>
        </div>
        
        <div class="info-box">
            <h3>📋 서버 정보</h3>
            <p><strong>인스턴스 ID:</strong> <span id="instance-id">$INSTANCE_ID</span></p>
            <p><strong>가용 영역:</strong> <span id="availability-zone">$AZ</span></p>
            <p><strong>프라이빗 IP:</strong> <span id="private-ip">$PRIVATE_IP</span></p>
            <p><strong>퍼블릭 IP:</strong> <span id="public-ip">$PUBLIC_IP</span></p>
        </div>
        
        <div class="info-box">
            <h3>✅ 서비스 상태</h3>
            <p>Apache 웹 서버: <span class="status">실행 중</span></p>
            <p>Auto Scaling 준비: <span class="status">완료</span></p>
        </div>
        
        <div class="info-box">
            <h3>🎯 다음 단계</h3>
            <p>1. Launch Template 생성</p>
            <p>2. Auto Scaling Group 구성</p>
            <p>3. Application Load Balancer 설정</p>
            <p>4. Auto Scaling 정책 구성</p>
        </div>
    </div>
    
    <script>
        // IMDSv2를 위한 토큰 기반 메타데이터 조회
        async function getMetadata(path) {
            try {
                // 먼저 토큰 획득
                const tokenResponse = await fetch('http://169.254.169.254/latest/api/token', {
                    method: 'PUT',
                    headers: {
                        'X-aws-ec2-metadata-token-ttl-seconds': '21600'
                    }
                });
                
                if (!tokenResponse.ok) {
                    throw new Error('Token request failed');
                }
                
                const token = await tokenResponse.text();
                
                // 토큰을 사용하여 메타데이터 조회
                const metadataResponse = await fetch(`http://169.254.169.254/latest/meta-data/${path}`, {
                    headers: {
                        'X-aws-ec2-metadata-token': token
                    }
                });
                
                if (!metadataResponse.ok) {
                    throw new Error('Metadata request failed');
                }
                
                return await metadataResponse.text();
            } catch (error) {
                console.error(`Failed to get metadata for ${path}:`, error);
                return '정보 없음';
            }
        }
        
        // 각 메타데이터 조회
        getMetadata('instance-id').then(data => {
            document.getElementById('instance-id').textContent = data;
        });
        
        getMetadata('placement/availability-zone').then(data => {
            document.getElementById('availability-zone').textContent = data;
        });
        
        getMetadata('local-ipv4').then(data => {
            document.getElementById('private-ip').textContent = data;
        });
        
        getMetadata('public-ipv4').then(data => {
            document.getElementById('public-ip').textContent = data;
        });
    </script>
</body>
</html>
HTML

# 시스템 정보 로그 생성
echo "=== CloudArchitect Lab06 웹 서버 설정 완료 ===" > /var/log/lab06-setup.log
echo "설정 시간: $(date)" >> /var/log/lab06-setup.log
echo "인스턴스 ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/lab06-setup.log
echo "Apache 상태: $(systemctl is-active httpd)" >> /var/log/lab06-setup.log
EOF
    
    show_success "User Data 스크립트 생성 완료"
}

# ===========================================
# EC2 인스턴스 생성 함수
# ===========================================
create_ec2_instance() {
    show_info "EC2 인스턴스 생성 중..."
    
    # 최신 Amazon Linux 2023 AMI 조회 (SSM Parameter 사용)
    local AMI_ID=$(aws ssm get-parameter \
        --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
        --query Parameter.Value \
        --output text)
    
    show_info "사용할 AMI: $AMI_ID (Amazon Linux 2023)"
    
    # EC2 인스턴스 생성 (IMDS 설정 포함)
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --count 1 \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --subnet-id $PUBLIC_SUBNET_ID \
        --user-data file://user-data.sh \
        --metadata-options "HttpTokens=optional,HttpPutResponseHopLimit=2,HttpEndpoint=enabled" \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudArchitect-Lab-WebServer},{Key=Project,Value=CloudArchitect},{Key=Environment,Value=Lab},{Key=Component,Value=Compute},{Key=Lab,Value=Lab06},{Key=CreatedBy,Value=setup-lab06-student.sh}]' \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    show_success "EC2 인스턴스 생성 완료: $INSTANCE_ID"
    
    # 인스턴스 실행 대기
    show_info "EC2 인스턴스 실행 대기 중... (예상 시간: 2-3분)"
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID
    show_success "EC2 인스턴스 실행 완료: $INSTANCE_ID"
    echo ""
}

# ===========================================
# 인스턴스 정보 조회 함수
# ===========================================
get_instance_info() {
    show_info "인스턴스 정보 조회 중..."
    
    local instance_info=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress,Placement.AvailabilityZone]' \
        --output text)
    
    PUBLIC_IP=$(echo $instance_info | cut -d' ' -f1)
    PRIVATE_IP=$(echo $instance_info | cut -d' ' -f2)
    AZ=$(echo $instance_info | cut -d' ' -f3)
    
    show_success "인스턴스 정보 조회 완료"
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab06 Auto Scaling 실습 인프라 구축이 완료되었습니다!"
    echo ""
    
    # 생성된 주요 리소스 정리
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    echo "  ✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
    echo "  ✅ Public Subnet 1: CloudArchitect-Lab-Public-Subnet-1 ($PUBLIC_SUBNET_ID)"
    echo "  ✅ Public Subnet 2: CloudArchitect-Lab-Public-Subnet-2 ($PUBLIC_SUBNET2_ID)"
    echo "  ✅ Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
    echo "  ✅ Security Group: CloudArchitect-Lab-WebServer-SG ($SG_ID)"
    echo "  ✅ EC2 Instance: CloudArchitect-Lab-WebServer ($INSTANCE_ID)"
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo "  ✅ EC2 Public IP: $PUBLIC_IP"
    fi
    echo ""
    
    echo "🎯 다음 단계 (실습 가이드 참조):"
    echo "1. 웹 브라우저로 http://$PUBLIC_IP 접속하여 웹 서버 확인"
    echo "2. EC2 콘솔에서 Instance Connect로 SSH 접속하여 서버 상태 확인"
    echo "3. 이 인스턴스를 기반으로 Launch Template 생성"
    echo "4. Auto Scaling Group 및 Application Load Balancer 구성"
    echo "5. Auto Scaling 정책 및 CloudWatch 알람 설정"
    echo ""
    
    echo "💡 참고사항:"
    echo "• Multi-AZ 서브넷 환경이 구성되어 ALB 배치 준비 완료"
    echo "• Launch Template 생성을 위한 템플릿 인스턴스 준비 완료"
    echo "• Auto Scaling 실습을 위한 기반 환경 구축 완료"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    echo "✅ Lab06 스크립트 실행 완료"
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
    echo "Lab06: Amazon EC2 Auto Scaling 구성 - 탄력적 인프라 구현"
    echo "================================"
    echo "목적: Auto Scaling 실습을 위한 VPC 네트워크 환경 및 EC2 템플릿 생성"
    echo "예상 시간: 약 15분"
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
    aws autoscaling describe-auto-scaling-groups --max-items 1 >/dev/null 2>&1 && show_success "Auto Scaling 권한 확인 완료" || show_warning "Auto Scaling 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 8 "VPC 생성 중..."
    create_vpc
    echo ""
    
    show_progress 2 8 "Internet Gateway 생성 중..."
    create_internet_gateway
    echo ""
    
    show_progress 3 8 "Public Subnets 생성 중..."
    create_public_subnets
    echo ""
    
    show_progress 4 8 "Route Table 생성 중..."
    create_route_table
    echo ""
    
    show_progress 5 8 "보안 그룹 생성 중..."
    create_security_group
    echo ""
    
    show_progress 6 8 "User Data 스크립트 생성 중..."
    create_user_data
    echo ""
    
    show_progress 7 8 "EC2 인스턴스 생성 중..."
    create_ec2_instance
    echo ""
    
    show_progress 8 8 "인스턴스 정보 조회 중..."
    get_instance_info
    echo ""
    
    # 완료 요약 표시
    show_completion_summary
}

# 스크립트 실행
main "$@"