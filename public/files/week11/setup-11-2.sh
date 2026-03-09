#!/bin/bash

# UTF-8 인코딩 설정 (로케일 오류 방지)
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export LC_CTYPE=${LC_CTYPE:-en_US.UTF-8}
# ===========================================
# Week 11-2: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크
# 목적: CloudFront 실습을 위한 S3 버킷 및 웹사이트 환경 생성
# 예상 시간: 약 2분
# 예상 비용: S3 스토리지 및 데이터 전송으로 인해 과금될 수 있음
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

# 생성 계획 표시 함수
show_creation_plan() {
    echo ""
    show_important "🚀 생성 계획:"
    echo ""
    echo "  📋 CloudFront 인프라 구성:"
    echo "    🪣 S3 버킷: cloudarchitect-lab-s3website-[계정 ID]"
    echo "    📄 샘플 파일: index.html, error.html"
    echo "    🔓 초기 퍼블릭 액세스: 임시 테스트용 (실습 중 OAC로 전환)"
    echo "    📝 환경 파일: week11-prerequisites.env (cleanup용)"
    echo ""
    echo "  🎯 핵심 학습 목표:"
    echo "    • S3 버킷을 CloudFront 오리진으로 구성"
    echo "    • OAC(Origin Access Control)를 통한 보안 강화 (AWS 권장 방식)"
    echo "    • CloudFront 배포 생성 및 Default root object 설정"
    echo "    • 글로벌 콘텐츠 전송 네트워크(CDN) 구축"
    echo ""
    echo "  ⚠️ 주의사항:"
    echo "    • S3 스토리지 및 데이터 전송으로 인해 과금될 수 있음"
    echo "    • 실습 완료 후 cleanup 스크립트 실행 필수"
    echo "    • 예상 소요 시간: 약 2분"
    echo ""
}

# 사용자 확인 함수
confirm_creation() {
    echo ""
    read -p "위 계획대로 Week 11-2 리소스를 생성하시겠습니까? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        show_info "Week 11-2 설정이 취소되었습니다."
        exit 0
    fi
    show_info "Week 11-2 리소스 생성을 시작합니다..."
    echo ""
}

# ===========================================
# S3 버킷 생성 함수
# ===========================================
create_s3_bucket() {
    local region=$(aws configure get region 2>/dev/null || echo "")
    local account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local bucket_name="cloudarchitect-lab-s3website-$account_id"
    
    # S3 버킷 생성 (메시지 출력 없이)
    if aws s3 mb "s3://$bucket_name" --region "$region" >/dev/null 2>&1; then
        # 태그 추가
        aws s3api put-bucket-tagging \
            --bucket "$bucket_name" \
            --tagging "TagSet=[
                {Key=Project,Value=CloudArchitect},
                {Key=Week,Value=Week11},
                {Key=Component,Value=Storage},
                {Key=Environment,Value=Lab},
                {Key=CreatedBy,Value=setup-11-2.sh}
            ]" 2>/dev/null || true
        
        # 버킷 이름만 반환
        echo "$bucket_name"
    else
        # 실패 시 빈 문자열 반환
        echo ""
    fi
}

# ===========================================
# 웹사이트 호스팅 설정 함수 (제거됨 - OAC 사용을 위해)
# ===========================================
# Note: S3 Website Endpoint는 CloudFront OAC와 호환되지 않습니다.
# AWS 공식 문서: "If your origin is an Amazon S3 bucket configured as a 
# website endpoint, you can't use OAC (or OAI)."
# 대신 CloudFront에서 S3 REST API endpoint를 사용하고 Default root object를 설정합니다.

# ===========================================
# 샘플 파일 업로드 함수
# ===========================================
upload_sample_files() {
    local bucket_name="$1"
    
    # index.html 생성 (메시지 출력 없이)
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>CloudArchitect Week11 - CloudFront</title>
    <style>
        body { font-family: Arial; text-align: center; background: #74b9ff; color: white; padding: 50px; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 CloudArchitect Week11</h1>
        <h2>CloudFront CDN 배포</h2>
        <p>✅ S3 정적 웹사이트 + CloudFront CDN</p>
        <p>전 세계 어디서나 빠른 콘텐츠 전송!</p>
    </div>
</body>
</html>
EOF
    
    # error.html 생성
    cat > error.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>Error - CloudArchitect Week11</title>
    <style>
        body { font-family: Arial; text-align: center; background: #e17055; color: white; padding: 50px; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>❌ 페이지를 찾을 수 없습니다</h1>
        <p>CloudArchitect Week11 - CloudFront 실습</p>
    </div>
</body>
</html>
EOF
    
    # 파일 업로드 (메시지 출력 없이)
    aws s3 cp index.html "s3://$bucket_name/" >/dev/null 2>&1
    aws s3 cp error.html "s3://$bucket_name/" >/dev/null 2>&1
    
    # 로컬 파일 정리
    rm -f index.html error.html
}

# ===========================================
# 버킷 정책 설정 함수
# ===========================================
configure_bucket_policy() {
    local bucket_name="$1"
    
    # 퍼블릭 액세스 차단 해제 (메시지 출력 없이)
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
        >/dev/null 2>&1
    
    # 버킷 정책 설정
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$bucket_name/*"
        }
    ]
}
EOF
    
    # 버킷 정책 적용 (메시지 출력 없이)
    aws s3api put-bucket-policy --bucket "$bucket_name" --policy file://bucket-policy.json >/dev/null 2>&1
    
    # 로컬 파일 정리
    rm -f bucket-policy.json
}

# 완료 요약 표시 함수
show_completion_summary() {
    local bucket_name=$1
    local region=$(aws configure get region 2>/dev/null || echo "")
    
    echo ""
    show_success "🎉 Week 11-2 CloudFront 인프라 구축이 완료되었습니다!"
    echo ""
    
    echo "📋 생성된 주요 리소스:"
    echo "  ✅ S3 버킷: $bucket_name"
    echo "  ✅ 샘플 파일: index.html, error.html"
    echo "  ✅ 초기 퍼블릭 액세스: 활성화 (임시)"
    echo "  ✅ 환경 파일: week11-prerequisites.env"
    echo ""
    
    echo "📝 중요 안내:"
    echo "  • S3 버킷은 CloudFront OAC 사용을 위해 일반 버킷으로 구성 (Website Endpoint 미사용)"
    echo "  • 실습 중 CloudFront 배포 생성 시 OAC를 설정하게 됩니다"
    echo "  • OAC 설정 후 버킷 정책을 CloudFront 전용으로 교체합니다"
    echo "  • OAC는 OAI보다 강력한 보안을 제공하며 AWS에서 권장하는 방식입니다"
    echo "  • 샘플 HTML 파일에는 인라인 CSS 스타일이 포함되어 있습니다 (별도 CSS 파일 불필요)"
    echo ""
    
    echo "🚀 다음 단계:"
    echo "  1. AWS 콘솔에서 CloudFront 서비스로 이동하세요"
    echo "  2. 'Create Distribution' 버튼을 클릭하여 새 배포를 생성하세요"
    echo "  3. Origin 설정:"
    echo "     • Origin domain: $bucket_name.s3.$region.amazonaws.com 선택"
    echo "     • Origin access: 'Origin access control settings (recommended)' 선택"
    echo "     • OAC 생성 후 자동 생성되는 버킷 정책을 복사하여 S3에 적용"
    echo "  4. Default root object: 'index.html' 입력"
    echo "  5. 배포 생성 후 Domain name을 통해 웹사이트에 접속하세요"
    echo "  6. OAC를 통한 보안 강화 및 글로벌 CDN을 경험하세요"
    echo ""
    
    echo "💰 비용 절약: cleanup 스크립트로 리소스를 정리하세요"
    echo ""
    
    show_success "Week 11-2 스크립트 실행 완료"
    
    # 환경 변수 저장 (cleanup에서 사용)
    cat > week11-prerequisites.env << EOF
BUCKET_NAME=$bucket_name
REGION=$region
EOF
}

# 메인 실행 함수
main() {
    # AWS 계정 정보 확인
    aws_info=$(get_aws_account_info)
    account_id=$(echo "$aws_info" | cut -d':' -f1)
    region=$(echo "$aws_info" | cut -d':' -f2)
    
    if [ -z "$region" ]; then
        show_error "AWS 리전이 설정되지 않았습니다."
        show_info "다음 명령어로 리전을 설정해주세요: aws configure set region <your-region>"
        exit 1
    fi
    
    # REGION 변수를 전역으로 export
    export REGION="$region"
    
    # 헤더 표시
    echo "================================"
    echo "Week 11-2: Amazon CloudFront 배포 구성 - 글로벌 콘텐츠 전송 네트워크"
    echo "================================"
    echo "목적: CloudFront 실습을 위한 S3 버킷 및 웹사이트 환경 생성"
    echo "예상 시간: 약 2분"
    echo "예상 비용: S3 스토리지 및 데이터 전송으로 인해 과금될 수 있음"
    echo "================================"
    echo ""
    
    # AWS 환경 확인
    show_info "AWS 환경 확인 중..."
    echo "현재 리전: $region"
    echo "계정 ID: $account_id"
    echo ""
    
    # 필수 권한 확인
    show_info "필수 AWS 서비스 권한 확인 중..."
    aws s3 ls >/dev/null 2>&1 && show_success "S3 권한 확인 완료" || show_warning "S3 권한 제한됨"
    echo ""
    
    # 생성 계획 표시 및 사용자 확인
    show_creation_plan
    confirm_creation
    
    # 리소스 생성 (단계별)
    show_progress 1 3 "S3 버킷 생성 중..."
    show_info "S3 버킷 생성 중..."
    bucket_name=$(create_s3_bucket)
    if [ -z "$bucket_name" ]; then
        show_error "S3 버킷 생성 실패"
        exit 1
    fi
    show_success "S3 버킷 생성 완료: $bucket_name"
    echo ""
    
    show_progress 2 3 "샘플 파일 업로드 중..."
    show_info "샘플 파일 생성 및 업로드 중..."
    if upload_sample_files "$bucket_name"; then
        show_success "샘플 파일 업로드 완료: index.html, error.html"
    else
        show_error "샘플 파일 업로드 실패"
        exit 1
    fi
    echo ""
    
    show_progress 3 3 "버킷 정책 설정 중..."
    show_info "버킷 정책 설정 중..."
    if configure_bucket_policy "$bucket_name"; then
        show_success "버킷 정책 설정 완료"
    else
        show_warning "버킷 정책 설정 실패 (수동으로 설정해주세요)"
    fi
    echo ""
    
    # 완료 요약
    show_completion_summary "$bucket_name"
}

# 스크립트 실행
main "$@"