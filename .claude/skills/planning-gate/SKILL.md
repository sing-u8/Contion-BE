---
name: planning-gate
description: >-
  Contion-Spring-BE의 슬라이스 착수 게이트. 기능 슬라이스, 백엔드 구현, 동작을 바꾸는
  리팩터, 설계/스펙 문서를 시작하기 직전에 사용한다. 핀된 upstream 기획 SSoT에서 관련
  Feature/BR/이벤트/수용 기준을 재독하고, BR 혼동 경계(CP-*)를 대조하고, BR 인용을
  원문과 대조 검증하고, "Docs consulted / Planning gate" 노트를 만든다. Tier-0
  헌법(docs/methodology/CONSTITUTION.md)과 CLAUDE.md에 종속되며 충돌 시 그쪽이 이긴다.
---

# Planning Gate — Contion-Spring-BE 착수 게이트 (Tier 1)

이 스킬은 Build 8단계(`게이트 → 스펙 → 계획 → 격리 → TDD → 리뷰 → 검증 → 통합`)의
**1단계(게이트)**를 이 프로젝트의 실제 문서 배치에 맞춰 걷게 한다. 범용 절차는
`spec-gated-development` 스킬에, 규범적 정의는
[`docs/methodology/CONSTITUTION.md`](../../../docs/methodology/CONSTITUTION.md)에 있다.

**이 프로젝트의 결정적 차이**: 요구사항 정본이 이 저장소에 없다. `upstream/`
서브모듈에 **커밋 SHA로 고정된** 원본에 있다. 따라서 재독은 항상 "핀이 유효한가"를
먼저 확인하는 것에서 시작한다.

## 언제 쓰나

- 새 기능 슬라이스 / 백엔드 구현 / 동작을 바꾸는 리팩터를 시작하기 직전
- 설계·스펙·계획 문서를 쓰기 직전
- BR 번호를 인용하려는 모든 순간

## 절차

### 0. 핀 유효성 (이 프로젝트 고유 — 건너뛰지 않는다)

```bash
./scripts/check-upstream.sh
```

- 통과하지 못하면 **멈춘다.** 요구사항을 추측하지 않는다(CLAUDE.md §2).
- 출력의 SHA를 기록한다. 아래 노트의 `Upstream pin` 칸에 그대로 들어간다.
- 서브모듈이 없다면 `./scripts/setup-dev.sh`.

### 1. Feature / BR / 이벤트 / 수용 기준 재독

`upstream-requirements-query` 서브에이전트로 **필요 발췌만** 가져온다 — 요구사항
문서를 메인 컨텍스트에 통째로 올리지 않는다(C4).

가져올 것:
- 이 슬라이스가 걸리는 **Feature 번호와 제목**
- 관련 **BR-\*** 원문 (짧은 verbatim 발췌)
- 관련 **EVT-\*** (이벤트를 발행/소비하면)
- **Gherkin 수용 기준** — 성공·실패·경계 조건 전부

### 2. BR 혼동 경계 대조

인용하거나 인접한 모든 BR에 대해
`upstream/docs/plan/BR_confusion_catalog.md`의 **CP-\*** 항목을 확인한다.
혼동 쌍 항목은 **협상 불가능한 범위 경계**다. 해당 없으면 "없음"이라고 적는다.

### 3. 상위 설계 문서 재독 (해당하는 경우)

슬라이스가 아래를 건드리면 그 층의 upstream 문서를 다시 읽는다.

| 건드리는 것 | 재독 대상 |
| --- | --- |
| BC 경계 · 컨텍스트 맵 · 유비쿼터스 언어 | `upstream/docs/plan/2.전략설계_DDD_Phase1.md`, `CONTEXT.md` |
| Aggregate/UseCase/Port 설계 · 불변식 · 이벤트 · 식별자 | `upstream/docs/plan/3.전술설계_DDD_Phase2.md` |
| 영속성 · 쿼리 · 인덱스 · 삭제 정책 | `upstream/docs/plan/4.DB설계_Phase3.md` |
| 외부 API 계약 | `upstream/tools/openapi/openapi.json` |

### 4. BR 인용 대조 검증

인용하려는 각 BR에 대해:

- [ ] 핀된 원문을 **실제로 열어** 번호와 내용이 일치하는지 확인했다.
- [ ] 짧은 verbatim 발췌를 출처(문서·버전·섹션)와 함께 준비했다.
- [ ] 기억이나 이전 세션 요약에서 가져온 번호가 **하나도 없다.**

### 5. 스택 번역 경계 확인 (이 프로젝트 고유)

upstream 전술/DB 문서에는 NestJS/Prisma 표현과 legacy Spring 표현이 섞여 있다.
[`docs/design/spring-translation-map.md`](../../../docs/design/spring-translation-map.md)에서
해당 항목의 번역 규칙을 확인한다.

- **보존해야 하는 것**: 도메인 규칙 · BR · 이벤트 · Aggregate 경계 · Port 이름 ·
  UseCase 책임 · 외부 API 계약
- **번역해도 되는 것**: 구현 프레임워크 · persistence adapter · 클래스/패키지 구조

번역 규칙이 없는 새 항목을 만나면 **그 문서에 행을 추가**하는 것도 이 슬라이스의
산출물이다.

### 6. "Docs consulted / Planning gate" 노트 작성

스펙 또는 구현 계획에 아래를 **빈 칸 없이** 넣는다. `.githooks/pre-commit`이 이
마커를 찾는다.

```markdown
## Docs consulted / Planning gate
- Upstream pin: <SHA> (`./scripts/check-upstream.sh` 통과)
- Feature(s): <번호 · 제목>
- BRs: <BR-XXX — verbatim 발췌 + 출처>
- Events: <EVT-XXX 또는 "없음">
- BR confusion boundaries checked: <CP-XX … 또는 "없음">
- Upstream design docs read: 요구사항 vX.Y · 전략 vA.B · 전술 vC.D · DB vE.F
- Translation map entries applied: <항목 또는 "신규 추가: …">
- Conflicts found / resolution: <없음 또는 해소 방법>
```

## 충돌이 발견되면

구현 의도가 `upstream/docs/plan/`과 충돌하면 **코딩하지 않는다.**

1. 충돌을 명시적으로 적는다 (무엇 vs 무엇).
2. 원본 문서가 이긴다 (CLAUDE.md §2, charter §4).
3. 원본 기획 자체가 틀렸다고 판단되면 **원본 저장소의 SSoT 정합 문제**로 다룬다.
   이 저장소에서 조용히 다르게 구현하지 않는다 (charter §9).
4. Spring에만 해당하는 기술 결정이면 `docs/adr/`에 ADR로 남긴다.

## Done when

- [ ] `./scripts/check-upstream.sh`가 통과했고 SHA를 기록했다.
- [ ] 관련 Feature/BR/EVT/수용 기준을 **핀된 원문에서** 재독했다.
- [ ] 혼동 카탈로그(CP-\*)를 대조했다.
- [ ] 인용할 BR을 전부 원문과 대조했고 verbatim 발췌를 확보했다.
- [ ] 번역 경계를 확인했다.
- [ ] "Docs consulted / Planning gate" 노트에 빈 칸이 없다.
- [ ] 이제 스펙 작성(2단계)으로 넘어갈 준비가 됐다.

이 스킬의 어떤 문구든 `docs/methodology/CONSTITUTION.md` 또는 `CLAUDE.md`와 어긋나면
**그쪽이 이긴다.**
