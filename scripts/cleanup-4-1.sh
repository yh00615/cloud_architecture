#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab05: Amazon EC2 인스턴스 배포 - 최적 서버 구성 및 관리 정리
# 목적: setup-lab05-student.sh에서 생성된 네트워크 인프라만 정리
# 주의: 학생이 콘솔에서 생성한 EC2 인스턴스는 정리하지 않음
# ===========================================

# set -e 제거: 오류가 발생해도 스크립트 계속 실행



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

# 리소스 삭제 대기 함수 (삭제 완료까지 무제한 대기)
wait_for_deletion() {
    local resource_type=$1
    local resource_id=$2
    local resource_name=${3:-"Unknown"}
    
    show_info "$resource_type 삭제 대기 중... $resource_name ($resource_id)"
    
    case $resource_type in
        "subnet")
            while aws ec2 describe-subnets --subnet-ids $resource_id >/dev/null 2>&1; do
                echo -n "."
                sleep 3
            done
            echo ""
            show_success "Subnet 삭제 완료: $resource_name ($resource_id)"
            ;;
        "vpc")
            while aws ec2 describe-vpcs --vpc-ids $resource_id >/dev/null 2>&1; do
                echo -n "."
                sleep 3
            done
            echo ""
            show_success "VPC 삭제 완료: $resource_name ($resource_id)"
            ;;
        "igw")
            while aws ec2 describe-internet-gateways --internet-gateway-ids $resource_id >/dev/null 2>&1; do
                echo -n "."
                sleep 3
            done
            echo ""
            show_success "Internet Gateway 삭제 완료: $resource_name ($resource_id)"
            ;;
    esac
}

# Route Table 연결 해제 및 삭제
cleanup_route_tables() {
    show_info "Route Table 정리 중..."
    
    # Name 태그로 Route Table 조회 (기본 Route Table 제외)
    local route_tables=$(aws ec2 describe-route-tables \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-RT" \
        --query 'RouteTables[*].RouteTableId' \
        --output text 2>/dev/null)
    
    # Name 태그가 없으면 Lab05 태그로 찾기 (보조)
    if [ -z "$route_tables" ] || [ "$route_tables" = "None" ]; then
        route_tables=$(aws ec2 describe-route-tables \
            --filters "Name=tag:Lab,Values=Lab05" \
            --query 'RouteTables[*].RouteTableId' \
            --output text 2>/dev/null)
    fi
    
    if [ ! -z "$route_tables" ] && [ "$route_tables" != "None" ]; then
        for rt_id in $route_tables; do
            show_info "Route Table 정리 중: CloudArchitect-Lab-Public-RT ($rt_id)"
            
            # IGW로의 라우트 제거 (0.0.0.0/0 → IGW)
            local igw_routes=$(aws ec2 describe-route-tables \
                --route-table-ids $rt_id \
                --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0` && GatewayId!=null && starts_with(GatewayId, `igw-`)].GatewayId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$igw_routes" ] && [ "$igw_routes" != "None" ]; then
                show_info "IGW 라우트 제거 중: CloudArchitect-Lab-Public-RT ($rt_id) → $igw_routes"
                aws ec2 delete-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 >/dev/null 2>&1 || true
            fi
            
            # 연결된 서브넷 해제
            local associations=$(aws ec2 describe-route-tables \
                --route-table-ids $rt_id \
                --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$associations" ] && [ "$associations" != "None" ]; then
                show_info "서브넷 연결 해제 중: CloudArchitect-Lab-Public-RT ($rt_id)"
                for assoc_id in $associations; do
                    aws ec2 disassociate-route-table --association-id $assoc_id >/dev/null 2>&1 || true
                done
            fi
            
            # Route Table 삭제
            show_info "Route Table 삭제 중: CloudArchitect-Lab-Public-RT ($rt_id)"
            aws ec2 delete-route-table --route-table-id $rt_id >/dev/null 2>&1 || true
        done
        show_success "Route Table 정리 완료: CloudArchitect-Lab-Public-RT"
    else
        show_info "정리할 Route Table이 없습니다."
    fi
}

# Internet Gateway 분리 및 삭제
cleanup_internet_gateways() {
    show_info "Internet Gateway 정리 중..."
    
    # Name 태그로 Internet Gateway 찾기
    local igw_ids=$(aws ec2 describe-internet-gateways \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" \
        --query 'InternetGateways[*].InternetGatewayId' \
        --output text 2>/dev/null)
    
    # Name 태그가 없으면 Lab05 태그로 찾기 (보조)
    if [ -z "$igw_ids" ] || [ "$igw_ids" = "None" ]; then
        igw_ids=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Lab,Values=Lab05" \
            --query 'InternetGateways[*].InternetGatewayId' \
            --output text 2>/dev/null)
    fi
    
    if [ ! -z "$igw_ids" ] && [ "$igw_ids" != "None" ]; then
        for igw_id in $igw_ids; do
            # IGW Name 태그 조회
            local igw_name=$(aws ec2 describe-internet-gateways \
                --internet-gateway-ids $igw_id \
                --query 'InternetGateways[0].Tags[?Key==`Name`].Value | [0]' \
                --output text 2>/dev/null)
            
            if [ -z "$igw_name" ] || [ "$igw_name" = "None" ]; then
                igw_name="Unnamed"
            fi
            
            # 연결된 VPC 조회 및 분리
            local vpc_id=$(aws ec2 describe-internet-gateways \
                --internet-gateway-ids $igw_id \
                --query 'InternetGateways[0].Attachments[0].VpcId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$vpc_id" ] && [ "$vpc_id" != "None" ]; then
                show_info "Internet Gateway 분리 중: $igw_name ($igw_id) from VPC ($vpc_id)"
                aws ec2 detach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id >/dev/null 2>&1 || true
                
                # 분리 완료까지 대기
                show_info "Internet Gateway 분리 대기 중... $igw_name ($igw_id)"
                local detach_wait=0
                while [ $detach_wait -lt 30 ]; do
                    local attachment_state=$(aws ec2 describe-internet-gateways \
                        --internet-gateway-ids $igw_id \
                        --query 'InternetGateways[0].Attachments[0].State' \
                        --output text 2>/dev/null)
                    
                    if [ "$attachment_state" = "None" ] || [ -z "$attachment_state" ] || [ "$attachment_state" = "detached" ]; then
                        if [ $detach_wait -gt 0 ]; then
                            echo ""
                        fi
                        show_success "Internet Gateway 분리 완료: $igw_name ($igw_id)"
                        break
                    fi
                    
                    echo -n "."
                    sleep 2
                    ((detach_wait++))
                done
            fi
            
            # Internet Gateway 삭제
            show_info "Internet Gateway 삭제 중: $igw_name ($igw_id)"
            aws ec2 delete-internet-gateway --internet-gateway-id $igw_id >/dev/null 2>&1 || true
            
            # 삭제 완료까지 대기
            wait_for_deletion "igw" $igw_id $igw_name
        done
        show_success "Internet Gateway 정리 완료"
    else
        show_info "정리할 Internet Gateway가 없습니다."
    fi
}

# Security Group 삭제 (setup에서 생성한 것만)
cleanup_security_groups() {
    show_info "Security Group 정리 중..."
    
    # VPC ID 확인
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    
    if [ "$vpc_id" = "None" ] || [ -z "$vpc_id" ]; then
        show_info "VPC가 존재하지 않아 Security Group 정리를 건너뜁니다."
        return 0
    fi
    
    # Web Security Group 삭제 (setup에서 생성한 것)
    local web_sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=CloudArchitect-Lab-Web-SG" "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$web_sg_id" != "None" ] && [ ! -z "$web_sg_id" ]; then
        # Web SG를 사용 중인 인스턴스 확인
        local web_sg_in_use=$(aws ec2 describe-instances \
            --filters "Name=instance.group-id,Values=$web_sg_id" "Name=instance-state-name,Values=running,stopped,pending" \
            --query 'Reservations[*].Instances[*].InstanceId' \
            --output text 2>/dev/null)
        
        if [ -z "$web_sg_in_use" ] || [ "$web_sg_in_use" = "None" ]; then
            show_info "Web Security Group 삭제 중: CloudArchitect-Lab-Web-SG ($web_sg_id)"
            
            # 최대 60회 재시도 (3분)
            local delete_attempts=0
            local max_attempts=60
            while [ $delete_attempts -lt $max_attempts ]; do
                if aws ec2 delete-security-group --group-id "$web_sg_id" >/dev/null 2>&1; then
                    show_success "Web Security Group 삭제 완료: CloudArchitect-Lab-Web-SG ($web_sg_id)"
                    break
                else
                    ((delete_attempts++))
                    if [ $((delete_attempts % 10)) -eq 0 ]; then
                        show_info "Web Security Group 삭제 재시도 중... (시도 ${delete_attempts}/${max_attempts}회)"
                    fi
                    if [ $delete_attempts -ge $max_attempts ]; then
                        show_error "Web Security Group 삭제 실패: 최대 재시도 횟수 초과"
                        return 1
                    fi
                    sleep 3
                fi
            done
        else
            show_error "Web Security Group이 EC2 인스턴스에서 사용 중입니다: $web_sg_in_use"
            show_error "EC2 인스턴스 정리가 완료되지 않았습니다. 스크립트를 다시 실행하세요."
            exit 1
        fi
    else
        show_info "Web Security Group이 존재하지 않습니다."
    fi
    
    show_success "Security Group 정리 완료"
}

# Subnet 삭제 (재시도 로직 포함)
cleanup_subnets() {
    show_info "Subnet 정리 중..."
    
    local max_retries=5
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Name 태그로 서브넷 찾기 (CloudArchitect-Lab 관련 모든 서브넷)
        local subnet_ids=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-Subnet*" \
            --query 'Subnets[*].SubnetId' \
            --output text 2>/dev/null)
        
        # 추가로 Lab05 태그가 있는 서브넷도 찾기
        if [ -z "$subnet_ids" ] || [ "$subnet_ids" = "None" ]; then
            subnet_ids=$(aws ec2 describe-subnets \
                --filters "Name=tag:Lab,Values=Lab05" \
                --query 'Subnets[*].SubnetId' \
                --output text 2>/dev/null)
        fi
        
        if [ -z "$subnet_ids" ] || [ "$subnet_ids" = "None" ]; then
            show_success "Subnet 정리 완료"
            return 0
        fi
        
        local deleted_any=false
        
        for subnet_id in $subnet_ids; do
            # 서브넷 이름 조회
            local subnet_name=$(aws ec2 describe-subnets --subnet-ids $subnet_id --query 'Subnets[0].Tags[?Key==`Name`].Value | [0]' --output text 2>/dev/null || echo "Unknown")
            
            show_info "Subnet 삭제 시도: $subnet_name ($subnet_id)"
            
            # 서브넷에 연결된 네트워크 인터페이스 확인
            local eni_count=$(aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$subnet_id" --query 'length(NetworkInterfaces)' --output text 2>/dev/null || echo "0")
            
            if [ "$eni_count" -gt 0 ]; then
                show_warning "서브넷에 네트워크 인터페이스가 $eni_count 개 연결되어 있습니다. 대기 중..."
                sleep 5
                continue
            fi
            
            # 서브넷 삭제 시도
            if aws ec2 delete-subnet --subnet-id $subnet_id >/dev/null 2>&1; then
                show_success "Subnet 삭제 완료: $subnet_name ($subnet_id)"
                deleted_any=true
                
                # 삭제 완료까지 대기
                wait_for_deletion "subnet" $subnet_id $subnet_name
            else
                show_warning "Subnet 삭제 실패, 재시도 예정: $subnet_name ($subnet_id)"
            fi
        done
        
        # 삭제된 것이 없으면 의존성 해결을 위해 대기
        if [ "$deleted_any" = false ]; then
            show_info "의존성 해결을 위해 대기 중... (시도 $((retry_count + 1))/$max_retries)"
            sleep 10
        fi
        
        ((retry_count++))
    done
    
    show_success "Subnet 정리 완료"
}

# VPC 삭제 (마지막) - 의존성 완전 정리 후
cleanup_vpcs() {
    show_info "VPC 정리 중..."
    
    # Name 태그로 VPC 찾기
    local vpc_ids=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[*].VpcId' \
        --output text 2>/dev/null)
    
    if [ ! -z "$vpc_ids" ] && [ "$vpc_ids" != "None" ]; then
        for vpc_id in $vpc_ids; do
            local vpc_name=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "Unknown")
            
            # VPC 삭제 전 최종 의존성 확인 및 정리
            show_info "VPC 삭제 전 최종 의존성 확인: $vpc_name ($vpc_id)"
            
            # 1. 남은 ENI 확인 및 정리
            local enis=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text 2>/dev/null)
            if [ ! -z "$enis" ] && [ "$enis" != "None" ]; then
                show_warning "VPC에 네트워크 인터페이스가 남아있습니다: $enis"
                show_info "학생이 생성한 EC2 인스턴스를 먼저 삭제한 후 이 스크립트를 다시 실행하세요."
                return 1
            fi
            
            show_info "VPC 삭제 시도: $vpc_name ($vpc_id)"
            if aws ec2 delete-vpc --vpc-id $vpc_id >/dev/null 2>&1; then
                show_success "VPC 삭제 완료: $vpc_name ($vpc_id)"
            else
                show_warning "VPC 삭제 실패: $vpc_name ($vpc_id)"
                show_info "VPC에 여전히 의존성이 있을 수 있습니다. 학생이 생성한 리소스를 먼저 삭제해주세요."
            fi
        done
    else
        show_info "정리할 VPC가 없습니다."
    fi
    
    show_success "VPC 정리 완료"
}

# 삭제 계획 표시 함수
show_deletion_plan() {
    echo ""
    echo "🗑️ 삭제 계획:"
    echo ""
    
    echo "  🌐 네트워크 인프라 삭제 (setup-lab05-student.sh에서 생성한 것만):"
    echo "    🔥 Web Security Group: CloudArchitect-Lab-Web-SG"
    echo "    🔥 Route Table: CloudArchitect-Lab-*-RT"
    echo "    🔥 Internet Gateway: CloudArchitect-Lab-IGW"
    echo "    🔥 Public Subnet: CloudArchitect-Lab-Public-Subnet"
    echo "    🔥 VPC: CloudArchitect-Lab-VPC"
    echo ""
    
    echo "  ⚠️ 삭제하지 않는 리소스:"
    echo "    ⚪ EC2 인스턴스 (학생이 콘솔에서 직접 생성한 것)"
    echo "    ⚪ 키 페어 (학생이 직접 생성한 것)"
    echo "    ⚪ 추가 보안 그룹 (학생이 직접 생성한 것)"
    echo ""
    
    echo "  ⚠️ 삭제 순서:"
    echo "    1. 보안 그룹 (setup에서 생성한 것만)"
    echo "    2. 라우팅 테이블"
    echo "    3. Internet Gateway"
    echo "    4. Public 서브넷"
    echo "    5. VPC"
    echo ""
    
    echo "💰 비용 절약: 네트워크 인프라 과금이 중단됩니다"
    echo "⏱️  예상 시간: 약 3분"
    echo ""
    echo "🔔 주의사항:"
    echo "   • EC2 인스턴스가 실행 중이면 일부 리소스 삭제가 실패할 수 있습니다"
    echo "   • 먼저 학생이 생성한 EC2 인스턴스를 삭제한 후 이 스크립트를 실행하세요"
    echo ""
    echo "==========================================="
}

# 완료 후 결과 정리 함수
show_cleanup_summary() {
    echo ""
    echo "🎉 Lab05 네트워크 인프라 정리가 완료되었습니다!"
    echo ""
    
    # 삭제된 주요 리소스 정리
    echo "📋 삭제된 주요 리소스:"
    echo "  🗑️ Web Security Group: CloudArchitect-Lab-Web-SG"
    echo "  🗑️ Public Subnet: CloudArchitect-Lab-Public-Subnet"
    echo "  🗑️ Internet Gateway: CloudArchitect-Lab-IGW"
    echo "  🗑️ VPC: CloudArchitect-Lab-VPC"
    echo ""
    
    # 확인 방법
    echo "🔍 정리 확인 방법:"
    echo "  1. AWS 콘솔 → VPC → Your VPCs (CloudArchitect-Lab-VPC 없음 확인)"
    echo "  2. AWS 콘솔 → EC2 → Security Groups (CloudArchitect-Lab-Web-SG 없음 확인)"
    echo ""
    
    # 비용 및 다음 단계
    echo "💰 비용 절약: 네트워크 인프라 과금이 중단되었습니다"
    echo "📚 참고사항: 학생이 생성한 EC2 인스턴스는 별도로 삭제해야 합니다"
    echo ""
    
    echo ""
    echo "==========================================="
}

# 스크립트 초기화
echo "================================"
echo "Lab05: EC2 기초 네트워크 인프라 정리 (학생용)"
echo "================================"
echo "목적: setup-lab05-student.sh에서 생성한 리소스만 정리"
echo "================================"
echo ""

# 1단계: AWS 환경 확인
show_info "AWS 환경 확인 중..."
REGION=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "미설정")
USER_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "미설정")

echo "현재 리전: $REGION"
echo "계정 ID: $ACCOUNT_ID"
echo "사용자: $USER_ARN"
echo ""

# 2단계: Lab05 리소스 확인 (활성 상태만)
show_info "Lab05 관련 활성 리소스 확인 중..."

# VPC 확인
vpc_count=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")

# 서브넷 확인
subnet_count=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-Subnet*" --query 'length(Subnets)' --output text 2>/dev/null || echo "0")

# Internet Gateway 확인
igw_count=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" --query 'length(InternetGateways)' --output text 2>/dev/null || echo "0")

# Security Group 확인 (setup에서 생성한 것만)
sg_count=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=CloudArchitect-Lab-Web-SG" --query 'length(SecurityGroups)' --output text 2>/dev/null || echo "0")

# EC2 인스턴스 확인 (참고용, 삭제하지 않음)
ec2_count=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=CloudArchitect-Lab-*" "Name=instance-state-name,Values=running,stopped,pending" --query 'length(Reservations[].Instances[])' --output text 2>/dev/null || echo "0")

echo "활성 리소스 현황:"
echo "- VPC: $vpc_count 개"
echo "- Subnet: $subnet_count 개" 
echo "- Internet Gateway: $igw_count 개"
echo "- Security Group (setup 생성): $sg_count 개"
echo "- EC2 Instance (참고용): $ec2_count 개"

# 3단계: 삭제 계획 표시
show_deletion_plan

# 4단계: 사용자 확인
echo ""
show_warning "주의: setup-lab05-student.sh에서 생성된 네트워크 인프라만 삭제됩니다."
echo "계속하시겠습니까? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "정리 작업이 취소되었습니다."
    exit 0
fi
echo ""

# ===========================================
# 메인 실행 함수
# ===========================================
# EC2 인스턴스 삭제 (학생이 생성한 것 포함)
cleanup_ec2_instances() {
    show_info "EC2 인스턴스 정리 중..."
    
    # CloudArchitect-Lab 관련 EC2 인스턴스 조회
    local instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-*" "Name=instance-state-name,Values=running,stopped,pending" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null)
    
    # Name 태그가 없으면 Lab05 태그로 조회
    if [ -z "$instances" ] || [ "$instances" = "None" ]; then
        instances=$(aws ec2 describe-instances \
            --filters "Name=tag:Lab,Values=Lab05" "Name=instance-state-name,Values=running,stopped,pending" \
            --query 'Reservations[].Instances[].InstanceId' \
            --output text 2>/dev/null)
    fi
    
    # 태그가 없어도 CloudArchitect-Lab VPC에 있는 인스턴스 조회
    if [ -z "$instances" ] || [ "$instances" = "None" ]; then
        local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
        if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
            instances=$(aws ec2 describe-instances \
                --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,stopped,pending" \
                --query 'Reservations[].Instances[].InstanceId' \
                --output text 2>/dev/null)
        fi
    fi
    
    if [ ! -z "$instances" ] && [ "$instances" != "None" ]; then
        for instance_id in $instances; do
            # 인스턴스 이름 조회
            local instance_name=$(aws ec2 describe-instances \
                --instance-ids $instance_id \
                --query 'Reservations[0].Instances[0].Tags[?Key==`Name`].Value | [0]' \
                --output text 2>/dev/null || echo "Unknown")
            
            show_info "EC2 인스턴스 종료 중: $instance_name ($instance_id)"
            
            if aws ec2 terminate-instances --instance-ids "$instance_id" >/dev/null 2>&1; then
                show_success "EC2 인스턴스 종료 시작: $instance_id"
                
                # 종료 완료까지 대기 (최대 5분)
                show_info "EC2 인스턴스 종료 대기 중... $instance_name ($instance_id)"
                local wait_count=0
                local max_wait=30
                while [ $wait_count -lt $max_wait ]; do
                    local state=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
                    if [ "$state" = "terminated" ] || [ "$state" = "None" ] || [ -z "$state" ]; then
                        if [ $wait_count -gt 0 ]; then
                            echo ""
                        fi
                        show_success "EC2 인스턴스 종료 완료: $instance_name ($instance_id)"
                        break
                    fi
                    echo -n "."
                    ((wait_count++))
                    if [ $wait_count -ge $max_wait ]; then
                        echo ""
                        show_error "EC2 인스턴스 종료 타임아웃: $instance_id"
                        return 1
                    fi
                    sleep 10
                    ((wait_count++))
                done
            else
                show_warning "EC2 인스턴스 종료 실패: $instance_name ($instance_id)"
            fi
        done
        show_success "EC2 인스턴스 정리 완료"
    else
        show_info "정리할 EC2 인스턴스가 없습니다."
    fi
}

main() {
    show_progress 1 6 "EC2 인스턴스 정리 중..."
    cleanup_ec2_instances
    echo ""
    
    show_progress 2 6 "Security Group 정리 중..."
    cleanup_security_groups
    echo ""
    
    show_progress 3 6 "Route Table 정리 중..."
    cleanup_route_tables
    echo ""
    
    show_progress 4 6 "Internet Gateway 정리 중..."
    cleanup_internet_gateways
    echo ""
    
    show_progress 5 6 "Subnet 정리 중..."
    cleanup_subnets
    echo ""
    
    show_progress 6 6 "VPC 정리 중..."
    cleanup_vpcs
    echo ""
    
    # 최종 정리 결과 표시
    show_cleanup_summary
}

# 메인 함수 실행
main

echo ""
echo "Lab05 네트워크 인프라 정리 작업이 완료되었습니다."