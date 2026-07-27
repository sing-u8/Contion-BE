#!/usr/bin/env bash
# =============================================================================
# upstream-sync.sh — 원본 기획 SSoT 동기화 (docs/upstream/UPSTREAM.md §4)
# =============================================================================
#
# 이 스크립트가 하는 일과 하지 않는 일이 명확히 갈린다.
#
#   한다   : 기계적인 것 — fetch, "Spring 에 영향 있는 커밋" 추리기, diff 뽑기,
#            핀 이동, lock 재생성, 검증.
#   안 한다: 판단 — diff 를 읽고 Spring 쪽 영향을 정하는 일, 그리고 커밋.
#
# 핀을 자동으로 최신까지 끌어올리지 않는 것이 의도다. 이 절차의 핵심은 핀 숫자를
# 바꾸는 게 아니라 **diff 를 읽는 것**이다. 자동으로 올려 버리면 상대경로 참조와
# 다를 바 없어진다 — 무엇이 바뀌었는지 모른 채 따라가게 된다.
#
# 사용:
#   ./scripts/upstream-sync.sh              무엇이 바뀌었는지 확인만 (읽기 전용)
#   ./scripts/upstream-sync.sh --pin <SHA>  판단을 마친 뒤 그 SHA 로 핀 이동
#
# 전형적인 흐름:
#   1) ./scripts/upstream-sync.sh          -> 영향 커밋 목록 + diff 파일 경로
#   2) 그 diff 를 읽는다                    <- 사람이 하는 유일한 일
#   3) ./scripts/upstream-sync.sh --pin <SHA>
#   4) 판단 결과를 문서에 반영하고 커밋
# =============================================================================

set -euo pipefail

# check-upstream.sh 와 같은 이유로 지운다 — git 훅에서 호출되면 상속된 GIT_* 가
# 서브모듈 대상 호출을 부모 저장소로 오염시킨다. 자세한 배경은 check-upstream.sh 상단.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX \
      GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SUBMODULE="upstream"

# "Spring 에 영향 있다"의 정의. 원본의 web/인프라 변경은 여기 없으므로 무시된다.
WATCHED_PATHS=("docs/plan" "tools/openapi")

# ---------- 인자 ---------------------------------------------------------------

MODE="check"
NEW_PIN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pin)
      MODE="pin"
      NEW_PIN="${2:-}"
      if [ -z "$NEW_PIN" ]; then
        echo "ERROR: --pin 에 SHA 가 필요합니다." >&2
        echo "  먼저 './scripts/upstream-sync.sh' 로 후보를 확인하세요." >&2
        exit 2
      fi
      shift 2
      ;;
    -h | --help)
      sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "ERROR: 알 수 없는 인자: $1 (--help 참고)" >&2
      exit 2
      ;;
  esac
done

# ---------- 전제 조건 -----------------------------------------------------------

if [ ! -e "$SUBMODULE/.git" ]; then
  echo "ERROR: '$SUBMODULE/' 이 초기화되지 않았습니다." >&2
  echo "  ./scripts/setup-dev.sh" >&2
  exit 1
fi

UPSTREAM_DIRTY="$(git -C "$SUBMODULE" status --porcelain 2>&1 || true)"
if [ -n "$UPSTREAM_DIRTY" ]; then
  echo "ERROR: upstream/ 에 로컬 수정이 있습니다 — 원본은 읽기 전용입니다." >&2
  printf '%s\n' "$UPSTREAM_DIRTY" | head -10 | sed 's/^/    /' >&2
  echo "  되돌리기: git -C $SUBMODULE checkout -- ." >&2
  exit 1
fi

CURRENT_PIN="$(git -C "$SUBMODULE" rev-parse HEAD)"
TRACKED_BRANCH="$(git config -f .gitmodules submodule.upstream.branch 2>/dev/null || echo main)"

# ---------- --pin: 핀 이동 -------------------------------------------------------

if [ "$MODE" = "pin" ]; then
  if ! git -C "$SUBMODULE" cat-file -e "${NEW_PIN}^{commit}" 2>/dev/null; then
    echo "ERROR: '$NEW_PIN' 을(를) upstream 에서 찾을 수 없습니다." >&2
    echo "  먼저 fetch 가 필요할 수 있습니다: ./scripts/upstream-sync.sh" >&2
    exit 1
  fi

  RESOLVED="$(git -C "$SUBMODULE" rev-parse "${NEW_PIN}^{commit}")"

  if [ "$RESOLVED" = "$CURRENT_PIN" ]; then
    echo "핀이 이미 $RESOLVED 입니다. 할 일 없음."
    exit 0
  fi

  echo "핀 이동: ${CURRENT_PIN:0:12}… → ${RESOLVED:0:12}…"
  git -C "$SUBMODULE" checkout --detach "$RESOLVED" >/dev/null 2>&1

  # check-upstream.sh 는 인덱스와 비교하므로, 여기서 gitlink 를 기록해야 통과한다.
  # 커밋은 하지 않는다 — 의도를 남기는 일은 사람의 몫이다.
  git add "$SUBMODULE"

  echo
  ./scripts/check-upstream.sh --update
  echo
  ./scripts/check-upstream.sh

  cat <<NEXT

────────────────────────────────────────────────────────────────
핀과 lock 이 스테이지됐습니다. 아직 커밋되지 않았습니다.

반영 여부를 확인할 것:
  [ ] docs/design/spring-translation-map.md — 인용한 절 번호·버전이 그대로인가
      (원본이 절을 옮기거나 이름을 바꾸면 인용이 조용히 stale 이 된다)
  [ ] BR·이벤트·Port·UseCase 이름이 갈라지지 않았는가
  [ ] 스키마 변경이 있으면 Flyway 마이그레이션이 필요한가
  [ ] openapi.json 이 바뀌었으면 계약 diff 기준선이 바뀐 것

커밋:
  git checkout -b chore/upstream-sync-<요약>
  git add upstream docs/upstream/UPSTREAM.lock   # 문서를 고쳤다면 함께
  git commit

커밋 메시지에는 **diff 에서 읽은 내용**을 남기세요. 그게 나중에
"이 핀은 왜 여기 있나"의 답이 됩니다.
────────────────────────────────────────────────────────────────
NEXT
  exit 0
fi

# ---------- check: 무엇이 바뀌었는지 확인 -------------------------------------------

echo "현재 핀 : $CURRENT_PIN"
echo "추적 브랜치: origin/$TRACKED_BRANCH"
echo

echo "fetch 중…"
if ! git -C "$SUBMODULE" fetch origin --quiet 2>/dev/null; then
  echo "ERROR: upstream fetch 실패." >&2
  echo "  .gitmodules 의 url 을 확인하세요 (docs/upstream/UPSTREAM.md §3)." >&2
  exit 1
fi

if ! TARGET="$(git -C "$SUBMODULE" rev-parse "origin/$TRACKED_BRANCH" 2>/dev/null)"; then
  echo "ERROR: origin/$TRACKED_BRANCH 를 찾을 수 없습니다." >&2
  exit 1
fi

if [ "$TARGET" = "$CURRENT_PIN" ]; then
  echo "핀이 origin/$TRACKED_BRANCH 최신과 같습니다. 할 일 없음."
  exit 0
fi

if ! git -C "$SUBMODULE" merge-base --is-ancestor "$CURRENT_PIN" "$TARGET" 2>/dev/null; then
  echo "주의: 현재 핀이 origin/$TRACKED_BRANCH 의 조상이 아닙니다." >&2
  echo "  브랜치가 다시 쓰였거나 다른 갈래를 보고 있을 수 있습니다. 아래 목록을" >&2
  echo "  그대로 신뢰하지 말고 직접 확인하세요." >&2
  echo >&2
fi

TOTAL="$(git -C "$SUBMODULE" rev-list --count "$CURRENT_PIN..$TARGET")"
COMMITS="$(git -C "$SUBMODULE" log --oneline "$CURRENT_PIN..$TARGET" -- "${WATCHED_PATHS[@]}")"

if [ -z "$COMMITS" ]; then
  echo "새 커밋 ${TOTAL}개가 있으나 Spring 영향 경로(${WATCHED_PATHS[*]}) 변경은 없습니다."
  echo "할 일 없음 — 핀을 올릴 이유가 없습니다."
  echo
  echo "(그래도 올리고 싶다면: ./scripts/upstream-sync.sh --pin $TARGET)"
  exit 0
fi

AFFECTED="$(printf '%s\n' "$COMMITS" | wc -l | tr -d ' ')"

echo "새 커밋 ${TOTAL}개 중 Spring 영향 커밋 ${AFFECTED}개:"
echo
printf '%s\n' "$COMMITS" | sed 's/^/  /'
echo
echo "변경 규모:"
# core.quotepath=false 가 없으면 한글 파일명이 \354\240\204… 로 이스케이프돼 읽을 수 없다.
git -C "$SUBMODULE" -c core.quotepath=false \
    diff --stat "$CURRENT_PIN..$TARGET" -- "${WATCHED_PATHS[@]}" | sed 's/^/  /'

TMP_BASE="${TMPDIR:-/tmp}"
TMP_BASE="${TMP_BASE%/}"   # TMPDIR 은 보통 끝에 / 가 붙어 있어 경로가 //T// 처럼 된다
DIFF_FILE="$TMP_BASE/upstream-sync-${CURRENT_PIN:0:8}-${TARGET:0:8}.diff"
git -C "$SUBMODULE" -c core.quotepath=false \
    diff "$CURRENT_PIN..$TARGET" -- "${WATCHED_PATHS[@]}" > "$DIFF_FILE"

cat <<NEXT

────────────────────────────────────────────────────────────────
전체 diff 를 저장했습니다:

  $DIFF_FILE

**이걸 읽는 것이 이 절차의 전부입니다.** 나머지는 기계적인 뒷정리입니다.

읽으면서 판단할 것:
  · BR 문구·수용 기준        → 구현/테스트에 영향 있나
  · Aggregate 경계·Port·UseCase 이름 → 코드 이름이 갈라졌나
  · 테이블·컬럼·인덱스·제약   → Flyway 마이그레이션이 필요한가
  · openapi.json             → 계약 diff 기준선이 바뀐 것
  · 절 번호 이동             → translation map 인용 교정 필요

읽고 나서:
  ./scripts/upstream-sync.sh --pin $TARGET
────────────────────────────────────────────────────────────────
NEXT
