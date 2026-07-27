#!/usr/bin/env bash
# =============================================================================
# setup-dev.sh — 새 클론/새 머신 1회 셋업
# =============================================================================
#   (1) git hooks 경로를 .githooks 로 지정 (보호 브랜치·게이트 마커 강제)
#   (2) 로컬 경로 서브모듈을 위한 file 프로토콜 허용 (UPSTREAM.md §4)
#   (3) upstream 기획 SSoT 서브모듈 초기화
#   (4) 핀 검증
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[1/4] git hooks 경로 설정"
chmod +x .githooks/* 2>/dev/null || true
git config core.hooksPath .githooks
echo "  ✓ core.hooksPath=.githooks"

echo "[2/4] 서브모듈 file 프로토콜 허용 (로컬 경로 upstream 용)"
git config protocol.file.allow always
echo "  ✓ protocol.file.allow=always (이 저장소 로컬 설정)"

echo "[3/4] upstream 기획 SSoT 서브모듈 초기화"
git -c protocol.file.allow=always submodule update --init --recursive
echo "  ✓ upstream/ 준비됨"

echo "[4/4] 핀 검증"
./scripts/check-upstream.sh

echo
echo "셋업 완료. 다음:"
echo "  ./gradlew test              # 테스트"
echo "  cat CLAUDE.md               # 이 저장소의 행동 규칙 (Tier 0 포인터)"
