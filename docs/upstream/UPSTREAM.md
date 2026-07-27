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
| 2026-07-27 | 최초 핀 `8faac025` | 하네스 도입 |
| 2026-07-27 | `8faac025` → `90f29eb9` (11커밋) | 요구사항 v8.114→**v8.115**, 전술 v1.1.0→**v1.1.9**, DB v1.1.3→**v1.1.5**. Java→TypeScript 전환 완료로 **legacy Java 참조 코드가 삭제**됨 + VO 승격 범위·예외 이름 계약·BR-SM-012 동시성 취약점이 새로 문서화. 반영 결과는 [`../design/spring-translation-map.md`](../design/spring-translation-map.md) §2.1·§4.1·§6.2~§6.5 |

이 커밋 시점의 문서 버전은 `docs/upstream/UPSTREAM.lock`에 **기계 생성**으로 기록되며
`scripts/check-upstream.sh`가 sha256까지 대조한다. 버전 헤더는 사람이 손으로 적는
값이라 조용히 거짓말할 수 있으므로, **해시가 정본이고 버전은 부가 정보**다.

이 문서에 버전 표를 손으로 복제하지 않는다 — 그것이 애초에 드리프트한 방식이다.
현재 값은 `./scripts/check-upstream.sh` 출력에서 읽는다.

## 3. 알려진 임시 상태 — 로컬 경로 URL

`.gitmodules`의 URL은 현재 **로컬 절대경로**다. canonical remote가 아니다.

이유: 고정 커밋(`90f29eb9` 및 그 조상들)은 **아직 GitHub에 푸시되지 않았다.**
GitHub의 `origin/main`은 v8.114 정합 이전이라 핀한 SHA를 fetch할 수 없다.

원본의 해당 브랜치를 푸시한 뒤에는 아래 한 번으로 canonical URL로 전환한다.

```bash
git config -f .gitmodules submodule.upstream.url https://github.com/sing-u8/Conti-On.git
git submodule sync upstream
git add .gitmodules && git commit -m "chore(upstream): switch submodule URL to canonical remote"
```

전환 전까지 이 저장소는 **이 머신에서만** 서브모듈을 초기화할 수 있다. Spring
저장소 자체도 아직 remote가 없으므로 현재 잃는 것은 없다.

## 4. 최초 셋업 / 다른 머신에서 클론할 때

로컬 경로 서브모듈은 git ≥ 2.38의 `file://` 전송 차단(CVE-2022-39253 완화)에
걸린다. 원본이 본인 소유 로컬 저장소이므로 이 저장소에 한해 허용한다.

```bash
git -c protocol.file.allow=always submodule update --init --recursive
```

`scripts/setup-dev.sh`가 이 설정을 로컬 git config에 한 번 심어준다.

## 5. 핀을 올리는 절차 (upstream 동기화 슬라이스)

원본 기획이 갱신됐을 때, 조용히 따라가지 않는다. **명시적인 커밋 1개**로 올린다.

```bash
# 1) 새 커밋 확인
git -C upstream fetch origin
git -C upstream log --oneline <현재핀>..origin/main -- docs/plan/ tools/openapi/

# 2) 무엇이 바뀌었는지 반드시 읽는다 (BR·이벤트·계약 영향 판단)
git -C upstream diff <현재핀>..<새SHA> -- docs/plan/ tools/openapi/openapi.json

# 3) 핀 이동
git -C upstream checkout --detach <새SHA>

# 4) 검증 후 부모에 기록
./scripts/check-upstream.sh
git add upstream docs/upstream/UPSTREAM.md
git commit -m "chore(upstream): bump plan SSoT pin to <새SHA> (요구사항 vX.Y)"
```

3번과 4번 사이에서 **Spring 쪽 영향 범위를 판단**하는 것이 이 절차의 목적이다.
diff를 읽지 않고 핀만 올리는 것은 상대경로 참조와 다를 바 없다.

## 6. 이 서브모듈을 다루는 규칙

- `upstream/` 안의 파일을 **절대 편집하지 않는다.** 읽기 전용이다.
- 원본 기획에 문제를 발견하면 원본 저장소에서 고치고, 여기서는 핀만 올린다
  (charter §9).
- BR 번호·이벤트 이름·식별자·영속성 규칙은 **핀된 원문에서 읽어 인용**한다. 기억에
  의존하지 않는다.
- 원본 워킹트리의 **미커밋 변경은 핀에 보이지 않는다.** 이는 결함이 아니라 의도다 —
  커밋되지 않은 기획은 아직 정본이 아니다.
