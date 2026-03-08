#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}

# ================================
# Lab12: AWS Lambda 함수 개발 - 서버리스 컴퓨팅 구현
# ================================
# 목적: Lambda 실습을 위한 DynamoDB 테이블 및 IAM 역할 생성
# 예상 시간: 약 10분
# 예상 비용: DynamoDB 프로비저닝 용량으로 인해 과금될 수 있음
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

# AWS CLI 프로필 및 리전 확인
get_aws_account_info() {
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local region=$(aws configure get region 2>/dev/null)
    
    if [ -z "$account_id" ]; then
        show_error "AWS 자격 증명을 확인할 수 없습니다."
        show_info "다음 명령어로 AWS CLI를 설정해주세요:"
        echo "  aws configure"
        exit 1
    fi
    
    echo "$account_id:$region"
}

# 생성 계획 표시 함수
show_creation_plan() {
    echo ""
    show_important "🚀 생성 계획:"
    echo ""
    echo "  📋 서버리스 인프라 구성:"
    echo "    🗄️ DynamoDB 테이블: CloudArchitect-Lab-Users"
    echo "    🔐 IAM 역할: CloudArchitect-Lab-LambdaExecutionRole"
    echo ""
    echo "  🏗️ 테이블 구성:"
    echo "    📝 파티션 키: id (String)"
    echo "    ⚡ 프로비저닝 용량: 읽기 5 RCU, 쓰기 5 WCU"
    echo "    📊 샘플 데이터: 2개 사용자 레코드"
    echo ""
    echo "  🔒 IAM 권한 구성:"
    echo "    🔧 Lambda 기본 실행 권한"
    echo "    🗄️ DynamoDB 전체 접근 권한 (CRUD)"
    echo ""
    echo "  🎯 핵심 학습 목표:"
    echo "    • DynamoDB NoSQL 데이터베이스 설계"
    echo "    • Lambda 함수용 IAM 역할 구성"
    echo "    • 서버리스 아키텍처 보안 모델"
    echo ""
    echo "  ⚠️ 주의사항:"
    echo "    • DynamoDB 프로비저닝 용량으로 인해 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 10분"
    echo ""
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab12 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab12 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab12 리소스 생성을 시작합니다..."
    echo ""
}

# DynamoDB 테이블 생성 함수
create_dynamodb_table() {
    local table_name="CloudArchitect-Lab-Users"
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    
    show_info "DynamoDB 테이블 확인/생성 중..."
    
    # 기존 테이블 확인
    if aws dynamodb describe-table --table-name "$table_name" >/dev/null 2>&1; then
        show_success "기존 DynamoDB 테이블 재사용: $table_name"
        return 0
    fi
    
    show_info "새 DynamoDB 테이블 생성 중: $table_name"
    
    # DynamoDB 테이블 생성
    if aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions \
            AttributeName=id,AttributeType=S \
        --key-schema \
            AttributeName=id,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$region" >/dev/null 2>&1; then
        
        show_info "테이블 생성 요청 완료, 활성화 대기 중..."
        
        # 테이블 활성화 대기
        if aws dynamodb wait table-exists --table-name "$table_name" --region "$region"; then
            show_success "DynamoDB 테이블 활성화 완료: $table_name"
            
            # 태그 추가
            aws dynamodb tag-resource \
                --resource-arn "arn:aws:dynamodb:$region:$account_id:table/$table_name" \
                --tags \
                    Key=Project,Value=CloudArchitect \
                    Key=Demo,Value=Lab12 \
                    Key=Component,Value=Database \
                    Key=Environment,Value=Lab \
                    Key=CreatedBy,Value=setup-lab12-student.sh \
                2>/dev/null || true
            
            # 샘플 데이터 추가
            show_info "샘플 데이터 추가 중..."
            aws dynamodb put-item \
                --table-name "$table_name" \
                --item '{
                    "id": {"S": "user001"},
                    "name": {"S": "김철수"},
                    "email": {"S": "kim@example.com"},
                    "age": {"N": "25"},
                    "department": {"S": "컴퓨터공학과"}
                }' \
                --region "$region" >/dev/null 2>&1
                
            aws dynamodb put-item \
                --table-name "$table_name" \
                --item '{
                    "id": {"S": "user002"},
                    "name": {"S": "이영희"},
                    "email": {"S": "lee@example.com"},
                    "age": {"N": "23"},
                    "department": {"S": "정보시스템학과"}
                }' \
                --region "$region" >/dev/null 2>&1
            
            show_success "샘플 데이터 추가 완료"
        else
            show_error "DynamoDB 테이블 활성화 실패: $table_name"
            return 1
        fi
    else
        show_error "DynamoDB 테이블 생성 실패: $table_name"
        return 1
    fi
}

# IAM 역할 생성 함수
create_lambda_role() {
    local role_name="CloudArchitect-Lab-LambdaExecutionRole"
    
    show_info "Lambda IAM 역할 확인/생성 중..."
    
    # 기존 역할 확인
    if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
        show_success "기존 IAM 역할 재사용: $role_name"
        return 0
    fi
    
    show_info "새 IAM 역할 생성 중: $role_name"
    
    # 신뢰 정책 생성
    cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    # IAM 역할 생성
    if aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document file://trust-policy.json \
        --description "CloudArchitect Lab12 - Lambda execution role for DynamoDB access" \
        >/dev/null 2>&1; then
        
        show_info "IAM 역할 생성 완료, 정책 연결 중..."
        
        # 기본 Lambda 실행 정책 연결
        aws iam attach-role-policy \
            --role-name "$role_name" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
            >/dev/null 2>&1
        
        # DynamoDB 접근 정책 생성 및 연결
        cat > dynamodb-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Scan",
                "dynamodb:Query"
            ],
            "Resource": "*"
        }
    ]
}
EOF
        
        aws iam put-role-policy \
            --role-name "$role_name" \
            --policy-name "DynamoDBAccess" \
            --policy-document file://dynamodb-policy.json \
            >/dev/null 2>&1
        
        # 태그 추가
        aws iam tag-role \
            --role-name "$role_name" \
            --tags \
                Key=Project,Value=CloudArchitect \
                Key=Demo,Value=Lab12 \
                Key=Component,Value=Security \
                Key=Environment,Value=Lab \
                Key=CreatedBy,Value=setup-lab12-student.sh \
            2>/dev/null || true
        
        # 임시 파일 정리
        rm -f trust-policy.json dynamodb-policy.json
        
        show_success "IAM 역할 및 정책 설정 완료: $role_name"
    else
        show_error "IAM 역할 생성 실패: $role_name"
        return 1
    fi
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab12 서버리스 인프라 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ DynamoDB 테이블: CloudArchitect-Lab-Users"
    echo "  ✅ IAM 역할: CloudArchitect-Lab-LambdaExecutionRole"
    echo "  ✅ 파티션 키: id (String)"
    echo "  ✅ 프로비저닝 용량: 읽기 5 RCU, 쓰기 5 WCU"
    echo "  ✅ 샘플 데이터: 2개 사용자 레코드"
    echo ""
    
    echo "🔐 IAM 권한 구성:"
    echo "  • Lambda 기본 실행 권한"
    echo "  • DynamoDB 전체 접근 권한 (CRUD)"
    echo ""
    
    echo "📝 샘플 데이터:"
    echo "  • user001: 김철수 (컴퓨터공학과, 25세)"
    echo "  • user002: 이영희 (정보시스템학과, 23세)"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "  • 이제 Lab12 Lambda 함수 개발 실습을 진행할 수 있습니다"
    echo "  • Lambda 함수 생성 시 CloudArchitect-Lab-LambdaExecutionRole을 선택하세요"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "✅ Lab12 스크립트 실행 완료"
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
    
    # 헤더 표시
    echo "================================"
    echo "Lab12: AWS Lambda 함수 개발 - 서버리스 컴퓨팅 구현"
    echo "================================"
    echo "목적: Lambda 실습을 위한 DynamoDB 테이블 및 IAM 역할 생성"
    echo "예상 시간: 약 10분"
    echo "예상 비용: DynamoDB 프로비저닝 용량으로 인해 과금될 수 있음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws dynamodb list-tables --max-items 1 >/dev/null 2>&1 && show_success "DynamoDB 권한 확인 완료" || show_warning "DynamoDB 권한 제한됨"
    aws iam list-roles --max-items 1 >/dev/null 2>&1 && show_success "IAM 권한 확인 완료" || show_warning "IAM 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 2 "DynamoDB 테이블 생성 중..."
    create_dynamodb_table
    echo ""
    
    show_progress 2 2 "IAM 역할 생성 중..."
    create_lambda_role
    echo ""
    
    # 환경 변수 저장
    cat > lab12-prerequisites.env << EOF
TABLE_NAME=CloudArchitect-Lab-Users
ROLE_NAME=CloudArchitect-Lab-LambdaExecutionRole
REGION=$region
ACCOUNT_ID=$account_id
EOF
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"
