#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Lab16: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크 정리
# 목적: setup-lab16-student.sh에서 생성된 S3 버킷만 정리
# 주의: 학생이 콘솔에서 생성한 CloudFront 배포는 정리하지 않음
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

# 삭제 계획 표시 함수
show_cleanup_plan() {
    echo ""
    show_important "🗑️ 삭제 계획:"
    echo ""
    echo "  📋 정리할 리소스:"
    echo "    🪣 S3 버킷: setup에서 생성된 버킷 (환경 파일 기준)"
    echo "    📄 로컬 파일: lab16-prerequisites.env, 로그 파일들"
    echo ""
    echo "  ⚠️ 정리하지 않는 리소스:"
    echo "    🌐 CloudFront 배포 (학생이 콘솔에서 직접 생성한 것)"
    echo "    🔐 OAC (Origin Access Control) - CloudFront 배포와 함께 삭제됨"
    echo "    📁 기타 S3 버킷 (다른 실습에서 생성된 것)"
    echo ""
    echo "  💡 참고사항:"
    echo "    • CloudFront 배포는 학생이 직접 콘솔에서 삭제해야 합니다"
    echo "    • 예상 소요 시간: 약 2분"
    echo ""
}

# 사용자 확인 함수
confirm_cleanup() {
    echo ""
    read -p "위 계획대로 Lab16 리소스를 정리하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Lab16 정리가 취소되었습니다."
        exit 0
    fi
    show_info "Lab16 리소스 정리를 시작합니다..."
    echo ""
}

# S3 버킷 정리 함수 (setup에서 생성한 것만)
cleanup_s3_bucket() {
    show_info "S3 버킷 정리 중..."
    
    # 환경 파일에서 버킷 이름 확인
    local bucket_names=()
    if [ -f "lab16-prerequisites.env" ]; then
        # 환경 파일에서 BUCKET_NAME만 추출
        local bucket_name=$(grep "^BUCKET_NAME=" lab16-prerequisites.env 2>/dev/null | cut -d'=' -f2)
        if [ -n "$bucket_name" ]; then
            bucket_names=("$bucket_name")
            show_info "환경 파일에서 버킷 확인: $bucket_name"
        fi
    fi
    
    # 환경 파일이 없거나 버킷 이름이 없으면 최신 버킷 1개만 검색
    if [ ${#bucket_names[@]} -eq 0 ]; then
        show_info "최신 Lab16 버킷 검색 중..."
        local latest_bucket=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'cloudarchitect-lab-s3website-')] | sort_by(@, &CreationDate) | [-1].Name" --output text 2>/dev/null)
        if [ -n "$latest_bucket" ] && [ "$latest_bucket" != "None" ]; then
            bucket_names=("$latest_bucket")
        fi
    fi
    
    if [ ${#bucket_names[@]} -eq 0 ]; then
        show_info "정리할 S3 버킷이 없습니다."
        return 0
    fi
    
    # 각 버킷을 개별적으로 삭제
    for bucket_name in "${bucket_names[@]}"; do
        if [ -z "$bucket_name" ] || [ "$bucket_name" = "None" ]; then
            continue
        fi
        
        show_info "S3 버킷 삭제 중: $bucket_name"
        
        # 버킷 내 모든 객체 삭제
        show_info "버킷 내 객체 삭제 중..."
        aws s3 rm s3://$bucket_name --recursive >/dev/null 2>&1 || true
        
        # 버킷 삭제
        if aws s3api delete-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
            show_success "S3 버킷 삭제 완료: $bucket_name"
        else
            show_warning "S3 버킷 삭제 실패: $bucket_name (수동으로 삭제해주세요)"
        fi
    done
}

# 로컬 파일 정리 함수
cleanup_local_files() {
    show_info "로컬 파일 정리 중..."
    
    local files_to_remove=(
        "lab16-prerequisites.env"
        "lab16-student-*.log"
        "lab16-cleanup-*.log"
    )
    
    for file_pattern in "${files_to_remove[@]}"; do
        if ls $file_pattern 1> /dev/null 2>&1; then
            rm -f $file_pattern
            show_success "로컬 파일 삭제 완료: $file_pattern"
        fi
    done
    
    show_success "로컬 파일 정리 완료"
}

# 완료 요약 표시 함수
show_completion_summary() {
    echo ""
    show_success "🎉 Lab16 CloudFront 인프라 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 정리된 주요 리소스:"
    echo "  ✅ S3 버킷: setup에서 생성된 버킷 (환경 파일 기준)"
    echo "  ✅ 로컬 파일: lab16-prerequisites.env, 로그 파일들"
    echo ""
    
    echo "⚠️ 수동으로 정리해야 할 리소스:"
    echo "  🌐 CloudFront 배포 (학생이 콘솔에서 생성한 것)"
    echo "    - CloudFront 콘솔에서 배포를 먼저 비활성화(Disable)한 후 삭제"
    echo "    - 비활성화 완료까지 약 15-20분 소요"
    echo "    - 비활성화 완료 후 삭제 가능"
    echo "  🔐 OAC (Origin Access Control)"
    echo "    - CloudFront 배포 삭제 시 자동으로 정리됨"
    echo ""
    
    echo "💡 참고사항:"
    echo "  • CloudFront 배포 삭제는 콘솔에서 수동으로 진행해주세요"
    echo "  • CloudFront 배포 삭제 순서: Disable → 대기(15-20분) → Delete"
    echo "  • OAC는 CloudFront 배포 삭제 시 자동으로 정리됩니다"
    echo "  • 다른 실습에서 생성된 리소스는 각각의 cleanup 스크립트로 정리"
    echo ""
    
    show_success "Lab16 정리 스크립트 실행 완료"
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
    echo "Lab16: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크 정리"
    echo "================================"
    echo "목적: setup-lab16-student.sh에서 생성된 S3 버킷만 정리"
    echo "주의: 학생이 콘솔에서 생성한 CloudFront 배포는 정리하지 않음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo ""
    
    # 삭제 계획 표시 및 사용자 확인
    show_cleanup_plan
    confirm_cleanup
    
    # 리소스 정리 (단계별)
    show_progress 1 2 "S3 버킷 정리 중..."
    cleanup_s3_bucket
    echo ""
    
    show_progress 2 2 "로컬 파일 정리 중..."
    cleanup_local_files
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"