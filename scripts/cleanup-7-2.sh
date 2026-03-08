#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ===========================================
# Lab11: CloudWatch Logs 실습 - 환경 정리
# 목적: Lab11에서 생성된 모든 AWS 리소스를 안전하게 정리
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

# 메인 실행 함수
main() {
    show_info "기존 리소스 상태를 확인합니다..."
    
    # 간단한 필터링으로 기존 리소스 확인
    local existing_vpc=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    local existing_instance=""
    local existing_igw=""
    local existing_subnet=""
    local existing_sg=""
    local existing_rt=""
    local existing_role=""
    local existing_profile=""
    local existing_access_log=""
    local existing_error_log=""
    
    # EC2 인스턴스 확인
    existing_instance=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-LogServer" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null)
    
    # VPC가 있으면 해당 VPC에 속한 리소스들 확인
    if [ "$existing_vpc" != "None" ] && [ -n "$existing_vpc" ]; then
        existing_igw=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$existing_vpc" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
        
        existing_subnet=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$existing_vpc" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        existing_sg=$(aws ec2 describe-security-groups \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Web-SG" "Name=vpc-id,Values=$existing_vpc" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        existing_rt=$(aws ec2 describe-route-tables \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" "Name=vpc-id,Values=$existing_vpc" \
            --query 'RouteTables[0].RouteTableId' \
            --output text 2>/dev/null)
    fi
    
    # IAM 리소스 확인
    existing_role=$(aws iam get-role --role-name "CloudArchitect-Lab-CloudWatchAgent-Role" --query 'Role.RoleName' --output text 2>/dev/null)
    existing_profile=$(aws iam get-instance-profile --instance-profile-name "CloudArchitect-Lab-CloudWatchAgent-InstanceProfile" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null)
    
    # CloudWatch Logs 그룹 확인
    existing_access_log=$(aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/nginx/access" --query 'logGroups[0].logGroupName' --output text 2>/dev/null)
    existing_error_log=$(aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/nginx/error" --query 'logGroups[0].logGroupName' --output text 2>/dev/null)
    
    # None 값을 빈 문자열로 정리
    [ "$existing_vpc" = "None" ] && existing_vpc=""
    [ "$existing_instance" = "None" ] && existing_instance=""
    [ "$existing_igw" = "None" ] && existing_igw=""
    [ "$existing_subnet" = "None" ] && existing_subnet=""
    [ "$existing_sg" = "None" ] && existing_sg=""
    [ "$existing_rt" = "None" ] && existing_rt=""
    [ "$existing_role" = "None" ] && existing_role=""
    [ "$existing_profile" = "None" ] && existing_profile=""
    [ "$existing_access_log" = "None" ] && existing_access_log=""
    [ "$existing_error_log" = "None" ] && existing_error_log=""
    
    echo ""
    echo "🔍 발견된 Lab11 리소스:"
    
    # EC2 인스턴스 상태 표시
    if [ -n "$existing_instance" ]; then
        local instance_state=$(aws ec2 describe-instances --instance-ids "$existing_instance" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
        echo "✅ EC2 인스턴스: CloudArchitect-Lab-LogServer ($existing_instance, $instance_state)"
    else
        echo "⚪ EC2 인스턴스: 이미 종료됨 또는 존재하지 않음"
    fi
    
    # VPC 리소스 상태 표시
    if [ -n "$existing_vpc" ]; then
        echo "✅ VPC: CloudArchitect-Lab-VPC ($existing_vpc)"
    else
        echo "⚪ VPC: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_igw" ]; then
        echo "✅ Internet Gateway: CloudArchitect-Lab-IGW ($existing_igw)"
    else
        echo "⚪ Internet Gateway: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_subnet" ]; then
        echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($existing_subnet)"
    else
        echo "⚪ Public Subnet: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_sg" ]; then
        echo "✅ Security Group: CloudArchitect-Lab-Web-SG ($existing_sg)"
    else
        echo "⚪ Security Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_rt" ]; then
        echo "✅ Route Table: CloudArchitect-Lab-Public-RT ($existing_rt)"
    else
        echo "⚪ Route Table: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # IAM 리소스 상태 표시
    if [ -n "$existing_role" ]; then
        echo "✅ IAM Role: CloudArchitect-Lab-CloudWatchAgent-Role"
    else
        echo "⚪ IAM Role: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_profile" ]; then
        echo "✅ Instance Profile: CloudArchitect-Lab-CloudWatchAgent-InstanceProfile"
    else
        echo "⚪ Instance Profile: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # CloudWatch Logs 상태 표시
    if [ -n "$existing_access_log" ]; then
        echo "✅ CloudWatch Log Group: $existing_access_log"
    else
        echo "⚪ Access Log Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_error_log" ]; then
        echo "✅ CloudWatch Log Group: $existing_error_log"
    else
        echo "⚪ Error Log Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    echo ""
    echo "🗑️ 삭제 계획:"
    
    # EC2 인스턴스 삭제 계획
    if [ -n "$existing_instance" ]; then
        echo "  🔥 EC2 인스턴스: CloudArchitect-Lab-LogServer ($existing_instance) - 삭제 예정"
    else
        echo "  ⚪ EC2 인스턴스: 이미 종료됨 또는 존재하지 않음"
    fi
    
    # Security Group 삭제 계획
    if [ -n "$existing_sg" ]; then
        echo "  🔥 Security Group: CloudArchitect-Lab-Web-SG ($existing_sg) - 삭제 예정"
    else
        echo "  ⚪ Security Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Route Table 삭제 계획
    if [ -n "$existing_rt" ]; then
        echo "  🔥 Route Table: CloudArchitect-Lab-Public-RT ($existing_rt) - 삭제 예정"
    else
        echo "  ⚪ Route Table: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Internet Gateway 삭제 계획
    if [ -n "$existing_igw" ]; then
        echo "  🔥 Internet Gateway: CloudArchitect-Lab-IGW ($existing_igw) - 삭제 예정"
    else
        echo "  ⚪ Internet Gateway: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Subnet 삭제 계획
    if [ -n "$existing_subnet" ]; then
        echo "  🔥 Public Subnet: CloudArchitect-Lab-Public-Subnet ($existing_subnet) - 삭제 예정"
    else
        echo "  ⚪ Public Subnet: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # VPC 삭제 계획
    if [ -n "$existing_vpc" ]; then
        echo "  🔥 VPC: CloudArchitect-Lab-VPC ($existing_vpc) - 삭제 예정"
    else
        echo "  ⚪ VPC: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # IAM 리소스 삭제 계획
    if [ -n "$existing_role" ]; then
        echo "  🔥 IAM Role: CloudArchitect-Lab-CloudWatchAgent-Role - 삭제 예정"
    else
        echo "  ⚪ IAM Role: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_profile" ]; then
        echo "  🔥 Instance Profile: CloudArchitect-Lab-CloudWatchAgent-InstanceProfile - 삭제 예정"
    else
        echo "  ⚪ Instance Profile: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # CloudWatch Logs 삭제 계획
    if [ -n "$existing_access_log" ]; then
        echo "  🔥 CloudWatch Log Group: $existing_access_log - 삭제 예정"
    else
        echo "  ⚪ Access Log Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ -n "$existing_error_log" ]; then
        echo "  🔥 CloudWatch Log Group: $existing_error_log - 삭제 예정"
    else
        echo "  ⚪ Error Log Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    echo ""
    echo "⚠️ 이 작업은 위의 모든 리소스를 영구적으로 삭제합니다"
    echo "🔍 삭제 완료 후 AWS 콘솔에서 리소스가 정말 삭제되었는지 다시 한 번 확인하세요"
    echo "🔄 삭제는 의존성 순서에 따라 안전하게 진행됩니다"
    echo ""
    echo ""
    echo "🔔 계속 진행하기 전에 위 삭제 계획을 검토하세요"
    echo ""
    
    show_warning "주의: Lab11에서 생성된 모든 AWS 리소스가 삭제됩니다."
    echo ""
    echo "계속하시겠습니까? (y/N):"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_info "Lab11 정리가 취소되었습니다."
        exit 0
    fi
    
    show_info "리소스 삭제를 시작합니다..."
    echo ""
    
    # 1단계: EC2 인스턴스 정리
    show_progress 1 5 "EC2 인스턴스 정리 중..."
    if [ -n "$existing_instance" ]; then
        show_info "EC2 인스턴스 종료 중... ($existing_instance)"
        local instance_state=$(aws ec2 describe-instances --instance-ids "$existing_instance" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
        
        if [ "$instance_state" != "terminated" ] && [ "$instance_state" != "terminating" ]; then
            aws ec2 terminate-instances --instance-ids "$existing_instance" >/dev/null 2>&1
            show_info "인스턴스 종료 대기 중... (최대 3분 소요)"
            aws ec2 wait instance-terminated --instance-ids "$existing_instance" --cli-read-timeout 300 --cli-connect-timeout 60 2>/dev/null || true
        fi
        show_success "EC2 인스턴스 종료 완료: $existing_instance"
    else
        show_info "정리할 EC2 인스턴스가 없습니다"
    fi
    echo ""
    
    # 2단계: CloudWatch Logs 정리
    show_progress 2 5 "CloudWatch Logs 정리 중..."
    local deleted_logs=0
    
    if [ -n "$existing_access_log" ]; then
        show_info "Access 로그 그룹 삭제 중: $existing_access_log"
        aws logs delete-log-group --log-group-name "$existing_access_log" >/dev/null 2>&1 && deleted_logs=$((deleted_logs + 1))
        show_success "Access 로그 그룹 삭제 완료"
    fi
    
    if [ -n "$existing_error_log" ]; then
        show_info "Error 로그 그룹 삭제 중: $existing_error_log"
        aws logs delete-log-group --log-group-name "$existing_error_log" >/dev/null 2>&1 && deleted_logs=$((deleted_logs + 1))
        show_success "Error 로그 그룹 삭제 완료"
    fi
    
    if [ $deleted_logs -gt 0 ]; then
        show_success "CloudWatch Logs 정리 완료 ($deleted_logs개 삭제)"
    else
        show_info "정리할 CloudWatch Logs가 없습니다"
    fi
    echo ""
    
    # 3단계: IAM 리소스 정리
    show_progress 3 5 "IAM 리소스 정리 중..."
    
    if [ -n "$existing_profile" ]; then
        show_info "Instance Profile에서 역할 제거 중..."
        aws iam remove-role-from-instance-profile \
            --instance-profile-name "CloudArchitect-Lab-CloudWatchAgent-InstanceProfile" \
            --role-name "CloudArchitect-Lab-CloudWatchAgent-Role" >/dev/null 2>&1 || true
        
        show_info "Instance Profile 삭제 중..."
        aws iam delete-instance-profile --instance-profile-name "CloudArchitect-Lab-CloudWatchAgent-InstanceProfile" >/dev/null 2>&1
        show_success "Instance Profile 삭제 완료"
    fi
    
    if [ -n "$existing_role" ]; then
        show_info "IAM 역할에서 정책 분리 중..."
        aws iam detach-role-policy \
            --role-name "CloudArchitect-Lab-CloudWatchAgent-Role" \
            --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy >/dev/null 2>&1 || true
        
        show_info "IAM 역할 삭제 중..."
        aws iam delete-role --role-name "CloudArchitect-Lab-CloudWatchAgent-Role" >/dev/null 2>&1
        show_success "IAM 역할 삭제 완료"
    fi
    
    if [ -z "$existing_role" ] && [ -z "$existing_profile" ]; then
        show_info "정리할 IAM 리소스가 없습니다"
    fi
    echo ""
    
    # 4단계: Security Group 정리
    show_progress 4 5 "Security Group 정리 중..."
    if [ -n "$existing_sg" ]; then
        show_info "Security Group 삭제 중: $existing_sg"
        aws ec2 delete-security-group --group-id "$existing_sg" >/dev/null 2>&1 || true
        show_success "Security Group 삭제 완료: $existing_sg"
    else
        show_info "정리할 Security Group이 없습니다"
    fi
    echo ""
    
    # 5단계: 네트워크 리소스 정리
    show_progress 5 5 "네트워크 리소스 정리 중..."
    
    # Route Table 정리
    if [ -n "$existing_rt" ]; then
        show_info "Route Table 정리 중: $existing_rt"
        
        # 서브넷 연결 해제
        local associations=$(aws ec2 describe-route-tables \
            --route-table-ids "$existing_rt" \
            --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' \
            --output text 2>/dev/null)
        
        if [ "$associations" != "None" ] && [ -n "$associations" ]; then
            for assoc_id in $associations; do
                aws ec2 disassociate-route-table --association-id "$assoc_id" >/dev/null 2>&1 || true
            done
        fi
        
        aws ec2 delete-route-table --route-table-id "$existing_rt" >/dev/null 2>&1 || true
        show_success "Route Table 삭제 완료: $existing_rt"
    fi
    
    # Internet Gateway 분리 및 삭제
    if [ -n "$existing_igw" ] && [ -n "$existing_vpc" ]; then
        show_info "Internet Gateway VPC 연결 해제 중: $existing_igw"
        aws ec2 detach-internet-gateway --vpc-id "$existing_vpc" --internet-gateway-id "$existing_igw" >/dev/null 2>&1 || true
        
        show_info "Internet Gateway 삭제 중: $existing_igw"
        aws ec2 delete-internet-gateway --internet-gateway-id "$existing_igw" >/dev/null 2>&1 || true
        show_success "Internet Gateway 삭제 완료: $existing_igw"
    fi
    
    # 서브넷 삭제
    if [ -n "$existing_subnet" ]; then
        show_info "Subnet 삭제 중: $existing_subnet"
        aws ec2 delete-subnet --subnet-id "$existing_subnet" >/dev/null 2>&1 || true
        show_success "Subnet 삭제 완료: $existing_subnet"
    fi
    
    # VPC 삭제
    if [ -n "$existing_vpc" ]; then
        show_info "VPC 삭제 중: $existing_vpc"
        aws ec2 delete-vpc --vpc-id "$existing_vpc" >/dev/null 2>&1 || true
        show_success "VPC 삭제 완료: $existing_vpc"
    fi
    
    if [ -z "$existing_rt" ] && [ -z "$existing_igw" ] && [ -z "$existing_subnet" ] && [ -z "$existing_vpc" ]; then
        show_info "정리할 네트워크 리소스가 없습니다"
    fi
    echo ""
    
    # 완료 요약
    echo "==========================================="
    
    # 실제 삭제된 리소스 확인 및 요약
    echo ""
    show_info "🎉 실제 삭제된 리소스 확인:"
    
    local deleted_count=0
    
    # EC2 인스턴스 삭제 확인
    local instance_check=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-LogServer" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)
    if [ "$instance_check" = "None" ] || [ -z "$instance_check" ]; then
        echo "  ✅ EC2 인스턴스 삭제: CloudArchitect-Lab-LogServer"
        deleted_count=$((deleted_count + 1))
    fi
    
    # VPC 삭제 확인
    local vpc_check=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    if [ "$vpc_check" = "None" ] || [ -z "$vpc_check" ]; then
        echo "  ✅ VPC 삭제: CloudArchitect-Lab-VPC"
        deleted_count=$((deleted_count + 1))
    fi
    
    # Internet Gateway 삭제 확인
    local igw_check=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ "$igw_check" = "None" ] || [ -z "$igw_check" ]; then
        echo "  ✅ Internet Gateway 삭제: CloudArchitect-Lab-IGW"
        deleted_count=$((deleted_count + 1))
    fi
    
    # Subnet 삭제 확인
    local subnet_check=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
    if [ "$subnet_check" = "None" ] || [ -z "$subnet_check" ]; then
        echo "  ✅ Public Subnet 삭제: CloudArchitect-Lab-Public-Subnet"
        deleted_count=$((deleted_count + 1))
    fi
    
    # Security Group 삭제 확인
    local sg_check=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=CloudArchitect-Lab-Web-SG" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    if [ "$sg_check" = "None" ] || [ -z "$sg_check" ]; then
        echo "  ✅ Security Group 삭제: CloudArchitect-Lab-Web-SG"
        deleted_count=$((deleted_count + 1))
    fi
    
    # IAM Role 삭제 확인
    local role_check=$(aws iam get-role --role-name "CloudArchitect-Lab-CloudWatchAgent-Role" --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$role_check" = "None" ] || [ -z "$role_check" ]; then
        echo "  ✅ IAM Role 삭제: CloudArchitect-Lab-CloudWatchAgent-Role"
        deleted_count=$((deleted_count + 1))
    fi
    
    # CloudWatch Logs 그룹 삭제 확인
    local access_log_check=$(aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/nginx/access" --query 'logGroups[0].logGroupName' --output text 2>/dev/null)
    if [ "$access_log_check" = "None" ] || [ -z "$access_log_check" ]; then
        echo "  ✅ CloudWatch Log Group 삭제: /aws/ec2/nginx/access"
        deleted_count=$((deleted_count + 1))
    fi
    
    local error_log_check=$(aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/nginx/error" --query 'logGroups[0].logGroupName' --output text 2>/dev/null)
    if [ "$error_log_check" = "None" ] || [ -z "$error_log_check" ]; then
        echo "  ✅ CloudWatch Log Group 삭제: /aws/ec2/nginx/error"
        deleted_count=$((deleted_count + 1))
    fi
    
    echo ""
    if [ "$deleted_count" -gt 0 ]; then
        echo "💰 총 $deleted_count 개 유형의 리소스가 정리되었습니다!"
    else
        echo "ℹ️ 정리할 Lab11 리소스가 없었습니다."
    fi
    
    echo ""
    echo "💰 비용 절약"
    echo "• 모든 Lab11 관련 리소스가 정리되어 추가 비용이 발생하지 않습니다"
    echo "• EC2 인스턴스 및 CloudWatch Logs 저장 비용 절약"
    echo ""
    
    echo "🔍 필수 확인 사항"
    echo "⚠️ AWS 콘솔에서 다음 항목들이 완전히 삭제되었는지 반드시 확인하세요:"
    echo "• EC2: 인스턴스가 terminated 상태인지 확인"
    echo "• VPC: CloudArchitect-Lab-VPC 삭제 확인"
    echo "• CloudWatch Logs: nginx 관련 로그 그룹 삭제 확인"
    echo "• IAM: CloudArchitect-Lab-CloudWatchAgent-Role 삭제 확인"
    echo ""
    
    echo "⚠️ 만약 일부 리소스가 남아있다면 AWS 콘솔에서 수동으로 삭제해주세요."
    echo "⚠️ 특히 VPC 삭제가 실패한 경우, 의존성 리소스를 먼저 정리해야 합니다."
    echo ""
    
    echo "=========================================="
    echo "전체 실행 시간: 약 5-8분 (EC2 인스턴스 종료가 가장 오래 걸림)"
    echo ""
    
    show_success "✅ Lab11 정리 스크립트 실행 완료"
}

# 스크립트 실행
main "$@"