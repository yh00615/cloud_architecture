#!/bin/bash
echo "============================================"
echo " CloudArchitect Lab01 - AWS 환경 정보 확인"
echo "============================================"
echo ""

# 기본 리전 설정
aws configure set default.region ap-northeast-2
aws configure set default.output json
echo "[1] 기본 리전: ap-northeast-2 (서울) 설정 완료"
echo ""

# 계정 정보 확인
echo "[2] 계정 정보:"
aws sts get-caller-identity
echo ""

# 현재 리전 확인
echo "[3] 현재 리전:"
aws configure get region
echo ""

# 사용 가능한 리전 목록
echo "[4] 사용 가능한 리전 목록:"
aws ec2 describe-regions --query 'Regions[].RegionName' --output table
echo ""

echo "============================================"
echo " 환경 정보 확인 완료"
echo "============================================"
