#!/usr/bin/env bash
# =============================================================================
# setup-dev.sh — 새 클론/새 머신 1회 셋업
# =============================================================================
#   (1) git hooks 경로를 .githooks 로 지정 (보호 브랜치·게이트 마커 강제)
#   (2) upstream 기획 SSoT 서브모듈 초기화 (UPSTREAM.md §3)
#   (3) 핀 검증
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[1/3] git hooks 경로 설정"
chmod +x .githooks/* 2>/dev/null || true
git config core.hooksPath .githooks
echo "  ✓ core.hooksPath=.githooks"

# upstream 이 로컬 경로였던 시절 심어둔 설정을 정리한다. canonical HTTPS URL 로
# 전환된 뒤로는 불필요하며, 이유 없이 남은 CVE-2022-39253 완화 해제는 그 자체로
# 위험이다. 없으면 조용히 넘어간다.
git config --unset protocol.file.allow 2>/dev/null || true

echo "[2/3] upstream 기획 SSoT 서브모듈 초기화"
git submodule update --init --recursive
echo "  ✓ upstream/ 준비됨"

echo "[3/3] 핀 검증"
./scripts/check-upstream.sh

echo
echo "셋업 완료. 다음:"
echo "  cat CLAUDE.md               # 이 저장소의 행동 규칙 (Tier 0 포인터)"
echo "  cat docs/backlog.md         # 열린 결정과 미배선 항목"
echo "  ./gradlew test              # 테스트"
