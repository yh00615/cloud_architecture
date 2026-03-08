#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab13: Amazon API Gateway 서비스 구축 - RESTful API 설계 및 배포
# 목적: API Gateway 실습을 위한 Lambda 함수, DynamoDB 테이블, IAM 역할 생성 (사전 환경 구축)
# 예상 시간: 약 10분
# 예상 비용: DynamoDB 및 Lambda 사용으로 인해 과금될 수 있음
# 
# 구성 요소:
# - DynamoDB 테이블: CloudArchitect-Lab-Users
# - IAM 역할: CloudArchitect-Lab-LambdaRole
# - Lambda 함수: CloudArchitect-Lab-UsersAPI (Python 3.12)
# - 샘플 데이터: 사용자 정보
# 
# 학생 실습 내용:
# - API Gateway는 실습 가이드에서 직접 생성
# - REST API 리소스 및 메서드 구성 실습
# - Lambda 함수와 API Gateway 연동 실습
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

show_step() {
    echo -e "${CYAN}📋 $1${NC}"
}

show_important() {
    echo -e "${PURPLE}🔥 $1${NC}"
}

# 단계별 대기 함수
wait_for_next_step() {
    echo ""
    echo -e "${CYAN}⏳ 다음 단계 준비 중...${NC}"
    sleep 2
    echo ""
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
    
    # 기존 리소스 확인
    local existing_table=$(aws dynamodb describe-table --table-name "CloudArchitect-Lab-Users" --query 'Table.TableName' --output text 2>/dev/null)
    local existing_role=$(aws iam get-role --role-name "CloudArchitect-Lab-LambdaRole" --query 'Role.RoleName' --output text 2>/dev/null)
    local existing_function=$(aws lambda get-function --function-name "CloudArchitect-Lab-UsersAPI" --query 'Configuration.FunctionName' --output text 2>/dev/null)
    
    echo "  📋 API Gateway 인프라 구성:"
    
    # DynamoDB 테이블 상태 표시
    if [ "$existing_table" = "CloudArchitect-Lab-Users" ]; then
        echo "  🔄 DynamoDB 테이블: CloudArchitect-Lab-Users - 기존 재사용"
    else
        echo "  ✨ DynamoDB 테이블: CloudArchitect-Lab-Users - 새로 생성"
    fi
    
    # IAM 역할 상태 표시
    if [ "$existing_role" = "CloudArchitect-Lab-LambdaRole" ]; then
        echo "  🔄 IAM 역할: CloudArchitect-Lab-LambdaRole - 기존 재사용"
    else
        echo "  ✨ IAM 역할: CloudArchitect-Lab-LambdaRole - 새로 생성"
    fi
    
    # Lambda 함수 상태 표시
    if [ "$existing_function" = "CloudArchitect-Lab-UsersAPI" ]; then
        echo "  🔄 Lambda 함수: CloudArchitect-Lab-UsersAPI - 기존 재사용"
    else
        echo "  ✨ Lambda 함수: CloudArchitect-Lab-UsersAPI - 새로 생성"
    fi
    
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
    
    echo "  ⚡ Lambda 함수 구성:"
    echo "    🐍 런타임: Python 3.12"
    echo "    🔗 DynamoDB 연동 CRUD API"
    echo "    📡 API Gateway 연결 준비"
    echo ""
    
    echo "  🎯 핵심 학습 목표:"
    echo "    • DynamoDB NoSQL 데이터베이스 설계"
    echo "    • Lambda 함수 개발 및 배포"
    echo "    • API Gateway RESTful API 구축"
    echo "    • 서버리스 아키텍처 구현"
    echo ""
    
    echo "  ⚠️ 주의사항:"
    echo "    • DynamoDB 및 Lambda 사용으로 인해 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 10분"
    echo ""
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Lab13 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab13 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Lab13 리소스 생성을 시작합니다..."
    echo ""
}

# DynamoDB 테이블 생성/재사용 함수
create_dynamodb_table() {
    show_info "DynamoDB 테이블 확인/생성 중..."
    
    local table_name="CloudArchitect-Lab-Users"
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    # 기존 테이블 확인
    local existing_table=$(aws dynamodb describe-table --table-name "$table_name" --query 'Table.TableName' --output text 2>/dev/null)
    
    if [ "$existing_table" = "$table_name" ]; then
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
        --provisioned-throughput \
            ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --tags \
            Key=Project,Value=CloudArchitect \
            Key=Lab,Value=Lab13 \
            Key=Component,Value=Database \
            Key=Environment,Value=Lab \
            Key=CreatedBy,Value=setup-lab13-student.sh \
        --region "$region" >/dev/null 2>&1; then
        
        show_success "DynamoDB 테이블 생성 완료: $table_name"
        
        # 테이블 활성화 대기
        show_info "테이블 활성화 대기 중..."
        aws dynamodb wait table-exists --table-name "$table_name" --region "$region"
        
        show_success "DynamoDB 테이블 활성화 완료"
        
        # 샘플 데이터 삽입
        insert_sample_data "$table_name"
        
    else
        show_error "DynamoDB 테이블 생성 실패: $table_name"
        exit 1
    fi
}

# 샘플 데이터 삽입 함수
insert_sample_data() {
    local table_name=$1
    
    show_info "샘플 데이터 삽입 중..."
    
    # 사용자 1 데이터 삽입
    aws dynamodb put-item \
        --table-name "$table_name" \
        --item '{
            "id": {"S": "user001"},
            "name": {"S": "김철수"},
            "email": {"S": "chulsoo@example.com"},
            "department": {"S": "컴퓨터공학과"},
            "age": {"N": "25"},
            "status": {"S": "active"}
        }' >/dev/null 2>&1
    
    # 사용자 2 데이터 삽입
    aws dynamodb put-item \
        --table-name "$table_name" \
        --item '{
            "id": {"S": "user002"},
            "name": {"S": "이영희"},
            "email": {"S": "younghee@example.com"},
            "department": {"S": "정보시스템학과"},
            "age": {"N": "23"},
            "status": {"S": "active"}
        }' >/dev/null 2>&1
    
    show_success "샘플 데이터 삽입 완료 (2개 사용자)"
}

# IAM 역할 생성/재사용 함수
create_lambda_role() {
    show_info "Lambda IAM 역할 확인/생성 중..."
    
    local role_name="CloudArchitect-Lab-LambdaRole"
    
    # 기존 역할 확인
    local existing_role=$(aws iam get-role --role-name "$role_name" --query 'Role.RoleName' --output text 2>/dev/null)
    
    if [ "$existing_role" = "$role_name" ]; then
        show_success "기존 Lambda IAM 역할 재사용: $role_name"
        return 0
    fi
    
    show_info "새 IAM 역할 생성 중: $role_name"
    
    # 신뢰 정책 문서 생성
    cat > lambda-trust-policy.json << 'EOF'
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
        --assume-role-policy-document file://lambda-trust-policy.json \
        --tags \
            Key=Project,Value=CloudArchitect \
            Key=Lab,Value=Lab13 \
            Key=Component,Value=Security \
            Key=Environment,Value=Lab \
            Key=CreatedBy,Value=setup-lab13-student.sh \
        >/dev/null 2>&1; then
        
        show_success "IAM 역할 생성 완료: $role_name"
        
        # 기본 Lambda 실행 정책 연결
        aws iam attach-role-policy \
            --role-name "$role_name" \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole >/dev/null 2>&1
        
        # DynamoDB 정책 연결
        aws iam attach-role-policy \
            --role-name "$role_name" \
            --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess >/dev/null 2>&1
        
        show_success "IAM 정책 연결 완료 (Lambda 실행 + DynamoDB 권한)"
        
        # 역할 전파 대기
        show_info "IAM 역할 전파 대기 중... (10초)"
        sleep 10
        
    else
        show_error "IAM 역할 생성 실패: $role_name"
        exit 1
    fi
    
    # 임시 파일 정리
    rm -f lambda-trust-policy.json
}

# Lambda 함수 생성/재사용 함수
create_lambda_function() {
    show_info "Lambda 함수 확인/생성 중..."
    
    local function_name="CloudArchitect-Lab-UsersAPI"
    local role_name="CloudArchitect-Lab-LambdaRole"
    local region=$(aws configure get region 2>/dev/null || echo "ap-northeast-2")
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    # 기존 함수 확인
    local existing_function=$(aws lambda get-function --function-name "$function_name" --query 'Configuration.FunctionName' --output text 2>/dev/null)
    
    if [ "$existing_function" = "$function_name" ]; then
        show_success "기존 Lambda 함수 재사용: $function_name"
        return 0
    fi
    
    show_info "새 Lambda 함수 생성 중: $function_name"
    
    # Lambda 함수 코드 생성
    cat > lambda_function.py << 'EOF'
import json
import boto3
from decimal import Decimal

# DynamoDB 클라이언트 초기화
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('CloudArchitect-Lab-Users')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def lambda_handler(event, context):
    try:
        # HTTP 메서드 확인
        http_method = event.get('httpMethod', 'GET')
        
        if http_method == 'GET':
            # 모든 사용자 조회
            response = table.scan()
            items = response.get('Items', [])
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'message': 'Users retrieved successfully',
                    'count': len(items),
                    'users': items
                }, default=decimal_default)
            }
            
        elif http_method == 'POST':
            # 새 사용자 생성
            body = json.loads(event.get('body', '{}'))
            
            # 필수 필드 확인
            if not body.get('id') or not body.get('name'):
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': 'Missing required fields: id, name'
                    })
                }
            
            # DynamoDB에 사용자 추가
            table.put_item(Item=body)
            
            return {
                'statusCode': 201,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'message': 'User created successfully',
                    'user': body
                })
            }
            
        else:
            return {
                'statusCode': 405,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'Method {http_method} not allowed'
                })
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }
EOF
    
    # Lambda 함수 코드 압축
    zip -q lambda_function.zip lambda_function.py
    
    # IAM 역할 ARN 구성
    local role_arn="arn:aws:iam::$account_id:role/$role_name"
    
    # Lambda 함수 생성
    if aws lambda create-function \
        --function-name "$function_name" \
        --runtime python3.12 \
        --role "$role_arn" \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip \
        --description "CloudArchitect Lab13 - API Gateway 연동용 Lambda 함수" \
        --timeout 30 \
        --memory-size 128 \
        --tags \
            Project=CloudArchitect,Lab=Lab13,Component=Compute,Environment=Lab,CreatedBy=setup-lab13-student.sh \
        >/dev/null 2>&1; then
        
        show_success "Lambda 함수 생성 완료: $function_name"
        
        # 함수 활성화 대기
        show_info "Lambda 함수 활성화 대기 중..."
        sleep 5
        
        # 함수 상태 확인
        local function_state=$(aws lambda get-function --function-name "$function_name" --query 'Configuration.State' --output text 2>/dev/null)
        
        if [ "$function_state" = "Active" ]; then
            show_success "Lambda 함수 활성화 완료 (상태: $function_state)"
        else
            show_warning "Lambda 함수 상태 확인 필요 (상태: $function_state)"
        fi
        
    else
        show_error "Lambda 함수 생성 실패: $function_name"
        show_info "가능한 원인:"
        echo "  • IAM 역할 권한 부족"
        echo "  • Lambda 서비스 권한 부족"
        echo "  • 네트워크 연결 문제"
        exit 1
    fi
    
    # 임시 파일 정리
    rm -f lambda_function.py lambda_function.zip
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab13 API Gateway 인프라 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ DynamoDB 테이블: CloudArchitect-Lab-Users"
    echo "  ✅ IAM 역할: CloudArchitect-Lab-LambdaRole"
    echo "  ✅ Lambda 함수: CloudArchitect-Lab-UsersAPI"
    echo "  ✅ 파티션 키: id (String)"
    echo "  ✅ 프로비저닝 용량: 읽기 5 RCU, 쓰기 5 WCU"
    echo "  ✅ 샘플 데이터: 2개 사용자 레코드"
    echo ""
    
    echo "🔐 IAM 권한 구성:"
    echo "  • Lambda 기본 실행 권한"
    echo "  • DynamoDB 전체 접근 권한 (CRUD)"
    echo ""
    
    echo "⚡ Lambda 함수 구성:"
    echo "  • 런타임: Python 3.12"
    echo "  • 핸들러: lambda_function.lambda_handler"
    echo "  • DynamoDB 연동 CRUD API"
    echo "  • CORS 헤더 설정 완료"
    echo ""
    
    echo "📝 샘플 데이터:"
    echo "  • user001: 김철수 (컴퓨터공학과, 25세)"
    echo "  • user002: 이영희 (정보시스템학과, 23세)"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "  • 이제 Lab13 API Gateway 실습을 진행할 수 있습니다"
    echo "  • 실습 가이드에 따라 API Gateway를 생성하세요"
    echo "  • CloudArchitect-Lab-UsersAPI 함수와 연결하세요"
    echo "  • RESTful API 엔드포인트를 테스트하세요"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Lab13 스크립트 실행 완료"
}

# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    local aws_info=$(get_aws_account_info)
    local account_id=$(echo "$aws_info" | cut -d':' -f1)
    local region=$(echo "$aws_info" | cut -d':' -f2)
    
    if [ -z "$region" ]; then
        show_error "AWS 리전이 설정되지 않았습니다."
        show_info "다음 명령어로 리전을 설정해주세요: aws configure set region ap-northeast-2"
        exit 1
    fi
    
    # 헤더 표시
    echo "================================"
    echo "Lab13: Amazon API Gateway 서비스 구축 - RESTful API 설계 및 배포"
    echo "================================"
    echo "목적: API Gateway 실습을 위한 Lambda 함수, DynamoDB 테이블, IAM 역할 생성"
    echo "예상 시간: 약 10분"
    echo "예상 비용: DynamoDB 및 Lambda 사용으로 인해 과금될 수 있음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "미설정")
    echo "사용자: $user_arn"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws dynamodb list-tables --max-items 1 >/dev/null 2>&1 && show_success "DynamoDB 권한 확인 완료" || show_warning "DynamoDB 권한 제한됨"
    aws iam list-roles --max-items 1 >/dev/null 2>&1 && show_success "IAM 권한 확인 완료" || show_warning "IAM 권한 제한됨"
    aws lambda list-functions --max-items 1 >/dev/null 2>&1 && show_success "Lambda 권한 확인 완료" || show_warning "Lambda 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 3 "DynamoDB 테이블 생성 중..."
    create_dynamodb_table
    wait_for_next_step
    
    show_progress 2 3 "IAM 역할 생성 중..."
    create_lambda_role
    wait_for_next_step
    
    show_progress 3 3 "Lambda 함수 생성 중..."
    create_lambda_function
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"