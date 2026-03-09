#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Lab10: CloudWatch 지표 모니터링 및 경보 설정 - 학생용 리소스 정리
# ================================
# 목적: Lab10에서 생성된 모든 AWS 리소스를 안전하게 정리
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

# AWS CLI 프로필 및 리전 확인
get_aws_account_info() {
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    region=$(aws configure get region 2>/dev/null)
    
    if [ -z "$account_id" ]; then
        show_error "AWS 자격 증명을 확인할 수 없습니다."
        show_info "다음 명령어로 AWS CLI를 설정해주세요:"
        echo "  aws configure"
        exit 1
    fi
    
    echo "$account_id:$region"
}

# 학생이 생성한 CloudWatch 리소스 정리 안내
cleanup_student_cloudwatch_resources() {
    show_info "학생이 생성한 CloudWatch 리소스 확인 중..."
    
    # CloudWatch 알람 확인
    student_alarms=$(aws cloudwatch describe-alarms --query 'MetricAlarms[?contains(AlarmName, `Lab`) || contains(AlarmName, `Student`)].AlarmName' --output text 2>/dev/null || echo "")
    
    # CloudWatch 대시보드 확인
    student_dashboards=$(aws cloudwatch list-dashboards --query 'DashboardEntries[?contains(DashboardName, `Lab`) || contains(DashboardName, `Student`)].DashboardName' --output text 2>/dev/null || echo "")
    
    # SNS 토픽 확인
    student_topics=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `Lab`) || contains(TopicArn, `Student`)].TopicArn' --output text 2>/dev/null || echo "")
    
    if [ -n "$student_alarms" ] || [ -n "$student_dashboards" ] || [ -n "$student_topics" ]; then
        show_warning "학생이 생성한 CloudWatch 리소스가 발견되었습니다:"
        
        if [ -n "$student_alarms" ]; then
            echo "  📊 CloudWatch Alarms: $student_alarms"
        fi
        
        if [ -n "$student_dashboards" ]; then
            echo "  📈 CloudWatch Dashboards: $student_dashboards"
        fi
        
        if [ -n "$student_topics" ]; then
            echo "  📧 SNS Topics: $student_topics"
        fi
        
        echo ""
        show_info "이러한 리소스들은 AWS 콘솔에서 수동으로 삭제해주세요:"
        echo "  1. CloudWatch → Alarms → 생성한 알람 선택 → Delete"
        echo "  2. CloudWatch → Dashboards → 생성한 대시보드 선택 → Delete"
        echo "  3. SNS → Topics → 생성한 토픽 선택 → Delete"
        echo ""
    else
        show_success "학생이 생성한 CloudWatch 리소스가 없습니다"
    fi
}

# EC2 인스턴스 정리
cleanup_ec2_instance() {
    show_info "EC2 인스턴스 정리 중..."
    
    # EC2 인스턴스 확인 및 삭제
    instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-MonitoringServer" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null)
    
    if [ "$instance_id" != "None" ] && [ -n "$instance_id" ]; then
        show_info "EC2 인스턴스 종료 중: $instance_id"
        aws ec2 terminate-instances --instance-ids "$instance_id" >/dev/null 2>&1
        
        show_info "EC2 인스턴스 종료 대기 중... (최대 3분)"
        aws ec2 wait instance-terminated --instance-ids "$instance_id" --cli-read-timeout 180 --cli-connect-timeout 60 2>/dev/null || true
        
        show_success "EC2 인스턴스 종료 완료: $instance_id"
    else
        show_info "EC2 인스턴스가 존재하지 않습니다"
    fi
}

# Security Group 정리
cleanup_security_group() {
    show_info "Security Group 정리 중..."
    
    # VPC ID 확인
    vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
        # Web Security Group 삭제
        sg_id=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=CloudArchitect-Lab-Web-SG" "Name=vpc-id,Values=$vpc_id" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        if [ "$sg_id" != "None" ] && [ -n "$sg_id" ]; then
            show_info "Security Group 삭제 중: CloudArchitect-Lab-Web-SG ($sg_id)"
            aws ec2 delete-security-group --group-id "$sg_id" >/dev/null 2>&1 || true
            show_success "Security Group 삭제 완료: CloudArchitect-Lab-Web-SG"
        else
            show_info "Security Group이 존재하지 않습니다: CloudArchitect-Lab-Web-SG"
        fi
    fi
}

# IAM 역할 및 Instance Profile 정리
cleanup_iam_resources() {
    show_info "IAM 리소스 정리 중..."
    
    role_name="CloudArchitect-Lab-CloudWatchRole"
    profile_name="CloudArchitect-Lab-CloudWatchProfile"
    
    # Instance Profile에서 역할 제거 및 삭제
    existing_profile=$(aws iam get-instance-profile --instance-profile-name "$profile_name" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_profile" != "None" ] && [ -n "$existing_profile" ]; then
        show_info "Instance Profile에서 역할 제거 중..."
        aws iam remove-role-from-instance-profile --instance-profile-name "$profile_name" --role-name "$role_name" >/dev/null 2>&1 || true
        
        show_info "Instance Profile 삭제 중: $profile_name"
        aws iam delete-instance-profile --instance-profile-name "$profile_name" >/dev/null 2>&1 || true
        show_success "Instance Profile 삭제 완료: $profile_name"
    else
        show_info "Instance Profile이 존재하지 않습니다: $profile_name"
    fi
    
    # IAM 역할에서 정책 분리 및 삭제
    existing_role=$(aws iam get-role --role-name "$role_name" --query 'Role.RoleName' --output text 2>/dev/null || echo "None")
    
    if [ "$existing_role" != "None" ] && [ -n "$existing_role" ]; then
        show_info "IAM 역할에서 정책 분리 중..."
        aws iam detach-role-policy --role-name "$role_name" --policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" >/dev/null 2>&1 || true
        
        show_info "IAM 역할 삭제 중: $role_name"
        aws iam delete-role --role-name "$role_name" >/dev/null 2>&1 || true
        show_success "IAM 역할 삭제 완료: $role_name"
    else
        show_info "IAM 역할이 존재하지 않습니다: $role_name"
    fi
}

# VPC 관련 리소스 정리 (다른 실습과 공유하므로 주의)
cleanup_vpc_resources() {
    show_info "VPC 리소스 확인 중..."
    
    # VPC ID 확인
    vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
        # 다른 실습에서 사용 중인지 확인
        other_instances=$(aws ec2 describe-instances \
            --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
            --query 'Reservations[*].Instances[?!contains(Tags[?Key==`Name`].Value, `CloudArchitect-Lab-MonitoringServer`)].InstanceId' \
            --output text 2>/dev/null)
        
        if [ -n "$other_instances" ] && [ "$other_instances" != "None" ]; then
            show_warning "VPC가 다른 인스턴스에서 사용 중이므로 VPC 리소스를 유지합니다"
            show_info "VPC 리소스는 다른 실습 cleanup 시 정리됩니다"
        else
            show_info "VPC 리소스가 더 이상 사용되지 않으므로 정리합니다"
            
            # Internet Gateway 분리 및 삭제
            igw_id=$(aws ec2 describe-internet-gateways \
                --filters "Name=attachment.vpc-id,Values=$vpc_id" \
                --query 'InternetGateways[0].InternetGatewayId' \
                --output text 2>/dev/null)
            
            if [ "$igw_id" != "None" ] && [ -n "$igw_id" ]; then
                show_info "Internet Gateway 분리 중: $igw_id"
                aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" >/dev/null 2>&1 || true
                show_info "Internet Gateway 삭제 중: $igw_id"
                aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" >/dev/null 2>&1 || true
                show_success "Internet Gateway 삭제 완료"
            fi
            
            # 서브넷 삭제
            subnet_ids=$(aws ec2 describe-subnets \
                --filters "Name=vpc-id,Values=$vpc_id" \
                --query 'Subnets[*].SubnetId' \
                --output text 2>/dev/null)
            
            if [ -n "$subnet_ids" ] && [ "$subnet_ids" != "None" ]; then
                for subnet_id in $subnet_ids; do
                    show_info "서브넷 삭제 중: $subnet_id"
                    aws ec2 delete-subnet --subnet-id "$subnet_id" >/dev/null 2>&1 || true
                done
                show_success "서브넷 삭제 완료"
            fi
            
            # 라우팅 테이블 삭제 (메인 라우팅 테이블 제외)
            route_table_ids=$(aws ec2 describe-route-tables \
                --filters "Name=vpc-id,Values=$vpc_id" \
                --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' \
                --output text 2>/dev/null)
            
            if [ -n "$route_table_ids" ] && [ "$route_table_ids" != "None" ]; then
                for rt_id in $route_table_ids; do
                    show_info "라우팅 테이블 삭제 중: $rt_id"
                    aws ec2 delete-route-table --route-table-id "$rt_id" >/dev/null 2>&1 || true
                done
                show_success "라우팅 테이블 삭제 완료"
            fi
            
            # VPC 삭제
            show_info "VPC 삭제 중: $vpc_id"
            aws ec2 delete-vpc --vpc-id "$vpc_id" >/dev/null 2>&1 || true
            show_success "VPC 삭제 완료: CloudArchitect-Lab-VPC"
        fi
    else
        show_info "VPC가 존재하지 않습니다"
    fi
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab10 CloudWatch 실습 리소스 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 삭제 완료된 리소스:"
    echo "✅ EC2 Instance: CloudArchitect-Lab-MonitoringServer"
    echo "✅ Security Group: CloudArchitect-Lab-Web-SG"
    echo "✅ IAM Role: CloudArchitect-Lab-CloudWatchRole"
    echo "✅ Instance Profile: CloudArchitect-Lab-CloudWatchProfile"
    echo ""
    
    echo "💰 비용 절약"
    echo "• 모든 Lab10 관련 리소스가 정리되어 추가 비용이 발생하지 않습니다"
    echo "• EC2 인스턴스 과금 중단"
    echo ""
    
    echo "🔍 필수 확인 사항"
    echo "⚠️ AWS 콘솔에서 다음 항목들이 완전히 삭제되었는지 반드시 확인하세요:"
    echo "• EC2 → Instances → CloudArchitect-Lab-MonitoringServer 종료됨 확인"
    echo "• EC2 → Security Groups → CloudArchitect-Lab-Web-SG 없음 확인"
    echo "• IAM → Roles → CloudArchitect-Lab-CloudWatchRole 없음 확인"
    echo ""
    
    echo "📚 실습에서 생성한 CloudWatch 리소스 정리:"
    echo "⚠️ 다음 리소스들은 AWS 콘솔에서 수동으로 삭제해주세요:"
    echo "• CloudWatch → Alarms → 생성한 모든 알람"
    echo "• CloudWatch → Dashboards → 생성한 모든 대시보드"
    echo "• SNS → Topics → 생성한 모든 토픽 및 구독"
    echo ""
    
    echo "ℹ️ VPC 리소스 정보:"
    echo "• VPC 및 네트워크 리소스는 다른 실습과 공유되므로 유지됩니다"
    echo "• 필요시 다른 실습의 cleanup 스크립트로 VPC 리소스를 정리하세요"
    
    echo ""
    echo "⚠️ 만약 일부 리소스가 남아있다면 AWS 콘솔에서 수동으로 삭제해주세요."
    echo ""
    echo "=========================================="
    echo "전체 실행 시간: 약 5-8분 (EC2 인스턴스 종료가 가장 오래 걸림)"
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
    
    echo "================================"
    echo "Lab10: CloudWatch 지표 모니터링 및 경보 설정 - 학생용 리소스 정리"
    echo "================================"
    echo "목적: Lab10에서 생성된 모든 AWS 리소스를 안전하게 정리"
    echo "예상 시간: 약 8분"
    echo "예상 비용: 모든 과금 리소스가 삭제됩니다"
    echo "================================"
    echo ""
    
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo ""
    
    # 기존 리소스 상태 확인
    show_info "기존 리소스 상태를 확인합니다..."
    
    # 리소스 확인
    existing_instance=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-MonitoringServer" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text 2>/dev/null || echo "None")
    
    existing_role=$(aws iam get-role --role-name "CloudArchitect-Lab-CloudWatchRole" --query 'Role.RoleName' --output text 2>/dev/null || echo "None")
    existing_profile=$(aws iam get-instance-profile --instance-profile-name "CloudArchitect-Lab-CloudWatchProfile" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "None")
    
    echo ""
    show_info "🔍 발견된 Lab10 리소스:"
    
    if [ "$existing_instance" != "None" ] && [ -n "$existing_instance" ]; then
        echo "✅ EC2 Instance: CloudArchitect-Lab-MonitoringServer ($existing_instance)"
    else
        echo "⚪ EC2 Instance: 이미 종료됨 또는 존재하지 않음"
    fi
    
    if [ "$existing_role" != "None" ] && [ -n "$existing_role" ]; then
        echo "✅ IAM Role: CloudArchitect-Lab-CloudWatchRole"
    else
        echo "⚪ IAM Role: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    if [ "$existing_profile" != "None" ] && [ -n "$existing_profile" ]; then
        echo "✅ Instance Profile: CloudArchitect-Lab-CloudWatchProfile"
    else
        echo "⚪ Instance Profile: 이미 삭제됨 또는 존재하지 않음"
    fi
    
    echo ""
    echo "⚠️ 주의사항:"
    echo "• 리소스 삭제는 되돌릴 수 없습니다"
    echo "• 의존성 순서에 따라 단계적으로 삭제됩니다"
    echo "• EC2 인스턴스 종료 시 모든 데이터가 삭제됩니다"
    echo ""
    
    read -p "위 리소스들을 삭제하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab10 리소스 정리가 취소되었습니다."
        exit 0
    fi
    
    show_info "리소스 삭제를 시작합니다..."
    echo ""
    
    # 1단계: 학생이 생성한 CloudWatch 리소스 확인
    show_progress 1 5 "학생 생성 CloudWatch 리소스 확인 중..."
    cleanup_student_cloudwatch_resources
    echo ""
    
    # 2단계: EC2 인스턴스 정리
    show_progress 2 5 "EC2 인스턴스 정리 중..."
    cleanup_ec2_instance
    echo ""
    
    # 3단계: Security Group 정리
    show_progress 3 5 "Security Group 정리 중..."
    cleanup_security_group
    echo ""
    
    # 4단계: IAM 리소스 정리
    show_progress 4 5 "IAM 리소스 정리 중..."
    cleanup_iam_resources
    echo ""
    
    # 5단계: VPC 리소스 확인
    show_progress 5 5 "VPC 리소스 확인 중..."
    cleanup_vpc_resources
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"