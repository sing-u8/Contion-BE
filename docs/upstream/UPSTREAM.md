# Upstream 기획 SSoT 핀 (Pinned Upstream)

- 상태: Active
- 대상: `upstream/` git submodule
- 원본 저장소: Worship Conti Maker (`worship-conti-maker-node-version`)
- Canonical remote: `https://github.com/sing-u8/Conti-On.git`

---

## 1. 왜 서브모듈인가

제품 요구사항의 정본은 이 저장소가 아니라 원본 `docs/plan/`이다
(`../reimplementation-charter.md` §4). 그 원본을 참조하는 방법에는 세 가지 선택지가
있었고, 서브모듈을 선택했다.

| 방식 | 문제 |
| --- | --- |
| 상대경로(`../worship-conti-maker-node-version`) 직접 참조 | 읽는 내용이 "그 순간 원본이 어느 브랜치·어느 워킹트리 상태였나"에 좌우된다. **무성(silent) 드리프트.** 원본이 없는 머신·CI에서는 아예 읽을 수 없다 |
| 기획 문서 전체 복사 | charter §9 "원본 기획 문서를 이 저장소에 복제하여 두 번째 정본으로 만들지 않는다"를 스스로 위반한다 |
| **git submodule (채택)** | 부모 트리에 커밋 SHA가 박히므로 **핀이 곧 파일**이다. 워킹트리는 남의 저장소의 detached 체크아웃이라 손대면 즉시 티가 나고, 두 번째 정본이 **구조적으로** 생기지 않는다 |

이 결정이 필요했던 실제 근거는 서브모듈을 거는 **바로 그 작업 세션 안에서** 관측됐다.
charter의 손으로 적은 기준선 표는 DB설계를 `v1.1.1`로 적고 있었는데, 한 세션(반나절)
동안 원본은 이렇게 움직였다.

| 원본 커밋 | `4.DB설계_Phase3.md` |
| --- | --- |
| `5b75e423` docs(plan): DB설계 문서 수정 | v1.1.1 |
| `0276a464` reconcile DB design v1.1.2 with implementation migrations | v1.1.2 |
| `8faac025` reclassify Notification as Projection | v1.1.3 |
| `90f29eb9` (그 다음 날까지 11커밋 더) | **v1.1.5** |

상대경로로 떠 있었다면 같은 날 여러 개의 서로 다른 "정본"을 읽었을 것이고, 그중 어느
것을 읽었는지 사후에 알 방법이 없다. 특히 `8faac025`는 Notification을 **Projection으로
재분류**하는 전략 수준 변경이라 이 저장소의 BC 패키지 구성에 직접 영향을 준다.

## 2. 현재 핀

| 항목 | 값 |
| --- | --- |
| 고정 커밋 | `90f29eb9bbed4d2b3ebc0f9015ff35f52b6a5858` |
| 커밋 제목 | `docs(plan): record the accidental protection behind BR-SM-012's file cap` |
| 원본 브랜치 | `main` |

### 2.1 핀 이동 기록

| 일자 | 이동 | 이유 / Spring 영향 |
| --- | --- | --- |
| 2026-07-27 | 최초 핀 `8faac025` | 하네스 도입. 원본이 아직 미푸시라 `.gitmodules` URL을 로컬 절대경로로 시작 |
| 2026-07-27 | `8faac025` → `90f29eb9` (11커밋) | 요구사항 v8.114→**v8.115**, 전술 v1.1.0→**v1.1.9**, DB v1.1.3→**v1.1.5**. Java→TypeScript 전환 완료로 **legacy Java 참조 코드가 삭제**됨 + VO 승격 범위·예외 이름 계약·BR-SM-012 동시성 취약점이 새로 문서화. 반영 결과는 [`../design/spring-translation-map.md`](../design/spring-translation-map.md) §2.1·§4.1·§6.2~§6.5 |
| 2026-07-27 | `90f29eb9` → `1c662cef` (5커밋 중 영향 1) | `1c0671ae`가 BR-SM-012 채번을 "load-bearing"으로 표시하고 해당 절을 §9.5.4→**§9.5.5**로 이동. translation map §6.5 인용 교정 + 원본 코드 주석("채번을 바꾸면 행을 잠글 것")을 Spring 의도적 차이의 근거로 인용 |
| 2026-07-27 | (핀 이동 아님) `.gitmodules` URL을 **canonical remote로 전환** | 원본 `main`이 GitHub에 푸시되어 로컬 절대경로 의존이 해소됐다. `file://` 전송 우회(`protocol.file.allow`)도 함께 제거 |

이 커밋 시점의 문서 버전은 `docs/upstream/UPSTREAM.lock`에 **기계 생성**으로 기록되며
`scripts/check-upstream.sh`가 sha256까지 대조한다. 버전 헤더는 사람이 손으로 적는
값이라 조용히 거짓말할 수 있으므로, **해시가 정본이고 버전은 부가 정보**다.

이 문서에 버전 표를 손으로 복제하지 않는다 — 그것이 애초에 드리프트한 방식이다.
현재 값은 `./scripts/check-upstream.sh` 출력에서 읽는다.

## 3. 최초 셋업 / 다른 머신에서 클론할 때

```bash
./scripts/setup-dev.sh
```

훅 경로를 배선하고, 서브모듈을 초기화하고, 핀을 검증한다. 서브모듈만 필요하면:

```bash
git submodule update --init --recursive
```

## 4. 핀을 올리는 절차 (upstream 동기화 슬라이스)

원본 기획이 갱신됐을 때, 조용히 따라가지 않는다. **명시적인 커밋 1개**로 올린다.

`scripts/upstream-sync.sh`가 기계적인 부분을 대신한다. 사람이 하는 일은 **diff를 읽는
것**과 **커밋**뿐이다.

```bash
# 1) 무엇이 바뀌었는지 확인 (읽기 전용)
./scripts/upstream-sync.sh
#    → 영향 커밋 목록 + 변경 규모 + 전체 diff 파일 경로를 출력한다.
#    → 변경이 없거나 Spring 영향 경로(docs/plan · tools/openapi) 밖이면
#      "할 일 없음"으로 즉시 끝난다.

# 2) 그 diff 를 읽는다        ← 이 절차의 핵심. 사람이 하는 유일한 판단
#    무엇을 볼지는 스크립트가 출력하는 체크리스트 참조

# 3) 핀 이동 + lock 재생성 + 검증
./scripts/upstream-sync.sh --pin <새SHA>

# 4) 판단 결과를 문서에 반영하고 커밋
git checkout -b chore/upstream-sync-<요약>
git add upstream docs/upstream/UPSTREAM.lock   # 문서를 고쳤다면 함께
git commit
```

**2번이 이 절차의 목적이다.** diff를 읽지 않고 핀만 올리는 것은 상대경로 참조와 다를
바 없다 — 무엇이 바뀌었는지 모른 채 따라가게 된다. 그래서 스크립트는 `--pin`에 SHA를
명시적으로 요구하고, 자동으로 최신까지 끌어올리지 않는다.

커밋 메시지에는 **diff에서 읽은 내용**을 남긴다. 그것이 나중에 "이 핀은 왜 여기
있나"의 답이 된다.

### 실제 사례 (2026-07-27)

```text
1단계 → 새 커밋 5개 중 Spring 영향 커밋 1개: 1c0671ae
2단계 → 읽어보니 (a) 해당 절이 §9.5.4 → §9.5.5 로 이동
                 (b) "채번을 바꾸면 행을 잠글 것"이라는 지침이 코드 주석으로 추가됨
판단  → (a) spring-translation-map.md §6.5 의 인용이 stale → 교정
        (b) Spring 의 의도적 차이가 원본 지침과 일치함을 확인 → 근거로 인용
3~4  → 핀 이동과 문서 교정을 한 커밋으로
```

1단계만 돌리고 2단계를 건너뛰었다면 핀 숫자만 올라가고 인용은 stale인 채로 남았다.

## 5. 이 서브모듈을 다루는 규칙

- `upstream/` 안의 파일을 **절대 편집하지 않는다.** 읽기 전용이다.
- 원본 기획에 문제를 발견하면 원본 저장소에서 고치고, 여기서는 핀만 올린다
  (charter §9).
- BR 번호·이벤트 이름·식별자·영속성 규칙은 **핀된 원문에서 읽어 인용**한다. 기억에
  의존하지 않는다.
- 원본 워킹트리의 **미커밋 변경은 핀에 보이지 않는다.** 이는 결함이 아니라 의도다 —
  커밋되지 않은 기획은 아직 정본이 아니다.
