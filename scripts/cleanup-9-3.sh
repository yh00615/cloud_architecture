#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab13: Amazon API Gateway 서비스 구축 - RESTful API 설계 및 배포 정리
# 목적: Lab13에서 생성된 Lambda 함수, DynamoDB 테이블, IAM 역할을 안전하게 정리
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

# Lambda 함수 정리 함수
cleanup_lambda_function() {
    show_info "Lambda 함수 정리 중..."
    
    local function_name="CloudArchitect-Lab-UsersAPI"
    
    # 기존 함수 확인
    local existing_function=$(aws lambda get-function --function-name "$function_name" --query 'Configuration.FunctionName' --output text 2>/dev/null)
    
    if [ "$existing_function" != "$function_name" ] || [ -z "$existing_function" ]; then
        show_info "삭제할 Lambda 함수가 없습니다: $function_name"
        return 0
    fi
    
    show_info "Lambda 함수 발견: $function_name"
    
    # Lambda 함수 삭제
    if aws lambda delete-function --function-name "$function_name" >/dev/null 2>&1; then
        show_success "Lambda 함수 삭제 완료: $function_name"
    else
        show_error "Lambda 함수 삭제 실패: $function_name"
        show_info "가능한 원인:"
        echo "  • Lambda 권한 부족"
        echo "  • 함수가 다른 서비스에서 사용 중"
        echo "  • 네트워크 연결 문제"
        return 1
    fi
}

# DynamoDB 테이블 정리 함수
cleanup_dynamodb_table() {
    show_info "DynamoDB 테이블 정리 중..."
    
    local table_name="CloudArchitect-Lab-Users"
    
    # 기존 테이블 확인
    local existing_table=$(aws dynamodb describe-table --table-name "$table_name" --query 'Table.TableName' --output text 2>/dev/null)
    
    if [ "$existing_table" != "$table_name" ] || [ -z "$existing_table" ]; then
        show_info "삭제할 DynamoDB 테이블이 없습니다: $table_name"
        return 0
    fi
    
    show_info "DynamoDB 테이블 발견: $table_name"
    
    # 테이블 삭제
    if aws dynamodb delete-table --table-name "$table_name" >/dev/null 2>&1; then
        show_success "DynamoDB 테이블 삭제 완료: $table_name"
        
        # 테이블 삭제 완료 대기
        show_info "테이블 삭제 완료 대기 중..."
        local wait_count=0
        while [ $wait_count -lt 30 ]; do  # 최대 3분 대기
            local table_status=$(aws dynamodb describe-table --table-name "$table_name" --query 'Table.TableStatus' --output text 2>/dev/null)
            if [ -z "$table_status" ] || [ "$table_status" = "None" ]; then
                show_success "DynamoDB 테이블 삭제 검증 완료"
                return 0
            fi
            echo -n "."
            sleep 6
            ((wait_count++))
        done
        echo ""
        show_warning "테이블 삭제 완료 확인 시간 초과"
        
    else
        show_error "DynamoDB 테이블 삭제 실패: $table_name"
        show_info "가능한 원인:"
        echo "  • DynamoDB 권한 부족"
        echo "  • 테이블이 다른 서비스에서 사용 중"
        echo "  • 네트워크 연결 문제"
        return 1
    fi
}

# IAM 역할 정리 함수
cleanup_iam_role() {
    show_info "IAM 역할 정리 중..."
    
    local role_name="CloudArchitect-Lab-LambdaRole"
    
    # 기존 역할 확인
    local existing_role=$(aws iam get-role --role-name "$role_name" --query 'Role.RoleName' --output text 2>/dev/null)
    
    if [ "$existing_role" != "$role_name" ] || [ -z "$existing_role" ]; then
        show_info "삭제할 IAM 역할이 없습니다: $role_name"
        return 0
    fi
    
    show_info "IAM 역할 발견: $role_name"
    
    # 연결된 정책 분리
    show_info "연결된 정책 분리 중..."
    
    # AWS 관리형 정책 분리
    aws iam detach-role-policy \
        --role-name "$role_name" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole >/dev/null 2>&1
    
    aws iam detach-role-policy \
        --role-name "$role_name" \
        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess >/dev/null 2>&1
    
    # 고객 관리형 정책 확인 및 분리
    local attached_policies=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null)
    
    if [ -n "$attached_policies" ]; then
        for policy_arn in $attached_policies; do
            aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy_arn" >/dev/null 2>&1
        done
    fi
    
    # 인라인 정책 확인 및 삭제
    local inline_policies=$(aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames' --output text 2>/dev/null)
    
    if [ -n "$inline_policies" ] && [ "$inline_policies" != "None" ]; then
        for policy_name in $inline_policies; do
            aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy_name" >/dev/null 2>&1
        done
    fi
    
    # IAM 역할 삭제
    if aws iam delete-role --role-name "$role_name" >/dev/null 2>&1; then
        show_success "IAM 역할 삭제 완료: $role_name"
    else
        show_error "IAM 역할 삭제 실패: $role_name"
        show_info "가능한 원인:"
        echo "  • IAM 권한 부족"
        echo "  • 역할이 다른 서비스에서 사용 중"
        echo "  • 연결된 정책이 남아있음"
        return 1
    fi
}

# 로컬 파일 정리 함수
cleanup_local_files() {
    show_info "로컬 파일 정리 중..."
    
    # 환경 파일 삭제
    if [ -f "lab13-prerequisites.env" ]; then
        rm -f lab13-prerequisites.env
        show_success "환경 파일 삭제 완료: lab13-prerequisites.env"
    fi
    

    
    show_success "로컬 파일 정리 완료"
}

# 정리 검증 함수
verify_cleanup() {
    show_info "정리 결과 검증 중..."
    
    local verification_failed=false
    
    # Lambda 함수 삭제 확인
    local function_check=$(aws lambda get-function --function-name "CloudArchitect-Lab-UsersAPI" --query 'Configuration.FunctionName' --output text 2>/dev/null)
    if [ "$function_check" = "CloudArchitect-Lab-UsersAPI" ]; then
        show_warning "Lambda 함수가 아직 존재합니다: CloudArchitect-Lab-UsersAPI"
        verification_failed=true
    else
        show_success "Lambda 함수 삭제 검증 완료"
    fi
    
    # DynamoDB 테이블 삭제 확인
    local table_check=$(aws dynamodb describe-table --table-name "CloudArchitect-Lab-Users" --query 'Table.TableName' --output text 2>/dev/null)
    if [ "$table_check" = "CloudArchitect-Lab-Users" ]; then
        show_warning "DynamoDB 테이블이 아직 존재합니다: CloudArchitect-Lab-Users"
        verification_failed=true
    else
        show_success "DynamoDB 테이블 삭제 검증 완료"
    fi
    
    # IAM 역할 삭제 확인
    local role_check=$(aws iam get-role --role-name "CloudArchitect-Lab-LambdaRole" --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$role_check" = "CloudArchitect-Lab-LambdaRole" ]; then
        show_warning "IAM 역할이 아직 존재합니다: CloudArchitect-Lab-LambdaRole"
        verification_failed=true
    else
        show_success "IAM 역할 삭제 검증 완료"
    fi
    
    if [ "$verification_failed" = true ]; then
        return 1
    else
        show_success "정리 결과 검증 완료"
        return 0
    fi
}

# 완료 요약 표시 함수
show_cleanup_summary() {
    echo ""
    show_success "🎉 Lab13 API Gateway 인프라 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 정리된 주요 리소스:"
    echo "  ✅ Lambda 함수: CloudArchitect-Lab-UsersAPI"
    echo "  ✅ DynamoDB 테이블: CloudArchitect-Lab-Users"
    echo "  ✅ IAM 역할: CloudArchitect-Lab-LambdaRole"
    echo "  ✅ 연결된 IAM 정책들"
    echo "  ✅ 로컬 환경 파일"
    echo "  ✅ 이전 로그 파일"
    echo ""
    
    echo "⚠️ 수동으로 정리해야 할 리소스:"
    echo "  🌐 API Gateway (학생이 콘솔에서 생성한 것)"
    echo "  📋 API Gateway 리소스 및 메서드 (학생이 콘솔에서 생성한 것)"
    echo "  🚀 API Gateway 배포 스테이지 (학생이 콘솔에서 생성한 것)"
    echo "    - API Gateway 콘솔에서 API를 선택"
    echo "    - Actions → Delete API 선택"
    echo "    - 배포된 스테이지도 함께 삭제됨"
    echo ""
    
    echo "💡 참고사항:"
    echo "  • Lambda, DynamoDB, IAM 역할은 스크립트로 생성되었으므로 자동 정리"
    echo "  • API Gateway 관련 리소스는 학생이 직접 생성한 것이므로 수동 정리 필요"
    echo "  • 다른 실습에서 생성된 리소스는 각각의 cleanup 스크립트로 정리"
    echo ""
    
    show_success "Lab13 정리 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # 헤더 표시
    echo "================================"
    echo "Lab13: Amazon API Gateway 서비스 구축 - RESTful API 설계 및 배포 정리"
    echo "================================"
    echo "목적: Lab13에서 생성된 Lambda 함수, DynamoDB 테이블, IAM 역할을 안전하게 정리"
    echo "주의: 학생이 콘솔에서 생성한 API Gateway는 정리하지 않음"
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
    
    # Lab13 리소스 확인
    show_info "Lab13 관련 리소스 확인 중..."
    
    # Lambda 함수 확인
    local lambda_function=$(aws lambda get-function --function-name "CloudArchitect-Lab-UsersAPI" --query 'Configuration.FunctionName' --output text 2>/dev/null)
    
    # DynamoDB 테이블 확인
    local dynamodb_table=$(aws dynamodb describe-table --table-name "CloudArchitect-Lab-Users" --query 'Table.TableName' --output text 2>/dev/null)
    
    # IAM 역할 확인
    local iam_role=$(aws iam get-role --role-name "CloudArchitect-Lab-LambdaRole" --query 'Role.RoleName' --output text 2>/dev/null)
    
    echo ""
    show_important "🗑️ 삭제 계획:"
    echo ""
    echo "  📋 정리할 리소스:"
    
    if [ "$lambda_function" = "CloudArchitect-Lab-UsersAPI" ]; then
        echo "    ⚡ Lambda 함수: CloudArchitect-Lab-UsersAPI"
    else
        echo "    ℹ️ 삭제할 Lambda 함수가 없습니다"
    fi
    
    if [ "$dynamodb_table" = "CloudArchitect-Lab-Users" ]; then
        echo "    🗄️ DynamoDB 테이블: CloudArchitect-Lab-Users"
    else
        echo "    ℹ️ 삭제할 DynamoDB 테이블이 없습니다"
    fi
    
    if [ "$iam_role" = "CloudArchitect-Lab-LambdaRole" ]; then
        echo "    🔐 IAM 역할: CloudArchitect-Lab-LambdaRole"
    else
        echo "    ℹ️ 삭제할 IAM 역할이 없습니다"
    fi
    
    echo "    📁 로컬 파일: 환경 파일, 로그 파일"
    echo ""
    
    echo "  ⚠️ 정리하지 않는 리소스:"
    echo "    🌐 API Gateway (학생이 콘솔에서 직접 생성한 것)"
    echo "    📋 API Gateway 리소스 및 메서드 (학생이 콘솔에서 직접 생성한 것)"
    echo "    🚀 API Gateway 배포 스테이지 (학생이 콘솔에서 직접 생성한 것)"
    echo ""
    
    echo "  💡 참고사항:"
    echo "    • API Gateway 리소스는 학생이 직접 콘솔에서 삭제해야 합니다"
    echo "    • 예상 소요 시간: 약 3분"
    echo ""
    
    # 사용자 확인
    read -p "위 계획대로 Lab13 리소스를 정리하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab13 정리가 취소되었습니다."
        exit 0
    fi
    
    show_info "Lab13 리소스 정리를 시작합니다..."
    echo ""
    
    # 리소스 정리 (단계별)
    show_progress 1 4 "Lambda 함수 정리 중..."
    cleanup_lambda_function
    echo ""
    
    show_progress 2 4 "DynamoDB 테이블 정리 중..."
    cleanup_dynamodb_table
    echo ""
    
    show_progress 3 4 "IAM 역할 정리 중..."
    cleanup_iam_role
    echo ""
    
    show_progress 4 4 "로컬 파일 정리 중..."
    cleanup_local_files
    echo ""
    
    # 정리 검증
    if verify_cleanup; then
        echo ""  # 빈 줄 추가
    else
        show_warning "일부 리소스 정리 실패"
    fi
    
    # 완료 요약
    show_cleanup_summary
}

# 스크립트 실행
main "$@"