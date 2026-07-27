# CLAUDE.md

이 파일은 `Contion-Spring-BE`에서 **에이전트 행동의 정본 규칙**이다. 세션 시작 시
자동 로드된다. `AGENTS.md`·`GEMINI.md`는 이 파일을 가리키는 얇은 포인터이므로 규칙은
여기 한 곳에만 산다.

> 다른 에이전트(Codex, Cursor, Gemini …)도 이 파일을 읽는다.

---

## 0. Tier 0 — 헌법 (최상위·불변)

이 저장소 행동 규칙의 최상위 기준은 [`docs/methodology/CONSTITUTION.md`](docs/methodology/CONSTITUTION.md)다.
**세션 시작 시 읽고 그대로 따른다.** 아래 4개는 항상 컨텍스트에 두기 위한 하드코어
미러이며, 전체 본문(한 줄 원칙 · C1~C4 · 3 루프 · Build 8단계)은 원문에서 읽는다.

### 4개 비협상 항목

1. **게이트 순서** — 기획: 상위 재독 후 하위. 구현: 슬라이스마다 스펙 재독 후 진행.
2. **SSoT 우선** — 문서 > 코드.
3. **근거 인용** — 규칙은 원문 인용, 외워서 인용 금지.
4. **검증-전-완료** — 명령 실행·출력 확인 없이 "완료" 없음.

어떤 스킬 팩·슬래시 커맨드·서브에이전트도 **기법 제공자(Tier 2)**일 뿐이며 위 4개를
바꿀 수 없다. 팩 기본동작이 충돌하면(자동 커밋 · 게이트 스킵 · 리뷰 우회 등) **헌법이
이기고 그 동작은 무효**다. 기계적 훅(`.githooks/`)이 특히 1·4를 스킬과 무관하게
강제한다.

이 파일과 헌법 원문이 충돌하면 **원문이 이긴다**.

---

## 1. 이 프로젝트가 무엇인가

Worship Conti Maker의 기존 NestJS 백엔드를 **Java 21 + Spring Boot 4.1**로
재구축한다. 파일 단위 번역이 아니라, 검증된 제품 요구사항과 외부 계약을 보존하면서
내부 구현을 Spring/JPA 관용으로 다시 설계한다.

목적·범위·동등성 원칙·완료 정의: [`docs/reimplementation-charter.md`](docs/reimplementation-charter.md).

---

## 2. Source of Truth — 어디서 진실을 읽는가

제품 요구사항의 정본은 **이 저장소가 아니다.** `upstream/` 서브모듈에 **커밋 SHA로
고정된** 원본 기획 문서가 정본이다.

| 층위 | 내용 | 정본 위치 |
| --- | --- | --- |
| **제품이 무엇을 하나** | BR · Feature · EVT · Gherkin 수용 기준 · 혼동 경계(CP) | `upstream/docs/plan/1.*`, `upstream/docs/plan/BR_confusion_catalog.md` — **복제 금지** |
| **도메인 분해** | BC 경계 · 컨텍스트 맵 · Aggregate 경계 · 불변식 · 도메인 이벤트 · 식별자/삭제/권한 정책 | `upstream/docs/plan/2.*`, `3.*` — **참조만.** 여기가 갈라지면 재구현이 아니라 다른 제품이다 |
| **스택 결속 전술** | 패키지/클래스 구조 · JPA 매핑 · `@Transactional` 경계 · Security filter chain · Outbox relay · 직렬화 | **이 저장소가 정본** → [`docs/design/`](docs/design/) |
| **스키마** | 테이블·컬럼·인덱스·제약 | 논리 = `upstream/docs/plan/4.*` / **물리 실행 정본 = `src/main/resources/db/migration/V*.sql`** |
| **외부 API 계약** | path · method · status · DTO · 에러 봉투 | `upstream/tools/openapi/openapi.json` (기준선) |

### `upstream/skills/`는 이 저장소의 SSoT가 아니다

원본은 **구현 규약의 SSoT를 `docs/plan/` 바깥**에 둔다고 명시했다.

> **`upstream/docs/plan/planning-sync-audit.md` §1.2**: "프론트엔드·백엔드의 *구현*
> 규약(레이어 구성·상태 관리·컴포넌트 조합·테스트 방식 등)은 다음이 SSoT이며,
> **`docs/plan/`은 이를 중복 규정하지 않는다** … `docs/plan/`은 **무엇을·왜**(BR·도메인
> 모델·계약)를 정하고, 위 가이드라인은 **어떻게**를 정한다."

따라서 `upstream/skills/project-setting/references/nestjs-project-guideline.md`는
**NestJS 구현의 "어떻게"이지 이 저장소의 기준이 아니다.** Spring의 "어떻게"는 이
저장소가 소유한다 — `CLAUDE.md` · `docs/rules/` · `docs/design/`.

**예외 (보존 대상)**: 같은 §1.2가 "계약 표면 — OpenAPI·도메인 이벤트·에러 코드는 BC 간
합의라 전술설계가 다룬다"고 못 박는다. 이 셋은 원본 전술설계가 정본이다.

### 규칙

- `upstream/`은 **읽기 전용**이다. 절대 편집하지 않는다.
- 원본 기획 문서를 이 저장소로 **복사하지 않는다** (charter §9 — 두 번째 정본 금지).
  Spring 고유 결정만 `docs/design/`에 **차이(delta)로만** 적는다.
- 원본 기획에 문제를 발견하면 원본 저장소에서 고치고, 여기서는 핀만 올린다.
- 핀을 올리는 것은 **명시적 커밋 1개**다. 절차: [`docs/upstream/UPSTREAM.md`](docs/upstream/UPSTREAM.md) §4.
- 서브모듈이 없거나 핀이 어긋나면 **요구사항을 추측하지 말고 멈춘다.**
  `./scripts/check-upstream.sh`로 확인한다.

### BR 인용 규칙

BR 번호·이벤트 이름·식별자·영속성 규칙을 **기억에서 인용하지 않는다.** 핀된 원문을
다시 읽고, 짧은 verbatim 발췌를 출처와 함께 붙인다.

```text
> **BR-XXX** (`upstream/docs/plan/1.…md` v8.114 §X.X): "..."
```

인용한 BR이 `upstream/docs/plan/BR_confusion_catalog.md`에 있으면 **혼동 쌍(CP-*)을
먼저 확인**한다. 혼동 카탈로그 항목은 협상 불가능한 범위 경계다.

거대한 요구사항 문서를 메인 컨텍스트에 통째로 올리지 않는다(C4) —
`upstream-requirements-query` 서브에이전트로 필요 발췌만 가져온다.

---

## 3. 슬라이스 워크플로 (Build 8단계)

> **게이트 → 스펙 → 계획 → 격리 → TDD → 리뷰 → 검증 → 통합**

기능·리팩터·설계 문서 어느 것이든 슬라이스 시작 전에:

1. **게이트** — `planning-gate` 스킬을 돌린다. 관련 BR/Feature/수용 기준을 핀된
   원문에서 재독하고, 혼동 경계를 대조하고, **"참조 문서" 노트**를 남긴다.
2. 결과 스펙/계획에 아래 블록을 포함한다 (`.githooks/pre-commit`이 마커를 찾는다).

```markdown
## Docs consulted / Planning gate
- Upstream pin: <SHA> (./scripts/check-upstream.sh 통과)
- Feature(s): …
- BRs: BR-… (verbatim 발췌 포함)
- BR confusion boundaries checked: CP-… / 없음
- Upstream design docs read: 요구사항 vX · 전략 vY · 전술 vZ · DB vW
- Conflicts found / resolution: …
```

게이트에서 구현과 `upstream/docs/plan/`의 충돌을 발견하면 **코딩 전에 멈추고** 기획
불일치부터 해소한다.

---

## 4. 아키텍처 규칙

- **모듈러 모놀리스** — 단일 Gradle 모듈, BC를 패키지 경계로 명시.
  `org.worship.contionspringbe.{user,team,sheetmusic,setlist,notification,common}`
- **`notification`은 Projection이라 `domain` 패키지가 없다** — 원본 전략설계 v1.1.1이
  Aggregate → Projection Root로 재분류했다. 포트·어댑터·유스케이스로 구성한다
  (`docs/design/spring-translation-map.md` §6.4, ArchUnit이 강제).
- **헥사고날** — `adapter.in.web → application.port.in → application.service →
  application.port.out → adapter.out.persistence`. 의존성은 **adapter → application →
  domain** 한 방향.
- `domain`은 Spring·JPA에 불필요하게 결합하지 않는다.
- 외부 시스템과 영속성은 **Port 뒤**에 둔다.
- 트랜잭션 경계는 **application use case**에서 관리한다.
- Cross-BC 연동은 직접 Aggregate 참조가 아니라 **명시적 Port 또는 도메인 이벤트**로 한다.
- 구현 편의로 Aggregate 불변식·권한 경계를 약화하지 않는다.

**이 규칙들은 문서가 아니라 테스트로 강제된다** —
`src/test/java/**/architecture/ArchitectureRulesTest.java` (ArchUnit). 규칙을 바꾸려면
그 테스트를 먼저 바꾸고 근거를 남긴다.

### 동시성 — 낙관적 락 금지

원본 프로젝트는 미배선 `version` 컬럼을 **의도적으로 철회**했다. JPA `@Version`을
**근거 없이 도입하지 않는다.** 동시성은 원본 설계 의도를 보존한다:
**비관적 잠금 · 조건부 상태 전이 UPDATE · `FOR UPDATE SKIP LOCKED` · Unique 제약 ·
ShedLock.**

### 식별자

내부 PK = `Long`, 외부 공개 = `UUID publicId`. **API에 내부 PK를 노출하지 않는다.**

### 스키마

**Flyway가 실행 정본**이다. `spring.jpa.hibernate.ddl-auto=validate`를 유지한다 —
`update`/`create`로 바꾸지 않는다. 원본 Prisma 모델은 참고 구현이며 JPA Entity 설계를
그대로 강제하지 않는다.

### 이벤트

- 전달 의미는 **at-least-once**. handler는 멱등해야 한다.
- 소비자 멱등성은 `processed_events` + 비즈니스 UNIQUE 제약으로 둔다.
- 같은 이벤트 흐름을 **커스텀 Outbox와 Spring Modulith가 동시에** 처리하지 않는다.
- 상세: [`docs/rules/lombok-outbox-modulith-policy.md`](docs/rules/lombok-outbox-modulith-policy.md).

### Lombok

기계적 보일러플레이트만 제거한다. 생성 규칙·불변식·상태 전이·엔티티 식별성은 **명시적
으로 작성**한다. 엔티티에 `@Data`·클래스 전체 `@Setter`·무분별한 `@Builder` 금지.
전체 규칙: 같은 문서 §2.

---

## 5. 계약 동등성

외부 계약은 의도적 결정 없이 원본과 달라지지 않는다 (charter §5.1): path·method·
status·요청/응답 DTO·null 및 필드 생략 규칙·RFC 7807 Problem Detail과 확장 속성·
날짜/enum/UUID 직렬화·인증 쿠키와 토큰의 외부 동작.

**계약 diff 없이 "동등하다"고 말하지 않는다.** springdoc이 생성한 OpenAPI를
`upstream/tools/openapi/openapi.json`과 기계적으로 비교한다.

알려진 함정:
- springdoc은 OpenAPI 버전을 **명시 고정**한다 (`springdoc.api-docs.version=openapi_3_0`).
  기준선이 3.0.0이라 안 맞추면 전 엔드포인트가 diff에 뜬다.
- Jackson 날짜는 타임스탬프가 아니라 ISO 문자열(`WRITE_DATES_AS_TIMESTAMPS=false`).
- null 포함/생략 규칙(`@JsonInclude`)을 기준선과 맞춘다.
- 알 수 없는 필드 거부 여부를 기준선과 맞춘다(Spring 기본은 무시).
- `oauth2-resource-server`의 기본 401 바디·`WWW-Authenticate` 헤더는 원본 RFC7807
  봉투와 **다르다.** 엔트리포인트를 오버라이드하거나 커스텀 필터를 쓴다 → ADR 필요.

---

## 6. 검증

**증거 없이 "완료 / 통과 / 고쳐짐"이라고 말하지 않는다.** 명령을 지금 이 세션에서
실행하고 출력을 읽는다. 좁은 것부터:

```bash
./gradlew test --tests '*TeamService*'   # 단일/부분
./gradlew test                            # 전체 테스트
./gradlew build                           # 컴파일 + 테스트
./scripts/check-upstream.sh               # 기획 SSoT 핀 검증
```

위험에 비례해 조합한다: 순수 도메인 단위 → use case 단위 → MVC slice →
Testcontainers 통합(실제 Flyway) → 인증/인가 실패 → 롤백 → 동시성·중복 전달 →
계약 diff.

TDD가 기본이다. **실패 테스트 먼저(red) → 구현(green) → 리팩터.**

---

## 7. Git

- `main`/`master`에 **직접 커밋 금지** (`.githooks/pre-commit`이 차단).
- 브랜치: `<type>/<scope>-<short-description>`
  (`feat|fix|refactor|docs|chore|test|plan|design`)
- 훅 설치: `./scripts/setup-dev.sh` (hooks 경로 + 서브모듈 초기화까지)
- **커밋과 푸시는 요청받았을 때만** 한다.
- 서브모듈 핀 이동은 별도 커밋으로 분리한다 (`chore(upstream): …`).
- 예외 커밋: `SPEC_GATED_ALLOW_PROTECTED_COMMIT=1 git commit ...`

---

## 8. 도구 인벤토리

**스킬** (`.claude/skills/`)
- `spec-gated-development` — Tier 1 운영 스킬. 착수 게이트/완료 게이트를 실제로 걷게 한다.
- `planning-gate` — 이 프로젝트용 착수 게이트. 핀된 upstream에서 BR/수용 기준을 재독하고
  "참조 문서" 노트를 만든다.

**서브에이전트** (`.claude/agents/`)
- `upstream-requirements-query` — 핀된 `upstream/docs/plan/`에서 BR/Feature/EVT/수용
  기준을 원문 발췌로만 조회. 메인 컨텍스트 오염 방지(C4).
- `spring-code-reviewer` — 이 저장소 규약 기준 리뷰(헥사고날 방향, Lombok 정책,
  `@Version` 금지, Flyway 정본, ProblemDetail 패리티, BR 인용 규율).

**훅 / 스크립트**
- `.githooks/pre-commit` — 보호 브랜치 차단 + upstream 편집 차단 + 핀 검증 + 게이트 마커.
- `scripts/check-upstream.sh` — 기획 SSoT 핀 검증 (`--update`로 lock 재생성).
- `scripts/upstream-sync.sh` — 원본 기획 갱신 반영. 인자 없이 실행하면 확인만 하고,
  `--pin <SHA>`로 이동한다. **자동으로 최신까지 끌어올리지 않는다** — diff를 읽는 것이
  이 절차의 목적이기 때문이다 (`docs/upstream/UPSTREAM.md` §4).
- `scripts/setup-dev.sh` — 새 클론 1회 셋업.

**방법론 원문** — [`docs/methodology/`](docs/methodology/) (헌법 · 가이드 · 합성 모델 ·
템플릿). 템플릿(`templates/`)은 슬라이스 스펙/계획/리뷰 플레이북/사례 연구의 골격이다.

---

## 9. 학습 루프

이 프로젝트는 학습·포트폴리오 목적이 명시돼 있다 (charter §2). 비자명한 결과는
버리지 않는다.

- 중요한 Spring 고유 기술 결정 → `docs/adr/`에 ADR로 남긴다.
- 슬라이스 회고(무엇이 깨졌나 · 왜 · 어떻게 고쳤나 · 교훈) →
  `docs/methodology/templates/case-study-template.md` 골격 사용.
- 리뷰에서 **반복되는 지적**은 규칙으로 승격한다 → `docs/rules/` 또는
  `spring-code-reviewer` 체크리스트에 반영 (학습 루프 피드백 엣지).
- 원본 대비 **의도적 차이**는 조용히 두지 않는다. 근거와 함께 기록한다 (charter §9).

---

## 10. 언어

문서·주석·커밋 메시지는 이 저장소의 기존 톤에 맞춰 **한국어**를 기본으로 한다.
사용자 대면 에러 메시지도 원본 계약을 따른다(원본이 한국어면 한국어).
