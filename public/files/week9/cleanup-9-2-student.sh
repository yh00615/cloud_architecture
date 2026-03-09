#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Week9: AWS Lambda 함수 개발 - 서버리스 컴퓨팅 구현 정리
# 목적: Week9에서 생성된 모든 AWS 리소스를 안전하게 정리
# ===========================================



# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 공통 표시 함수들
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

echo "================================"
echo "Week9 정리 스크립트"
echo "================================"
echo "목적: Week9에서 생성된 모든 리소스 정리"
echo "================================"
echo ""

show_warning "⚠️ 이 스크립트는 Week9에서 생성된 모든 리소스를 삭제합니다."
echo ""

read -p "정말로 모든 리소스를 삭제하시겠습니까? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    show_info "작업이 취소되었습니다."
    exit 0
fi

echo ""
show_step "Week9 리소스 정리 시작"
echo ""

# 환경 정보 파일에서 리소스 정보 로드
if [ -f "week9-prerequisites.env" ]; then
    source week9-prerequisites.env
    show_info "📋 환경 정보 파일에서 리소스 정보 로드됨"
else
    show_warning "⚠️ 환경 정보 파일을 찾을 수 없습니다."
fi

# Lambda 함수 정리
cleanup_lambda_functions() {
    
    local function_name="CloudArchitect-Lab-UsersAPI"
    
    if aws lambda get-function --function-name "$function_name" >/dev/null 2>&1; then
        show_info "🗑️ Lambda 함수 삭제 중: $function_name"
        aws lambda delete-function --function-name "$function_name"
        show_success "✅ Lambda 함수 삭제 완료: $function_name"
    else
        show_info "ℹ️ Lambda 함수 이미 삭제됨: $function_name"
    fi
}

# IAM 역할 정리
cleanup_iam_roles() {
    
    local role_name="CloudArchitect-Lab-LambdaExecutionRole"
    
    if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
        show_info "🗑️ IAM 역할 정책 분리 중: $role_name"
        
        # 연결된 정책들 분리
        aws iam detach-role-policy --role-name "$role_name" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null || true
        aws iam delete-role-policy --role-name "$role_name" --policy-name "DynamoDBAccess" 2>/dev/null || true
        
        # 역할 삭제
        aws iam delete-role --role-name "$role_name"
        show_success "✅ IAM 역할 삭제 완료: $role_name"
    else
        show_info "ℹ️ IAM 역할 이미 삭제됨: $role_name"
    fi
}

# DynamoDB 테이블 삭제 (setup에서 생성한 것)
cleanup_dynamodb_table() {
    
    local table_name="CloudArchitect-Lab-Users"
    
    # 테이블 존재 확인
    if aws dynamodb describe-table --table-name "$table_name" >/dev/null 2>&1; then
        show_info "DynamoDB 테이블 삭제 중: $table_name"
        
        if aws dynamodb delete-table --table-name "$table_name" >/dev/null 2>&1; then
            show_success "✅ DynamoDB 테이블 삭제 완료: $table_name"
            
            # 테이블 삭제 완료까지 대기
            show_info "테이블 삭제 완료 대기 중..."
            aws dynamodb wait table-not-exists --table-name "$table_name" 2>/dev/null || true
            show_success "✅ DynamoDB 테이블 삭제 확인 완료"
        else
            show_error "❌ DynamoDB 테이블 삭제 실패: $table_name"
        fi
    else
        show_info "ℹ️ DynamoDB 테이블 이미 삭제됨: $table_name"
    fi
}

# 로컬 파일 정리
cleanup_local_files() {
    
    local files_to_remove=(
        "lambda_function.py"
        "lambda-function.zip"
        "lambda-package"
        "trust-policy.json"
        "dynamodb-policy.json"
        "test-event.json"
        "test-get-event.json"
        "response.json"
        "response-get.json"
        "cloudscape-demo.html"
        "week9-prerequisites.env"
        "lambda-test.sh"
    )
    
    for item in "${files_to_remove[@]}"; do
        if [ -f "$item" ] || [ -d "$item" ]; then
            rm -rf "$item"
            show_info "🗑️ 삭제됨: $item"
        fi
    done
    
    show_success "✅ 로컬 파일 정리 완료"
}

# 정리 작업 실행 (단계별)
show_progress 1 4 "Lambda 함수 정리 중..."
cleanup_lambda_functions
echo ""

show_progress 2 4 "IAM 역할 정리 중..."
cleanup_iam_roles
echo ""

show_progress 3 4 "DynamoDB 테이블 정리 중..."
cleanup_dynamodb_table
echo ""

show_progress 4 4 "로컬 파일 정리 중..."
cleanup_local_files

echo ""
echo "==========================================="
show_success "Week9 정리 완료!"
echo "==========================================="
echo -e "${CYAN}📋 정리된 리소스${NC}"
echo "• Lambda 함수: CloudArchitect-Lab-UsersAPI"
echo "• IAM 역할: CloudArchitect-Lab-LambdaExecutionRole"
echo "• DynamoDB 테이블: CloudArchitect-Lab-Users"
echo "• 로컬 시연 파일들"
echo ""
echo -e "${YELLOW}💡 참고사항${NC}"
echo "• Lambda 함수 삭제로 서버리스 비용 절약"
echo "• IAM 역할 정리로 보안 정책 정리"
echo "• CloudWatch 로그는 자동으로 만료됩니다"
echo "==========================================="