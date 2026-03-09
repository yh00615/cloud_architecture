#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Week 12-3: AWS Backup 서비스 - 자동화된 백업 및 복원 정리
# ================================
# 목적: Week 12-3에서 생성된 모든 AWS 리소스를 안전하게 정리
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

# 기존 리소스 확인 및 표시
check_existing_resources() {
    echo ""
    show_info "기존 리소스 상태를 확인합니다..."
    echo ""
    
    # VPC 확인
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        echo "🔍 발견된 Week 12-3 리소스:"
        
        # EC2 인스턴스 확인
        EC2_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=CloudArchitect-Lab-TestInstance" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query 'Reservations[0].Instances[0].InstanceId' --output text 2>/dev/null)
        if [ "$EC2_INSTANCE_ID" != "None" ] && [ -n "$EC2_INSTANCE_ID" ]; then
            echo "✅ EC2 Instance: CloudArchitect-Lab-TestInstance ($EC2_INSTANCE_ID)"
        fi
        
        # EC2 보안 그룹 확인
        EC2_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
        if [ "$EC2_SG_ID" != "None" ] && [ -n "$EC2_SG_ID" ]; then
            echo "✅ EC2 Security Group: CloudArchitect-Lab-EC2-SG ($EC2_SG_ID)"
        fi
        
        # Route Table 확인
        PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-RT" "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
        if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
            echo "✅ Public Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID)"
        fi
        
        # Public Subnet 확인
        PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
        if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
            echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID)"
        fi
        
        # Internet Gateway 확인
        IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
        if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
            echo "✅ Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID)"
        fi
        
        echo "✅ VPC: CloudArchitect-Lab-VPC ($VPC_ID)"
    else
        echo "ℹ️ 삭제할 Week 12-3 VPC 리소스가 없습니다."
    fi
    
    # IAM Backup Role 확인
    BACKUP_ROLE_NAME=$(aws iam get-role --role-name CloudArchitect-Lab-BackupRole --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$BACKUP_ROLE_NAME" != "None" ] && [ -n "$BACKUP_ROLE_NAME" ]; then
        echo "✅ IAM Backup Role: CloudArchitect-Lab-BackupRole"
    fi
    
    echo ""
    echo "🗑️ 삭제 계획:"
    echo ""
    
    # EC2 인스턴스 상태 표시
    if [ "$EC2_INSTANCE_ID" != "None" ] && [ -n "$EC2_INSTANCE_ID" ]; then
        echo "  🔥 EC2 Instance: CloudArchitect-Lab-TestInstance ($EC2_INSTANCE_ID) - 삭제 예정"
    else
        echo "  ⚪ EC2 Instance: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Security Group 상태 표시
    if [ "$EC2_SG_ID" != "None" ] && [ -n "$EC2_SG_ID" ]; then
        echo "  🔥 Security Group: CloudArchitect-Lab-EC2-SG ($EC2_SG_ID) - 삭제 예정"
    else
        echo "  ⚪ Security Group: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Route Table 상태 표시
    if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
        echo "  🔥 Route Table: CloudArchitect-Lab-Public-RT ($PUBLIC_RT_ID) - 삭제 예정"
    else
        echo "  ⚪ Route Table: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Internet Gateway 상태 표시
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        echo "  🔥 Internet Gateway: CloudArchitect-Lab-IGW ($IGW_ID) - 삭제 예정"
    else
        echo "  ⚪ Internet Gateway: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # Public Subnet 상태 표시
    if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
        echo "  🔥 Public Subnet: CloudArchitect-Lab-Public-Subnet ($PUBLIC_SUBNET_ID) - 삭제 예정"
    else
        echo "  ⚪ Public Subnet: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # VPC 상태 표시
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        echo "  🔥 VPC: CloudArchitect-Lab-VPC ($VPC_ID) - 삭제 예정"
    else
        echo "  ⚪ VPC: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    # IAM Backup Role 상태 표시
    if [ "$BACKUP_ROLE_NAME" != "None" ] && [ -n "$BACKUP_ROLE_NAME" ]; then
        echo "  🔥 IAM Backup Role: CloudArchitect-Lab-BackupRole - 삭제 예정"
    else
        echo "  ⚪ IAM Backup Role: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    echo ""
    echo "⚠️ 이 작업은 위의 모든 리소스를 영구적으로 삭제합니다"
    echo "🔍 삭제 완료 후 AWS 콘솔에서 리소스가 정말 삭제되었는지 다시 한 번 확인하세요"
    echo "🔄 삭제는 의존성 순서에 따라 안전하게 진행됩니다"
    echo "⚠️ AWS Backup 관련 리소스는 별도로 정리해야 합니다"
    echo ""
}

# 사용자 확인
confirm_deletion() {
    read -p "위 리소스들을 모두 삭제하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Week 12-3 정리가 취소되었습니다."
        exit 0
    fi
    show_info "리소스 삭제를 시작합니다..."
    echo ""
}

# EC2 인스턴스 정리
cleanup_ec2_instances() {
    show_info "EC2 인스턴스 정리 중..."
    
    if [ "$EC2_INSTANCE_ID" != "None" ] && [ -n "$EC2_INSTANCE_ID" ]; then
        show_info "EC2 인스턴스 종료 중... ($EC2_INSTANCE_ID)"
        aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_ID >/dev/null 2>&1
        
        show_info "EC2 인스턴스 종료 대기 중... (최대 3분 소요)"
        aws ec2 wait instance-terminated --instance-ids $EC2_INSTANCE_ID
        
        show_success "EC2 인스턴스 삭제 완료"
    else
        show_info "삭제할 EC2 인스턴스가 없습니다."
    fi
    
    show_success "EC2 인스턴스 정리 완료"
}

# 보안 그룹 정리
cleanup_security_groups() {
    show_info "보안 그룹 정리 중..."
    
    if [ "$EC2_SG_ID" != "None" ] && [ -n "$EC2_SG_ID" ]; then
        show_info "EC2 보안 그룹 삭제 중... ($EC2_SG_ID)"
        aws ec2 delete-security-group --group-id $EC2_SG_ID >/dev/null 2>&1
        show_success "EC2 보안 그룹 삭제 완료"
    else
        show_info "삭제할 EC2 보안 그룹이 없습니다."
    fi
    
    show_success "보안 그룹 정리 완료"
}

# Route Table 정리
cleanup_route_tables() {
    show_info "Route Table 정리 중..."
    
    if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
        # 서브넷 연결 해제
        if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
            show_info "Public Route Table 서브넷 연결 해제 중..."
            local association_id=$(aws ec2 describe-route-tables --route-table-ids $PUBLIC_RT_ID --query 'RouteTables[0].Associations[?SubnetId==`'$PUBLIC_SUBNET_ID'`].RouteTableAssociationId' --output text 2>/dev/null)
            if [ "$association_id" != "None" ] && [ -n "$association_id" ]; then
                aws ec2 disassociate-route-table --association-id $association_id >/dev/null 2>&1
            fi
        fi
        
        show_info "Public Route Table 삭제 중... ($PUBLIC_RT_ID)"
        aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID >/dev/null 2>&1
        show_success "Public Route Table 삭제 완료"
    else
        show_info "삭제할 Route Table이 없습니다."
    fi
    
    show_success "Route Table 정리 완료"
}

# Internet Gateway 정리
cleanup_internet_gateway() {
    show_info "Internet Gateway 정리 중..."
    
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        show_info "Internet Gateway VPC 연결 해제 중... ($IGW_ID)"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID >/dev/null 2>&1
        show_success "VPC 연결 해제 완료"
        
        show_info "Internet Gateway 삭제 중..."
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID >/dev/null 2>&1
        show_success "Internet Gateway 삭제 완료"
    else
        show_info "삭제할 Internet Gateway가 없습니다."
    fi
    
    show_success "Internet Gateway 정리 완료"
}

# Subnet 정리
cleanup_subnets() {
    show_info "Subnet 정리 중..."
    
    if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
        show_info "Public Subnet 삭제 중... ($PUBLIC_SUBNET_ID)"
        aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID >/dev/null 2>&1
        show_success "Public Subnet 삭제 완료"
    else
        show_info "삭제할 Public Subnet이 없습니다."
    fi
    
    show_success "Subnet 정리 완료"
}

# VPC 정리
cleanup_vpc() {
    show_info "VPC 정리 중..."
    
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        show_info "VPC 삭제 중... ($VPC_ID)"
        aws ec2 delete-vpc --vpc-id $VPC_ID >/dev/null 2>&1
        show_success "VPC 삭제 완료"
    else
        show_info "삭제할 VPC가 없습니다."
    fi
    
    show_success "VPC 정리 완료"
}

# IAM Backup Role 정리
cleanup_backup_role() {
    show_info "IAM Backup Role 정리 중..."
    
    if [ "$BACKUP_ROLE_NAME" != "None" ] && [ -n "$BACKUP_ROLE_NAME" ]; then
        # 연결된 정책 해제
        show_info "IAM 정책 연결 해제 중..."
        aws iam detach-role-policy --role-name $BACKUP_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup >/dev/null 2>&1
        aws iam detach-role-policy --role-name $BACKUP_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores >/dev/null 2>&1
        
        show_info "IAM Backup Role 삭제 중... ($BACKUP_ROLE_NAME)"
        aws iam delete-role --role-name $BACKUP_ROLE_NAME >/dev/null 2>&1
        show_success "IAM Backup Role 삭제 완료"
    else
        show_info "삭제할 IAM Backup Role이 없습니다."
    fi
    
    show_success "IAM Backup Role 정리 완료"
}

# 완료 요약 표시
show_cleanup_summary() {
    echo ""
    show_success "🎉 Week 12-3 리소스 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 삭제 완료된 리소스:"
    if [ "$EC2_INSTANCE_ID" != "None" ] && [ -n "$EC2_INSTANCE_ID" ]; then
        echo "✅ EC2 Instance: CloudArchitect-Lab-TestInstance"
    fi
    if [ "$EC2_SG_ID" != "None" ] && [ -n "$EC2_SG_ID" ]; then
        echo "✅ EC2 Security Group: CloudArchitect-Lab-EC2-SG"
    fi
    if [ "$PUBLIC_RT_ID" != "None" ] && [ -n "$PUBLIC_RT_ID" ]; then
        echo "✅ Public Route Table: CloudArchitect-Lab-Public-RT"
    fi
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        echo "✅ Internet Gateway: CloudArchitect-Lab-IGW"
    fi
    if [ "$PUBLIC_SUBNET_ID" != "None" ] && [ -n "$PUBLIC_SUBNET_ID" ]; then
        echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet"
    fi
    if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
        echo "✅ VPC: CloudArchitect-Lab-VPC"
    fi
    if [ "$BACKUP_ROLE_NAME" != "None" ] && [ -n "$BACKUP_ROLE_NAME" ]; then
        echo "✅ IAM Backup Role: CloudArchitect-Lab-BackupRole"
    fi
    echo ""
    
    echo "💰 비용 절약"
    echo "• 모든 Week 12-3 관련 리소스가 정리되어 추가 비용이 발생하지 않습니다"
    echo "• EC2 및 IAM 관련 리소스 정리 완료"
    echo ""
    
    echo "🔍 필수 확인 사항"
    show_warning "AWS 콘솔에서 다음 항목들이 완전히 삭제되었는지 반드시 확인하세요:"
    echo "• EC2 Instances: CloudArchitect-Lab-TestInstance"
    echo "• Security Groups: CloudArchitect-Lab-EC2-SG"
    echo "• IAM Roles: CloudArchitect-Lab-BackupRole"
    echo "• AWS Backup: 백업 볼트, 백업 계획, 복구 포인트 (수동 생성한 경우)"
    echo ""
    
    show_warning "만약 일부 리소스가 남아있다면 AWS 콘솔에서 수동으로 삭제해주세요."
    show_warning "특히 AWS Backup 관련 리소스는 별도로 정리해야 합니다."
    echo ""
    
    echo "=========================================="
    echo "전체 실행 시간: 약 5분 (EC2 인스턴스 종료가 가장 오래 걸림)"
}

# 메인 실행 함수
main() {
    # 헤더 표시
    echo "================================"
    echo "Week 12-3: AWS Backup 서비스 - 자동화된 백업 및 복원 정리"
    echo "================================"
    echo "목적: Week 12-3에서 생성된 모든 AWS 리소스를 안전하게 정리"
    echo "================================"
    
    # 기존 리소스 확인
    check_existing_resources
    
    # 삭제할 리소스가 없으면 종료
    if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
        if [ "$BACKUP_ROLE_NAME" = "None" ] || [ -z "$BACKUP_ROLE_NAME" ]; then
            show_info "삭제할 Week 12-3 리소스가 없습니다."
            exit 0
        fi
    fi
    
    # 사용자 확인
    confirm_deletion
    
    # 리소스 삭제 (단계별)
    show_progress 1 7 "EC2 인스턴스 정리 중..."
    cleanup_ec2_instances
    echo ""
    
    show_progress 2 7 "보안 그룹 정리 중..."
    cleanup_security_groups
    echo ""
    
    show_progress 3 7 "Route Table 정리 중..."
    cleanup_route_tables
    echo ""
    
    show_progress 4 7 "Internet Gateway 정리 중..."
    cleanup_internet_gateway
    echo ""
    
    show_progress 5 7 "Subnet 정리 중..."
    cleanup_subnets
    echo ""
    
    show_progress 6 7 "VPC 정리 중..."
    cleanup_vpc
    echo ""
    
    show_progress 7 7 "IAM Backup Role 정리 중..."
    cleanup_backup_role
    echo ""
    
    # 완료 요약 표시
    show_cleanup_summary
}

# 스크립트 실행
main "$@"