#!/usr/bin/env bash
# =============================================================================
# check-upstream.sh — 원본 기획 SSoT 핀 검증
# =============================================================================
#
# 검증하는 것:
#   (1) upstream/ 서브모듈이 초기화돼 있는가
#   (2) 실제 체크아웃된 SHA == 부모 트리에 기록된 gitlink SHA (핀 이탈 탐지)
#   (3) upstream/ 워킹트리가 깨끗한가 (읽기 전용 규약 위반 탐지)
#   (4) 추적 대상 문서의 sha256 + 버전 헤더 == UPSTREAM.lock 기록
#
# 왜 버전 헤더가 아니라 sha256이 정본인가:
#   문서 상단의 "vX.Y" 헤더는 사람이 손으로 적는다 — 갱신을 잊으면 조용히 거짓말을
#   한다(실제로 charter가 DB설계를 v1.1.1로 적고 있는 동안 원본은 v1.1.2였다).
#   해시는 거짓말을 못 한다. 버전은 사람이 읽기 위한 부가 정보로만 기록한다.
#
# 사용:
#   ./scripts/check-upstream.sh            검증 (CI/pre-commit 용, 실패 시 exit 1)
#   ./scripts/check-upstream.sh --update   현재 핀 기준으로 UPSTREAM.lock 재생성
#
# 자세한 배경과 핀 이동 절차: docs/upstream/UPSTREAM.md
# =============================================================================

set -euo pipefail

# git 훅에서 호출되면 git 이 자기 저장소로 스코프를 고정하는 환경변수를 주입한다.
# 그중 GIT_INDEX_FILE 은 보통 상대경로(`.git/index`)라, `git -C upstream ...` 로
# 디렉터리를 옮기는 순간 `upstream/.git/index` 로 해석된다 — 그런데 `upstream/.git`
# 은 gitfile(디렉터리 아님)이라 "index file open failed: Not a directory" 로 죽는다.
# 이 스크립트는 REPO_ROOT 를 스스로 계산하므로 상속받은 값이 필요 없다. 지운다.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX \
      GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LOCK_FILE="docs/upstream/UPSTREAM.lock"
SUBMODULE="upstream"

# 추적 대상 — 이 목록이 "Spring 재구현이 의존하는 원본 문서"의 정의다.
TRACKED_FILES=(
  "docs/plan/1.찬양_콘티_메이커_요구사항명세서.md"
  "docs/plan/2.전략설계_DDD_Phase1.md"
  "docs/plan/3.전술설계_DDD_Phase2.md"
  "docs/plan/4.DB설계_Phase3.md"
  "docs/plan/CONTEXT.md"
  "docs/plan/BR_confusion_catalog.md"
  "docs/plan/planning-sync-audit.md"
  "tools/openapi/openapi.json"
)

# ---------- 유틸 --------------------------------------------------------------

if command -v sha256sum >/dev/null 2>&1; then
  hash_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
  echo "ERROR: sha256sum / shasum 둘 다 없습니다." >&2
  exit 2
fi

# 문서 상단의 첫 vX.Y(.Z) 토큰. 없으면 "-".
version_of() {
  grep -m1 -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$1" 2>/dev/null || echo "-"
}

fail() { echo "  ✗ $*" >&2; FAILED=1; }
ok()   { echo "  ✓ $*"; }

FAILED=0
MODE="${1:-check}"

# ---------- (1) 서브모듈 초기화 확인 ------------------------------------------

echo "[1/4] 서브모듈 초기화"
if [ ! -e "$SUBMODULE/.git" ]; then
  echo "  ✗ '$SUBMODULE/' 이 초기화되지 않았습니다." >&2
  echo "" >&2
  echo "    git -c protocol.file.allow=always submodule update --init --recursive" >&2
  echo "" >&2
  echo "    (또는 ./scripts/setup-dev.sh — 배경: docs/upstream/UPSTREAM.md §4)" >&2
  exit 1
fi
ok "초기화됨"

# ---------- (2) 핀 이탈 탐지 ---------------------------------------------------

echo "[2/4] 핀 일치 (gitlink vs 실제 체크아웃)"
ACTUAL_SHA="$(git -C "$SUBMODULE" rev-parse HEAD)"
RECORDED_SHA="$(git ls-tree HEAD -- "$SUBMODULE" | awk '{print $3}')"

if [ -z "$RECORDED_SHA" ]; then
  echo "  · 부모 커밋에 gitlink 없음 (최초 도입 중) — 실제 SHA를 기준으로 진행"
  RECORDED_SHA="$ACTUAL_SHA"
fi

if [ "$ACTUAL_SHA" != "$RECORDED_SHA" ]; then
  fail "핀 이탈: 기록=$RECORDED_SHA / 실제=$ACTUAL_SHA"
  echo "    의도한 이동이라면 'git add $SUBMODULE' 로 기록하고 UPSTREAM.md §5를 따르세요." >&2
else
  ok "$ACTUAL_SHA"
fi

# ---------- (3) 읽기 전용 규약 -------------------------------------------------

echo "[3/4] upstream 워킹트리 청결도 (읽기 전용 규약)"
# 실패를 조용히 넘기지 않는다 — git 호출 자체가 실패하면 "깨끗함"으로 오판하거나
# set -e 로 아무 메시지 없이 죽는다. 게이트로서 둘 다 최악이다.
if DIRTY="$(git -C "$SUBMODULE" status --porcelain 2>&1)"; then
  if [ -n "$DIRTY" ]; then
    fail "upstream/ 에 로컬 수정이 있습니다 — 원본은 읽기 전용입니다 (UPSTREAM.md §6)"
    printf '%s\n' "$DIRTY" | head -20 | sed 's/^/      /' >&2
  else
    ok "깨끗함"
  fi
else
  fail "upstream/ 상태를 읽을 수 없습니다 (git 호출 실패)"
  printf '%s\n' "$DIRTY" | head -5 | sed 's/^/      /' >&2
fi

# ---------- (4) 문서 해시 / 버전 -----------------------------------------------

if [ "$MODE" = "--update" ]; then
  echo "[4/4] UPSTREAM.lock 재생성"
  mkdir -p "$(dirname "$LOCK_FILE")"
  {
    echo "# UPSTREAM.lock — 기계 생성. 손으로 편집하지 마세요."
    echo "# 재생성: ./scripts/check-upstream.sh --update"
    echo "# 배경:   docs/upstream/UPSTREAM.md"
    printf 'pin\t%s\n' "$ACTUAL_SHA"
    for f in "${TRACKED_FILES[@]}"; do
      p="$SUBMODULE/$f"
      [ -f "$p" ] || { echo "ERROR: 추적 대상이 핀에 없습니다: $f" >&2; exit 2; }
      printf 'file\t%s\t%s\t%s\n' "$(version_of "$p")" "$(hash_of "$p")" "$f"
    done
  } > "$LOCK_FILE"
  ok "생성됨: $LOCK_FILE ($(( ${#TRACKED_FILES[@]} )) files @ $ACTUAL_SHA)"
  echo
  echo "요약:"
  grep '^file' "$LOCK_FILE" | awk -F'\t' '{printf "  %-10s %s\n", $2, $4}'
  exit 0
fi

echo "[4/4] 문서 해시 / 버전 대조"
if [ ! -f "$LOCK_FILE" ]; then
  fail "$LOCK_FILE 이 없습니다 — './scripts/check-upstream.sh --update' 로 생성하세요."
else
  LOCKED_PIN="$(awk -F'\t' '$1=="pin"{print $2}' "$LOCK_FILE")"
  if [ "$LOCKED_PIN" != "$ACTUAL_SHA" ]; then
    fail "lock 파일의 핀($LOCKED_PIN)이 현재 핀($ACTUAL_SHA)과 다릅니다 — --update 필요"
  fi

  while IFS=$'\t' read -r kind lver lhash lpath; do
    [ "$kind" = "file" ] || continue
    p="$SUBMODULE/$lpath"
    if [ ! -f "$p" ]; then
      fail "핀에서 사라진 문서: $lpath"
      continue
    fi
    ahash="$(hash_of "$p")"
    if [ "$ahash" != "$lhash" ]; then
      fail "$lpath 내용 변경 (lock=${lhash:0:12}… actual=${ahash:0:12}…)"
    else
      aver="$(version_of "$p")"
      if [ "$aver" != "$lver" ]; then
        fail "$lpath 버전 헤더 불일치 (lock=$lver actual=$aver)"
      else
        ok "$(printf '%-10s %s' "$lver" "$lpath")"
      fi
    fi
  done < "$LOCK_FILE"
fi

echo
if [ "$FAILED" = "1" ]; then
  echo "UPSTREAM 검증 실패. 절차는 docs/upstream/UPSTREAM.md §5." >&2
  exit 1
fi
echo "UPSTREAM 검증 통과 @ $ACTUAL_SHA"
