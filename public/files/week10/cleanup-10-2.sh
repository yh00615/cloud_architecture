#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab15: Amazon ECS 서비스 배포 - 컨테이너 오케스트레이션 관리 정리
# 목적: Lab15에서 생성된 ECR 리포지토리를 안전하게 정리
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

show_important() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

show_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

# VPC 인프라 정리 함수 (Demo04 기반)
cleanup_vpc_infrastructure() {
    show_info "VPC 네트워크 인프라 정리 중..."
    
    local vpc_name="CloudArchitect-Lab-VPC"
    
    # VPC 확인
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=$vpc_name" "Name=tag:Lab,Values=Lab15" \
        --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    
    if [ "$vpc_id" = "None" ] || [ -z "$vpc_id" ]; then
        show_info "삭제할 VPC가 없습니다: $vpc_name"
        return 0
    fi
    
    show_info "VPC 발견: $vpc_name ($vpc_id)"
    
    # 1. Security Groups 삭제
    cleanup_security_groups "$vpc_id"
    
    # 2. NAT Gateway 삭제
    cleanup_nat_gateways "$vpc_id"
    
    # 3. Route Tables 삭제
    cleanup_route_tables "$vpc_id"
    
    # 4. Internet Gateway 삭제
    cleanup_internet_gateways "$vpc_id"
    
    # 5. Subnets 삭제
    cleanup_subnets "$vpc_id"
    
    # 6. VPC 삭제
    cleanup_vpc "$vpc_id" "$vpc_name"
}

# Security Groups 삭제
cleanup_security_groups() {
    local vpc_id=$1
    show_info "Security Groups 삭제 중..."
    
    local sg_ids=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Lab,Values=Lab15" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null)
    
    if [ -n "$sg_ids" ] && [ "$sg_ids" != "None" ]; then
        for sg_id in $sg_ids; do
            aws ec2 delete-security-group --group-id "$sg_id" >/dev/null 2>&1
            show_success "Security Group 삭제: $sg_id"
        done
    fi
}

# NAT Gateways 삭제
cleanup_nat_gateways() {
    local vpc_id=$1
    show_info "NAT Gateways 삭제 중..."
    
    local nat_gw_ids=$(aws ec2 describe-nat-gateways \
        --filter "Name=vpc-id,Values=$vpc_id" "Name=tag:Lab,Values=Lab15" \
        --query 'NatGateways[?State==`available`].NatGatewayId' --output text 2>/dev/null)
    
    if [ -n "$nat_gw_ids" ] && [ "$nat_gw_ids" != "None" ]; then
        for nat_id in $nat_gw_ids; do
            # EIP 정보 가져오기
            local eip_id=$(aws ec2 describe-nat-gateways --nat-gateway-ids "$nat_id" \
                --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text 2>/dev/null)
            
            # NAT Gateway 삭제
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" >/dev/null 2>&1
            show_success "NAT Gateway 삭제: $nat_id"
            
            # NAT Gateway 삭제 대기
            show_info "NAT Gateway 삭제 대기 중..."
            aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$nat_id" 2>/dev/null || sleep 30
            
            # EIP 해제
            if [ -n "$eip_id" ] && [ "$eip_id" != "None" ]; then
                aws ec2 release-address --allocation-id "$eip_id" >/dev/null 2>&1
                show_success "Elastic IP 해제: $eip_id"
            fi
        done
    fi
}

# Route Tables 삭제
cleanup_route_tables() {
    local vpc_id=$1
    show_info "Route Tables 삭제 중..."
    
    local rt_ids=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Lab,Values=Lab15" \
        --query 'RouteTables[].RouteTableId' --output text 2>/dev/null)
    
    if [ -n "$rt_ids" ] && [ "$rt_ids" != "None" ]; then
        for rt_id in $rt_ids; do
            aws ec2 delete-route-table --route-table-id "$rt_id" >/dev/null 2>&1
            show_success "Route Table 삭제: $rt_id"
        done
    fi
}

# Internet Gateways 삭제
cleanup_internet_gateways() {
    local vpc_id=$1
    show_info "Internet Gateways 삭제 중..."
    
    local igw_ids=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" "Name=tag:Lab,Values=Lab15" \
        --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null)
    
    if [ -n "$igw_ids" ] && [ "$igw_ids" != "None" ]; then
        for igw_id in $igw_ids; do
            # VPC에서 분리
            aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" >/dev/null 2>&1
            # IGW 삭제
            aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" >/dev/null 2>&1
            show_success "Internet Gateway 삭제: $igw_id"
        done
    fi
}

# Subnets 삭제
cleanup_subnets() {
    local vpc_id=$1
    show_info "Subnets 삭제 중..."
    
    local subnet_ids=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Lab,Values=Lab15" \
        --query 'Subnets[].SubnetId' --output text 2>/dev/null)
    
    if [ -n "$subnet_ids" ] && [ "$subnet_ids" != "None" ]; then
        for subnet_id in $subnet_ids; do
            aws ec2 delete-subnet --subnet-id "$subnet_id" >/dev/null 2>&1
            show_success "Subnet 삭제: $subnet_id"
        done
    fi
}

# VPC 삭제
cleanup_vpc() {
    local vpc_id=$1
    local vpc_name=$2
    show_info "VPC 삭제 중: $vpc_name"
    
    if aws ec2 delete-vpc --vpc-id "$vpc_id" >/dev/null 2>&1; then
        show_success "VPC 삭제 완료: $vpc_name ($vpc_id)"
    else
        show_error "VPC 삭제 실패: $vpc_name ($vpc_id)"
    fi
}

# ECR 리포지토리 정리 함수
cleanup_ecr_repository() {
    show_info "ECR 리포지토리 정리 중..."
    
    local repo_name="cloudarchitect-lab-webapp"
    
    # 기존 리포지토리 확인
    local existing_repo=$(aws ecr describe-repositories --repository-names "$repo_name" --query 'repositories[0].repositoryName' --output text 2>/dev/null)
    
    if [ "$existing_repo" != "$repo_name" ] || [ -z "$existing_repo" ]; then
        show_info "삭제할 ECR 리포지토리가 없습니다: $repo_name"
        return 0
    fi
    
    show_info "ECR 리포지토리 발견: $repo_name"
    
    # 리포지토리 내 이미지 확인
    local image_count=$(aws ecr list-images --repository-name "$repo_name" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
    
    if [ "$image_count" -gt 0 ]; then
        show_info "리포지토리 내 이미지 삭제 중... ($image_count개)"
        
        # 모든 이미지 삭제
        local image_digests=$(aws ecr list-images --repository-name "$repo_name" --query 'imageIds[*].imageDigest' --output text 2>/dev/null)
        
        if [ -n "$image_digests" ] && [ "$image_digests" != "None" ]; then
            for digest in $image_digests; do
                aws ecr batch-delete-image --repository-name "$repo_name" --image-ids imageDigest="$digest" >/dev/null 2>&1
            done
            show_success "리포지토리 내 이미지 삭제 완료"
        fi
    else
        show_info "리포지토리가 비어있습니다"
    fi
    
    # 리포지토리 삭제
    show_info "ECR 리포지토리 삭제 중: $repo_name"
    
    if aws ecr delete-repository --repository-name "$repo_name" --force >/dev/null 2>&1; then
        show_success "ECR 리포지토리 삭제 완료: $repo_name"
    else
        show_error "ECR 리포지토리 삭제 실패: $repo_name"
        show_info "가능한 원인:"
        echo "  • ECR 권한 부족"
        echo "  • 리포지토리가 다른 서비스에서 사용 중"
        echo "  • 네트워크 연결 문제"
        return 1
    fi
}

# ECS 리소스 정리 함수
cleanup_ecs_resources() {
    show_info "ECS 리소스 정리 중..."
    
    local cluster_name="CloudArchitect-Lab-Cluster"
    local service_name="cloudarchitect-lab-service"
    
    # ECS 클러스터 확인
    local cluster_arn=$(aws ecs describe-clusters --clusters "$cluster_name" --query 'clusters[0].clusterArn' --output text 2>/dev/null)
    
    if [ "$cluster_arn" = "None" ] || [ -z "$cluster_arn" ] || [[ "$cluster_arn" == *"MISSING"* ]]; then
        show_info "삭제할 ECS 클러스터가 없습니다: $cluster_name"
        return 0
    fi
    
    show_info "ECS 클러스터 발견: $cluster_name"
    
    # ECS 서비스 확인 및 삭제
    local service_arn=$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --query 'services[0].serviceArn' --output text 2>/dev/null)
    
    if [ "$service_arn" != "None" ] && [ -n "$service_arn" ] && [[ "$service_arn" != *"MISSING"* ]]; then
        show_info "ECS 서비스 삭제 중: $service_name"
        
        # 서비스 desired count를 0으로 설정
        aws ecs update-service --cluster "$cluster_name" --service "$service_name" --desired-count 0 >/dev/null 2>&1
        
        # 서비스 삭제
        aws ecs delete-service --cluster "$cluster_name" --service "$service_name" --force >/dev/null 2>&1
        
        # 서비스 삭제 대기 (최대 2분)
        show_info "ECS 서비스 삭제 대기 중... (최대 2분)"
        local wait_count=0
        while [ $wait_count -lt 24 ]; do
            local service_status=$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --query 'services[0].status' --output text 2>/dev/null)
            if [ "$service_status" = "INACTIVE" ] || [ "$service_status" = "None" ] || [ -z "$service_status" ]; then
                break
            fi
            sleep 5
            wait_count=$((wait_count + 1))
        done
        
        show_success "ECS 서비스 삭제 완료: $service_name"
    else
        show_info "삭제할 ECS 서비스가 없습니다: $service_name"
    fi
    
    # 실행 중인 태스크 확인 및 중지
    local task_arns=$(aws ecs list-tasks --cluster "$cluster_name" --query 'taskArns[]' --output text 2>/dev/null)
    
    if [ -n "$task_arns" ] && [ "$task_arns" != "None" ]; then
        show_info "실행 중인 태스크 중지 중..."
        for task_arn in $task_arns; do
            aws ecs stop-task --cluster "$cluster_name" --task "$task_arn" >/dev/null 2>&1
        done
        show_success "모든 태스크 중지 완료"
        sleep 10
    fi
    
    # ECS 클러스터 삭제
    show_info "ECS 클러스터 삭제 중: $cluster_name"
    if aws ecs delete-cluster --cluster "$cluster_name" >/dev/null 2>&1; then
        show_success "ECS 클러스터 삭제 완료: $cluster_name"
    else
        show_warning "ECS 클러스터 삭제 실패 (이미 삭제되었거나 권한 부족): $cluster_name"
    fi
    
    # Task Definition 비활성화
    show_info "Task Definition 비활성화 중..."
    local task_def_family="cloudarchitect-lab-task"
    local task_def_arns=$(aws ecs list-task-definitions --family-prefix "$task_def_family" --status ACTIVE --query 'taskDefinitionArns[]' --output text 2>/dev/null)
    
    if [ -n "$task_def_arns" ] && [ "$task_def_arns" != "None" ]; then
        for task_def_arn in $task_def_arns; do
            aws ecs deregister-task-definition --task-definition "$task_def_arn" >/dev/null 2>&1
        done
        show_success "Task Definition 비활성화 완료"
    else
        show_info "비활성화할 Task Definition이 없습니다"
    fi
}

# ALB 및 Target Group 정리 함수
cleanup_alb_resources() {
    show_info "ALB 및 Target Group 정리 중..."
    
    local alb_name="CloudArchitect-Lab-ALB"
    local tg_name="CloudArchitect-Lab-TG"
    
    # ALB 확인 및 삭제
    local alb_arn=$(aws elbv2 describe-load-balancers --names "$alb_name" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
    
    if [ "$alb_arn" != "None" ] && [ -n "$alb_arn" ]; then
        show_info "ALB 삭제 중: $alb_name"
        aws elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" >/dev/null 2>&1
        
        # ALB 삭제 대기
        show_info "ALB 삭제 대기 중... (약 1분)"
        sleep 60
        
        show_success "ALB 삭제 완료: $alb_name"
    else
        show_info "삭제할 ALB가 없습니다: $alb_name"
    fi
    
    # Target Group 확인 및 삭제
    local tg_arn=$(aws elbv2 describe-target-groups --names "$tg_name" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    
    if [ "$tg_arn" != "None" ] && [ -n "$tg_arn" ]; then
        show_info "Target Group 삭제 중: $tg_name"
        aws elbv2 delete-target-group --target-group-arn "$tg_arn" >/dev/null 2>&1
        show_success "Target Group 삭제 완료: $tg_name"
    else
        show_info "삭제할 Target Group이 없습니다: $tg_name"
    fi
}

# 로컬 파일 정리 함수
cleanup_local_files() {
    show_info "로컬 파일 정리 중..."
    
    # 환경 파일 삭제
    if [ -f "lab15-prerequisites.env" ]; then
        rm -f lab15-prerequisites.env
        show_success "환경 파일 삭제 완료: lab15-prerequisites.env"
    fi
    
    # 로그 파일 삭제
    local log_files=$(ls lab15-*.log 2>/dev/null || true)
    if [ -n "$log_files" ]; then
        rm -f lab15-*.log
        show_success "로그 파일 삭제 완료"
    fi
    
    show_success "로컬 파일 정리 완료"
}

# 정리 검증 함수
verify_cleanup() {
    show_info "정리 결과 검증 중..."
    
    # ECR 리포지토리 삭제 확인
    local repo_check=$(aws ecr describe-repositories --repository-names "cloudarchitect-lab-webapp" --query 'repositories[0].repositoryName' --output text 2>/dev/null)
    
    if [ "$repo_check" = "cloudarchitect-lab-webapp" ]; then
        show_warning "ECR 리포지토리가 아직 존재합니다: cloudarchitect-lab-webapp"
        return 1
    else
        show_success "ECR 리포지토리 삭제 검증 완료"
    fi
    
    return 0
}

# 완료 요약 표시 함수
show_cleanup_summary() {
    echo ""
    show_success "🎉 Lab15 ECS 컨테이너 인프라 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 정리된 주요 리소스:"
    echo "  ✅ ECS 클러스터: CloudArchitect-Lab-Cluster"
    echo "  ✅ ECS 서비스: cloudarchitect-lab-service"
    echo "  ✅ ECS Task Definition: cloudarchitect-lab-task (비활성화)"
    echo "  ✅ Application Load Balancer: CloudArchitect-Lab-ALB"
    echo "  ✅ Target Group: CloudArchitect-Lab-TG"
    echo "  ✅ ECR 리포지토리: cloudarchitect-lab-webapp"
    echo "  ✅ 리포지토리 내 모든 Docker 이미지"
    echo "  ✅ VPC: CloudArchitect-Lab-VPC (10.0.0.0/16)"
    echo "  ✅ Internet Gateway, NAT Gateway, Elastic IP"
    echo "  ✅ Public/Private Subnets (4개, Multi-AZ)"
    echo "  ✅ Route Tables (Public/Private)"
    echo "  ✅ Security Groups (ALB-SG, ECS-SG)"
    echo "  ✅ 로컬 환경 파일 및 로그 파일"
    echo ""
    
    echo "💡 참고사항:"
    echo "  • 모든 Lab15 리소스가 자동으로 정리되었습니다"
    echo "  • IAM 역할 ecsTaskExecutionRole은 AWS 관리형 역할이므로 유지됩니다"
    echo "  • 다른 실습에서 생성된 리소스는 각각의 cleanup 스크립트로 정리하세요"
    echo ""
    
    show_success "Lab15 정리 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # 헤더 표시
    echo "================================"
    echo "Lab15: Amazon ECS 서비스 배포 - 컨테이너 오케스트레이션 관리 정리"
    echo "================================"
    echo "목적: Lab15에서 생성된 모든 리소스를 안전하게 정리"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "미설정")
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "미설정")
    
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo "사용자: $user_arn"
    echo ""
    
    # Lab15 리소스 확인
    show_info "Lab15 관련 리소스 확인 중..."
    
    # ECS 클러스터 확인
    local cluster_arn=$(aws ecs describe-clusters --clusters "CloudArchitect-Lab-Cluster" --query 'clusters[0].clusterArn' --output text 2>/dev/null)
    
    # ALB 확인
    local alb_arn=$(aws elbv2 describe-load-balancers --names "CloudArchitect-Lab-ALB" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
    
    # ECR 리포지토리 확인
    local ecr_repo=$(aws ecr describe-repositories --repository-names "cloudarchitect-lab-webapp" --query 'repositories[0].repositoryName' --output text 2>/dev/null)
    
    # VPC 확인
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" "Name=tag:Lab,Values=Lab15" \
        --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    
    echo ""
    show_important "🗑️ 삭제 계획:"
    echo ""
    echo "  📋 정리할 리소스:"
    
    # ECS 리소스
    if [ "$cluster_arn" != "None" ] && [ -n "$cluster_arn" ] && [[ "$cluster_arn" != *"MISSING"* ]]; then
        echo "    🏗️ ECS 클러스터: CloudArchitect-Lab-Cluster"
        echo "    🚀 ECS 서비스: cloudarchitect-lab-service"
        echo "    📋 Task Definition: cloudarchitect-lab-task"
    else
        echo "    ℹ️ 삭제할 ECS 리소스가 없습니다"
    fi
    
    # ALB 리소스
    if [ "$alb_arn" != "None" ] && [ -n "$alb_arn" ]; then
        echo "    ⚖️ Application Load Balancer: CloudArchitect-Lab-ALB"
        echo "    🎯 Target Group: CloudArchitect-Lab-TG"
    else
        echo "    ℹ️ 삭제할 ALB가 없습니다"
    fi
    
    # VPC 리소스
    if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
        echo "    🌐 VPC: CloudArchitect-Lab-VPC ($vpc_id)"
        echo "    🌍 Internet Gateway, NAT Gateway, Elastic IP"
        echo "    🏢 Public/Private Subnets (4개)"
        echo "    🗺️ Route Tables (Public/Private)"
        echo "    🛡️ Security Groups (ALB-SG, ECS-SG)"
    else
        echo "    ℹ️ 삭제할 VPC가 없습니다"
    fi
    
    # ECR 리소스
    if [ "$ecr_repo" = "cloudarchitect-lab-webapp" ]; then
        local repo_uri=$(aws ecr describe-repositories --repository-names "cloudarchitect-lab-webapp" --query 'repositories[0].repositoryUri' --output text)
        local image_count=$(aws ecr list-images --repository-name "cloudarchitect-lab-webapp" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
        echo "    🏪 ECR 리포지토리: cloudarchitect-lab-webapp ($repo_uri)"
        echo "    🐳 컨테이너 이미지: $image_count개"
    else
        echo "    ℹ️ 삭제할 ECR 리포지토리가 없습니다"
    fi
    
    echo "    📁 로컬 파일: 환경 파일, 로그 파일"
    echo ""
    
    echo "  💡 참고사항:"
    echo "    • 모든 Lab15 리소스를 자동으로 정리합니다"
    echo "    • 예상 소요 시간: 약 3-5분"
    echo ""
    
    # 사용자 확인
    read -p "위 계획대로 Lab15 리소스를 정리하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab15 정리가 취소되었습니다."
        exit 0
    fi
    
    show_info "Lab15 리소스 정리를 시작합니다..."
    echo ""
    
    # 리소스 정리 (단계별)
    show_progress 1 5 "ECS 리소스 정리 중..."
    cleanup_ecs_resources
    echo ""
    
    show_progress 2 5 "ALB 및 Target Group 정리 중..."
    cleanup_alb_resources
    echo ""
    
    show_progress 3 5 "ECR 리포지토리 정리 중..."
    cleanup_ecr_repository
    echo ""
    
    show_progress 4 5 "VPC 네트워크 인프라 정리 중..."
    cleanup_vpc_infrastructure
    echo ""
    
    show_progress 5 5 "로컬 파일 정리 중..."
    cleanup_local_files
    echo ""
    
    # 정리 검증
    if verify_cleanup; then
        show_success "정리 검증 완료"
    else
        show_warning "일부 리소스 정리 실패"
    fi
    
    # 완료 요약
    show_cleanup_summary
}

# 스크립트 실행
main "$@"