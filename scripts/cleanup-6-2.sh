#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}



# ================================
# Lab08: Amazon RDS MySQL 데이터베이스 구축 정리
# ================================
# 목적: Lab08에서 생성된 모든 AWS 리소스를 안전하게 정리
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
    
    # Name 태그가 없으면 Lab08 태그로 찾기 (보조)
    if [ -z "$route_tables" ] || [ "$route_tables" = "None" ]; then
        route_tables=$(aws ec2 describe-route-tables \
            --filters "Name=tag:Lab,Values=Lab08" \
            --query 'RouteTables[*].RouteTableId' \
            --output text 2>/dev/null)
    fi
    
    if [ ! -z "$route_tables" ] && [ "$route_tables" != "None" ]; then
        for rt_id in $route_tables; do
            show_info "Route Table 정리 중: $rt_id"
            
            # IGW로의 라우트 제거 (0.0.0.0/0 → IGW)
            local igw_routes=$(aws ec2 describe-route-tables \
                --route-table-ids $rt_id \
                --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0` && GatewayId!=null && starts_with(GatewayId, `igw-`)].GatewayId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$igw_routes" ] && [ "$igw_routes" != "None" ]; then
                show_info "IGW 라우트 제거 중: $rt_id → $igw_routes"
                aws ec2 delete-route --route-table-id $rt_id --destination-cidr-block 0.0.0.0/0 >/dev/null 2>&1 || true
            fi
            
            # 연결된 서브넷 해제
            local associations=$(aws ec2 describe-route-tables \
                --route-table-ids $rt_id \
                --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' \
                --output text 2>/dev/null)
            
            if [ ! -z "$associations" ] && [ "$associations" != "None" ]; then
                show_info "서브넷 연결 해제 중: $rt_id"
                for assoc_id in $associations; do
                    aws ec2 disassociate-route-table --association-id $assoc_id >/dev/null 2>&1 || true
                done
            fi
            
            # Route Table 삭제
            show_info "Route Table 삭제 중: $rt_id"
            aws ec2 delete-route-table --route-table-id $rt_id >/dev/null 2>&1 || true
        done
        show_success "Route Table 정리 완료"
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
    
    # Name 태그가 없으면 Lab08 태그로 찾기 (보조)
    if [ -z "$igw_ids" ] || [ "$igw_ids" = "None" ]; then
        igw_ids=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Lab,Values=Lab08" \
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

# EC2 인스턴스 삭제 (setup에서 생성한 것만)
cleanup_ec2_instances() {
    show_info "EC2 인스턴스 정리 중..."
    
    # setup에서 생성한 EC2 인스턴스 조회
    local ec2_instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-RDS-Client" \
                  "Name=instance-state-name,Values=running,stopped,pending" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null)
    
    if [ ! -z "$ec2_instances" ] && [ "$ec2_instances" != "None" ]; then
        for instance_id in $ec2_instances; do
            show_info "EC2 인스턴스 종료 중: CloudArchitect-Lab-RDS-Client ($instance_id)"
            
            if aws ec2 terminate-instances --instance-ids "$instance_id" >/dev/null 2>&1; then
                show_success "EC2 인스턴스 종료 시작: $instance_id"
                
                # 인스턴스 종료 완료까지 대기
                show_info "EC2 인스턴스 종료 완료 대기 중... $instance_id"
                if aws ec2 wait instance-terminated --instance-ids "$instance_id" 2>/dev/null; then
                    show_success "EC2 인스턴스 종료 완료: $instance_id"
                else
                    show_warning "EC2 인스턴스 종료 대기 시간 초과: $instance_id"
                    show_info "백그라운드에서 종료가 계속 진행됩니다."
                fi
            else
                show_error "EC2 인스턴스 종료 실패: $instance_id"
            fi
        done
        show_success "EC2 인스턴스 정리 완료"
    else
        show_info "정리할 EC2 인스턴스가 없습니다."
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
    
    # Lab08 setup에서 생성한 EC2 Security Group 찾기
    local ec2_sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null)
    
    if [ "$ec2_sg_id" != "None" ] && [ ! -z "$ec2_sg_id" ]; then
        # EC2 SG를 사용 중인 인스턴스 확인
        local sg_in_use=$(aws ec2 describe-instances \
            --filters "Name=instance.group-id,Values=$ec2_sg_id" "Name=instance-state-name,Values=running,stopped,pending" \
            --query 'Reservations[*].Instances[*].InstanceId' \
            --output text 2>/dev/null)
        
        if [ -z "$sg_in_use" ] || [ "$sg_in_use" = "None" ]; then
            show_info "EC2 Security Group 삭제 중: CloudArchitect-Lab-EC2-SG ($ec2_sg_id)"
            
            # 최대 60회 재시도 (3분)
            local delete_attempts=0
            local max_attempts=60
            while [ $delete_attempts -lt $max_attempts ]; do
                if aws ec2 delete-security-group --group-id "$ec2_sg_id" >/dev/null 2>&1; then
                    show_success "EC2 Security Group 삭제 완료: CloudArchitect-Lab-EC2-SG ($ec2_sg_id)"
                    break
                else
                    ((delete_attempts++))
                    if [ $((delete_attempts % 10)) -eq 0 ]; then
                        show_info "EC2 Security Group 삭제 재시도 중... (시도 ${delete_attempts}/${max_attempts}회)"
                    fi
                    if [ $delete_attempts -ge $max_attempts ]; then
                        show_error "EC2 Security Group 삭제 실패: 최대 재시도 횟수 초과"
                        return 1
                    fi
                    sleep 3
                fi
            done
        else
            show_warning "EC2 Security Group이 인스턴스에서 사용 중입니다: $sg_in_use"
            show_info "학생이 생성한 EC2 인스턴스를 먼저 삭제한 후 이 스크립트를 다시 실행하세요."
        fi
    else
        show_info "EC2 Security Group이 존재하지 않습니다."
    fi
    
    show_success "Security Group 정리 완료"
}

# ENI 자동 정리 함수
cleanup_available_enis() {
    show_info "사용 가능한 ENI 정리 중..."
    
    # VPC 내의 available 상태 ENI 조회
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
    
    if [ "$vpc_id" = "None" ] || [ -z "$vpc_id" ]; then
        show_info "VPC가 존재하지 않아 ENI 정리를 건너뜁니다."
        return 0
    fi
    
    local available_enis=$(aws ec2 describe-network-interfaces \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=status,Values=available" \
        --query 'NetworkInterfaces[*].NetworkInterfaceId' \
        --output text 2>/dev/null)
    
    if [ ! -z "$available_enis" ] && [ "$available_enis" != "None" ]; then
        show_info "사용 가능한 ENI 발견: $available_enis"
        
        for eni_id in $available_enis; do
            show_info "ENI 삭제 중: $eni_id"
            
            # ENI 삭제 시도 (RDS/EC2 삭제 후 남은 ENI)
            if aws ec2 delete-network-interface --network-interface-id $eni_id >/dev/null 2>&1; then
                show_success "ENI 삭제 완료: $eni_id"
            else
                show_warning "ENI 삭제 실패 (사용 중일 수 있음): $eni_id"
            fi
        done
    else
        show_info "정리할 사용 가능한 ENI가 없습니다."
    fi
    
    show_success "ENI 정리 완료"
}

# Subnet 삭제 (재시도 로직 포함)
cleanup_subnets() {
    show_info "Subnet 정리 중..."
    
    # ENI 정리 먼저 수행
    cleanup_available_enis
    
    local max_retries=10  # 재시도 횟수 증가
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        # Name 태그로 서브넷 찾기 (CloudArchitect-Lab 관련 모든 서브넷)
        local subnet_ids=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-Subnet*" \
            --query 'Subnets[*].SubnetId' \
            --output text 2>/dev/null)
        
        # 추가로 Lab08 태그가 있는 서브넷도 찾기
        if [ -z "$subnet_ids" ] || [ "$subnet_ids" = "None" ]; then
            subnet_ids=$(aws ec2 describe-subnets \
                --filters "Name=tag:Lab,Values=Lab08" \
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
                show_warning "서브넷에 네트워크 인터페이스가 $eni_count 개 연결되어 있습니다."
                
                # ENI 상세 정보 확인
                local eni_details=$(aws ec2 describe-network-interfaces \
                    --filters "Name=subnet-id,Values=$subnet_id" \
                    --query 'NetworkInterfaces[*].[NetworkInterfaceId,Status,Description]' \
                    --output text 2>/dev/null)
                
                show_info "ENI 상세 정보:"
                echo "$eni_details"
                
                # available 상태 ENI가 있으면 삭제 시도
                local available_enis_in_subnet=$(aws ec2 describe-network-interfaces \
                    --filters "Name=subnet-id,Values=$subnet_id" "Name=status,Values=available" \
                    --query 'NetworkInterfaces[*].NetworkInterfaceId' \
                    --output text 2>/dev/null)
                
                if [ ! -z "$available_enis_in_subnet" ] && [ "$available_enis_in_subnet" != "None" ]; then
                    show_info "서브넷 내 사용 가능한 ENI 정리 시도: $available_enis_in_subnet"
                    for eni_id in $available_enis_in_subnet; do
                        aws ec2 delete-network-interface --network-interface-id $eni_id >/dev/null 2>&1 || true
                    done
                    sleep 5  # ENI 삭제 후 잠시 대기
                    continue  # 다음 반복에서 다시 시도
                else
                    show_warning "활성 상태의 ENI가 있습니다. RDS/EC2 인스턴스가 아직 실행 중일 수 있습니다."
                    sleep 10
                    continue
                fi
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
            
            # ENI 재정리 시도
            if [ $((retry_count % 3)) -eq 0 ]; then
                show_info "ENI 재정리 시도..."
                cleanup_available_enis
            fi
            
            sleep 15  # 대기 시간 증가
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
                
                # available 상태 ENI 자동 정리 시도
                local available_enis=$(aws ec2 describe-network-interfaces \
                    --filters "Name=vpc-id,Values=$vpc_id" "Name=status,Values=available" \
                    --query 'NetworkInterfaces[*].NetworkInterfaceId' \
                    --output text 2>/dev/null)
                
                if [ ! -z "$available_enis" ] && [ "$available_enis" != "None" ]; then
                    show_info "사용 가능한 ENI 자동 정리 시도: $available_enis"
                    for eni_id in $available_enis; do
                        if aws ec2 delete-network-interface --network-interface-id $eni_id >/dev/null 2>&1; then
                            show_success "ENI 삭제 완료: $eni_id"
                        else
                            show_warning "ENI 삭제 실패: $eni_id"
                        fi
                    done
                    
                    # ENI 정리 후 잠시 대기
                    sleep 10
                    
                    # 다시 ENI 확인
                    enis=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text 2>/dev/null)
                fi
                
                # 여전히 ENI가 남아있으면 경고
                if [ ! -z "$enis" ] && [ "$enis" != "None" ]; then
                    show_warning "활성 상태의 ENI가 남아있습니다: $enis"
                    show_info "학생이 생성한 RDS 인스턴스와 EC2 인스턴스를 먼저 삭제한 후 이 스크립트를 다시 실행하세요."
                    return 1
                fi
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

# 리소스 확인 및 삭제 계획 표시 함수
show_deletion_plan() {
    echo ""
    show_important "🔍 발견된 Lab08 리소스:"
    echo ""
    
    # 실제 리소스 확인
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    local igw_id=""
    local public_subnet_id=""
    local private_subnet1_id=""
    local private_subnet2_id=""
    local ec2_sg_id=""
    local ec2_instance_id=""
    
    if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
        echo "✅ VPC: CloudArchitect-Lab-VPC ($vpc_id)"
        
        # Internet Gateway 확인
        igw_id=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$vpc_id" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
        
        if [ "$igw_id" != "None" ] && [ -n "$igw_id" ]; then
            echo "✅ Internet Gateway: CloudArchitect-Lab-IGW ($igw_id)"
        fi
        
        # Public Subnet 확인
        public_subnet_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        if [ "$public_subnet_id" != "None" ] && [ -n "$public_subnet_id" ]; then
            echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($public_subnet_id)"
        fi
        
        # Private Subnets 확인
        private_subnet1_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-1" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        private_subnet2_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-2" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        if [ "$private_subnet1_id" != "None" ] && [ -n "$private_subnet1_id" ]; then
            echo "✅ Private Subnet 1: CloudArchitect-Lab-Private-Subnet-1 ($private_subnet1_id)"
        fi
        
        if [ "$private_subnet2_id" != "None" ] && [ -n "$private_subnet2_id" ]; then
            echo "✅ Private Subnet 2: CloudArchitect-Lab-Private-Subnet-2 ($private_subnet2_id)"
        fi
        
        # EC2 Security Group 확인
        ec2_sg_id=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$vpc_id" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        if [ "$ec2_sg_id" != "None" ] && [ -n "$ec2_sg_id" ]; then
            echo "✅ EC2 Security Group: CloudArchitect-Lab-EC2-SG ($ec2_sg_id)"
        fi
        
        # EC2 Instance 확인
        ec2_instance_id=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-RDS-Client" "Name=instance-state-name,Values=running,pending,stopped" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null)
        
        if [ "$ec2_instance_id" != "None" ] && [ -n "$ec2_instance_id" ]; then
            echo "✅ EC2 Instance: CloudArchitect-Lab-RDS-Client ($ec2_instance_id)"
        fi
        
        # Route Tables 확인
        local route_tables=$(aws ec2 describe-route-tables \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-RT" "Name=vpc-id,Values=$vpc_id" \
            --query 'RouteTables[*].RouteTableId' \
            --output text 2>/dev/null)
        
        if [ "$route_tables" != "None" ] && [ -n "$route_tables" ]; then
            echo "✅ Route Tables: CloudArchitect-Lab-*-RT"
        fi
    else
        echo "ℹ️ Lab08 리소스가 발견되지 않았습니다."
    fi
    
    echo ""
    echo "⚠️ 주의사항:"
    echo "• 리소스 삭제는 되돌릴 수 없습니다"
    echo "• 의존성 순서에 따라 단계적으로 삭제됩니다"
    echo "• 학생이 생성한 RDS 인스턴스는 별도로 삭제해야 합니다"
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab08 RDS 실습 인프라 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 삭제 완료된 리소스:"
    echo "✅ VPC: CloudArchitect-Lab-VPC"
    echo "✅ Internet Gateway: CloudArchitect-Lab-IGW"
    echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet"
    echo "✅ Private Subnets: 2개 (RDS용)"
    echo "✅ Route Tables: 사용자 정의 라우트 테이블"
    echo "✅ Security Groups: CloudArchitect-Lab-EC2-SG"
    echo "✅ EC2 Instance: CloudArchitect-Lab-RDS-Client"
    echo ""
    
    echo "💰 비용 절약"
    echo "• 모든 Lab08 관련 리소스가 정리되어 추가 비용이 발생하지 않습니다"
    echo "• VPC 관련 리소스 정리 완료"
    echo ""
    
    echo "🔍 필수 확인 사항"
    echo "⚠️ AWS 콘솔에서 다음 항목들이 완전히 삭제되었는지 반드시 확인하세요:"
    echo "• VPC: CloudArchitect-Lab-VPC"
    echo "• Subnets: 모든 Public/Private 서브넷"
    echo "• Route Tables: 사용자 정의 라우트 테이블"
    echo "• Security Groups: CloudArchitect-Lab-EC2-SG"
    echo "• Internet Gateway: CloudArchitect-Lab-IGW"
    echo "• EC2 Instances: CloudArchitect-Lab-RDS-Client"
    echo ""
    
    echo "⚠️ 만약 일부 리소스가 남아있다면 AWS 콘솔에서 수동으로 삭제해주세요."
    echo "⚠️ 특히 VPC 삭제가 실패한 경우, 의존성 리소스를 먼저 정리해야 합니다."
    echo ""
    
    echo "=========================================="
    echo "전체 실행 시간: 약 3-5분"
}

# AWS CLI 프로필 및 리전 확인
get_aws_account_info() {
    # 환경변수 디버깅
    if [ -n "$AWS_PROFILE" ]; then
        show_info "AWS_PROFILE: $AWS_PROFILE"
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
    
    # 디버깅을 위한 로그
    if [ -z "$account_id" ] || [ "$account_id" = "None" ] || [ "$account_id" = "null" ]; then
        show_error "AWS 자격 증명을 확인할 수 없습니다."
        show_info "다음 명령어로 AWS CLI를 설정해주세요:"
        echo "  aws configure"
        if [ -n "$AWS_PROFILE" ]; then
            show_info "또는 AWS_PROFILE=$AWS_PROFILE 환경변수를 확인해주세요."
        fi
        exit 1
    fi
    
    echo "$account_id:$region:$user_arn"
}

# 리소스 확인 및 삭제 계획 표시 함수
show_deletion_plan() {
    echo ""
    show_important "🔍 발견된 Lab08 리소스:"
    echo ""
    
    # 실제 리소스 확인
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" \
        --query 'Vpcs[0].VpcId' \
        --output text 2>/dev/null)
    
    local igw_id=""
    local public_subnet_id=""
    local private_subnet1_id=""
    local private_subnet2_id=""
    local ec2_sg_id=""
    local ec2_instance_id=""
    
    if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
        echo "✅ VPC: CloudArchitect-Lab-VPC ($vpc_id)"
        
        # Internet Gateway 확인
        igw_id=$(aws ec2 describe-internet-gateways \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-IGW" "Name=attachment.vpc-id,Values=$vpc_id" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text 2>/dev/null)
        
        if [ "$igw_id" != "None" ] && [ -n "$igw_id" ]; then
            echo "✅ Internet Gateway: CloudArchitect-Lab-IGW ($igw_id)"
        fi
        
        # Public Subnet 확인
        public_subnet_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Public-Subnet" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        if [ "$public_subnet_id" != "None" ] && [ -n "$public_subnet_id" ]; then
            echo "✅ Public Subnet: CloudArchitect-Lab-Public-Subnet ($public_subnet_id)"
        fi
        
        # Private Subnets 확인
        private_subnet1_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-1" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        private_subnet2_id=$(aws ec2 describe-subnets \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-Private-Subnet-2" "Name=vpc-id,Values=$vpc_id" \
            --query 'Subnets[0].SubnetId' \
            --output text 2>/dev/null)
        
        if [ "$private_subnet1_id" != "None" ] && [ -n "$private_subnet1_id" ]; then
            echo "✅ Private Subnet 1: CloudArchitect-Lab-Private-Subnet-1 ($private_subnet1_id)"
        fi
        
        if [ "$private_subnet2_id" != "None" ] && [ -n "$private_subnet2_id" ]; then
            echo "✅ Private Subnet 2: CloudArchitect-Lab-Private-Subnet-2 ($private_subnet2_id)"
        fi
        
        # EC2 Security Group 확인
        ec2_sg_id=$(aws ec2 describe-security-groups \
            --filters "Name=group-name,Values=CloudArchitect-Lab-EC2-SG" "Name=vpc-id,Values=$vpc_id" \
            --query 'SecurityGroups[0].GroupId' \
            --output text 2>/dev/null)
        
        if [ "$ec2_sg_id" != "None" ] && [ -n "$ec2_sg_id" ]; then
            echo "✅ EC2 Security Group: CloudArchitect-Lab-EC2-SG ($ec2_sg_id)"
        fi
        
        # EC2 Instance 확인
        ec2_instance_id=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-RDS-Client" "Name=instance-state-name,Values=running,pending,stopped" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null)
        
        if [ "$ec2_instance_id" != "None" ] && [ -n "$ec2_instance_id" ]; then
            echo "✅ EC2 Instance: CloudArchitect-Lab-RDS-Client ($ec2_instance_id)"
        fi
        
        # Route Tables 확인
        local route_tables=$(aws ec2 describe-route-tables \
            --filters "Name=tag:Name,Values=CloudArchitect-Lab-*-RT" "Name=vpc-id,Values=$vpc_id" \
            --query 'RouteTables[*].RouteTableId' \
            --output text 2>/dev/null)
        
        if [ "$route_tables" != "None" ] && [ -n "$route_tables" ]; then
            echo "✅ Route Tables: CloudArchitect-Lab-*-RT"
        fi
    else
        echo "ℹ️ Lab08 리소스가 발견되지 않았습니다."
    fi
    
    echo ""
    echo "⚠️ 주의사항:"
    echo "• 리소스 삭제는 되돌릴 수 없습니다"
    echo "• 의존성 순서에 따라 단계적으로 삭제됩니다"
    echo "• 학생이 생성한 RDS 인스턴스는 별도로 삭제해야 합니다"
}

# 스크립트 초기화
echo "================================"
echo "Lab08: Amazon RDS MySQL 데이터베이스 구축 정리"
echo "================================"
echo "목적: Lab08에서 생성된 모든 AWS 리소스를 안전하게 정리"
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

# 2단계: 기존 리소스 상태 확인
show_info "기존 리소스 상태를 확인합니다..."
show_deletion_plan

# 3단계: 사용자 확인 (리소스가 있을 때만)
# VPC 확인으로 리소스 존재 여부 판단
vpc_exists=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudArchitect-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

if [ "$vpc_exists" != "None" ] && [ -n "$vpc_exists" ]; then
    echo ""
    read -p "위 리소스들을 삭제하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab08 정리가 취소되었습니다."
        exit 0
    fi
    show_info "리소스 삭제를 시작합니다..."
    echo ""
else
    show_info "삭제할 Lab08 리소스가 없습니다. 정리 작업을 건너뜁니다."
    exit 0
fi

# 메인 실행 함수
main() {
    # 리소스 삭제 (단계별)
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
    
    # 완료 요약 표시
    show_completion_summary
}

# 스크립트 실행
main "$@"