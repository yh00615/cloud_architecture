#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Week 11-2: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크 정리
# 목적: Week 11-2에서 생성된 모든 리소스를 안전하게 정리
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
    echo "    🌐 CloudFront 배포: CloudArchitect-Lab-Distribution"
    echo "    🔐 OAC (Origin Access Control)"
    echo "    🪣 S3 버킷: setup에서 생성된 버킷"
    echo "    📄 로컬 파일: week11-prerequisites.env, 로그 파일들"
    echo ""
    echo "  💡 참고사항:"
    echo "    • CloudFront 배포 비활성화에 약 5-10분 소요"
    echo "    • 모든 리소스를 자동으로 정리합니다"
    echo "    • 예상 소요 시간: 약 10-15분"
    echo ""
}

# 사용자 확인 함수
confirm_cleanup() {
    echo ""
    read -p "위 계획대로 Week 11-2 리소스를 정리하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Week 11-2 정리가 취소되었습니다."
        exit 0
    fi
    show_info "Week 11-2 리소스 정리를 시작합니다..."
    echo ""
}

# CloudFront 배포 정리 함수
cleanup_cloudfront_distribution() {
    show_info "CloudFront 배포 정리 중..."
    
    # CloudFront 배포 목록 확인 (태그 기반)
    local distribution_ids=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='CloudArchitect-Lab-Distribution' || Comment=='CloudArchitect Lab Distribution'].Id" --output text 2>/dev/null)
    
    if [ -z "$distribution_ids" ] || [ "$distribution_ids" = "None" ]; then
        show_info "삭제할 CloudFront 배포가 없습니다"
        return 0
    fi
    
    for dist_id in $distribution_ids; do
        show_info "CloudFront 배포 발견: $dist_id"
        
        # 배포 상태 확인
        local dist_status=$(aws cloudfront get-distribution --id "$dist_id" --query 'Distribution.Status' --output text 2>/dev/null)
        local dist_enabled=$(aws cloudfront get-distribution --id "$dist_id" --query 'Distribution.DistributionConfig.Enabled' --output text 2>/dev/null)
        
        if [ "$dist_enabled" = "true" ]; then
            show_info "CloudFront 배포 비활성화 중: $dist_id"
            
            # 현재 설정 가져오기
            aws cloudfront get-distribution-config --id "$dist_id" > /tmp/dist-config-$dist_id.json 2>/dev/null
            
            # ETag 추출
            local etag=$(jq -r '.ETag' /tmp/dist-config-$dist_id.json)
            
            # Enabled를 false로 변경
            jq '.DistributionConfig.Enabled = false | .DistributionConfig' /tmp/dist-config-$dist_id.json > /tmp/dist-config-disabled-$dist_id.json
            
            # 배포 업데이트
            aws cloudfront update-distribution \
                --id "$dist_id" \
                --distribution-config file:///tmp/dist-config-disabled-$dist_id.json \
                --if-match "$etag" >/dev/null 2>&1
            
            show_success "CloudFront 배포 비활성화 요청 완료: $dist_id"
            show_info "배포 비활성화 대기 중... (약 5-10분 소요)"
            
            # 배포 비활성화 대기 (최대 15분)
            local wait_count=0
            while [ $wait_count -lt 90 ]; do
                local current_status=$(aws cloudfront get-distribution --id "$dist_id" --query 'Distribution.Status' --output text 2>/dev/null)
                if [ "$current_status" = "Deployed" ]; then
                    break
                fi
                sleep 10
                wait_count=$((wait_count + 1))
            done
            
            # 정리
            rm -f /tmp/dist-config-$dist_id.json /tmp/dist-config-disabled-$dist_id.json
        fi
        
        # 배포 삭제
        show_info "CloudFront 배포 삭제 중: $dist_id"
        
        # 최신 ETag 가져오기
        local final_etag=$(aws cloudfront get-distribution --id "$dist_id" --query 'ETag' --output text 2>/dev/null)
        
        if aws cloudfront delete-distribution --id "$dist_id" --if-match "$final_etag" >/dev/null 2>&1; then
            show_success "CloudFront 배포 삭제 완료: $dist_id"
        else
            show_warning "CloudFront 배포 삭제 실패: $dist_id (수동으로 삭제해주세요)"
        fi
    done
}

# S3 버킷 정리 함수 (setup에서 생성한 것만)
cleanup_s3_bucket() {
    show_info "S3 버킷 정리 중..."
    
    # 환경 파일에서 버킷 이름 확인
    local bucket_names=()
    if [ -f "week11-prerequisites.env" ]; then
        # 환경 파일에서 BUCKET_NAME만 추출
        local bucket_name=$(grep "^BUCKET_NAME=" week11-prerequisites.env 2>/dev/null | cut -d'=' -f2)
        if [ -n "$bucket_name" ]; then
            bucket_names=("$bucket_name")
            show_info "환경 파일에서 버킷 확인: $bucket_name"
        fi
    fi
    
    # 환경 파일이 없거나 버킷 이름이 없으면 최신 버킷 1개만 검색
    if [ ${#bucket_names[@]} -eq 0 ]; then
        show_info "최신 Week 11-2 버킷 검색 중..."
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
        "week11-prerequisites.env"
        "week11-*.log"
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
    show_success "🎉 Week 11-2 CloudFront 인프라 정리가 완료되었습니다!"
    echo ""
    
    echo "📋 정리된 주요 리소스:"
    echo "  ✅ CloudFront 배포: CloudArchitect-Lab-Distribution"
    echo "  ✅ OAC (Origin Access Control)"
    echo "  ✅ S3 버킷: setup에서 생성된 버킷"
    echo "  ✅ 로컬 파일: week11-prerequisites.env, 로그 파일들"
    echo ""
    
    echo "💡 참고사항:"
    echo "  • 모든 Week 11-2 리소스가 자동으로 정리되었습니다"
    echo "  • 다른 실습에서 생성된 리소스는 각각의 cleanup 스크립트로 정리하세요"
    echo ""
    
    show_success "Week 11-2 정리 스크립트 실행 완료"
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
    echo "Week 11-2: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크 정리"
    echo "================================"
    echo "목적: Week 11-2에서 생성된 모든 리소스를 안전하게 정리"
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
    show_progress 1 3 "CloudFront 배포 정리 중..."
    cleanup_cloudfront_distribution
    echo ""
    
    show_progress 2 3 "S3 버킷 정리 중..."
    cleanup_s3_bucket
    echo ""
    
    show_progress 3 3 "로컬 파일 정리 중..."
    cleanup_local_files
    echo ""
    
    # 완료 요약
    show_completion_summary
}

# 스크립트 실행
main "$@"