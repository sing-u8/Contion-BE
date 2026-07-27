# Spring 번역 지도 (Translation Map)

- 상태: Active
- 적용 대상: `Contion-Spring-BE`
- 기준 upstream 핀: `docs/upstream/UPSTREAM.lock` 참조 (`./scripts/check-upstream.sh`)

---

## 1. 이 문서의 책임 — 그리고 하지 않는 것

원본 기획 문서(`upstream/docs/plan/`)의 전술·DB 층에는 NestJS/Prisma 표현이 섞여
있다. 이 문서는 그것을 **Spring으로 어떻게 읽을 것인가**만 적는다.

**이 문서는 원본을 재서술하지 않는다. 차이(delta)만 적는다.**

원본 기획을 이 저장소로 복제하면 두 번째 정본이 생기고, 6개월 뒤 원본에서 BR 하나가
바뀌었을 때 이쪽 사본은 따라가지 않는다. 그 순간 이 프로젝트의 핵심 주장인 **"계약·
행위 동등성 검증"이 무너진다.** charter §9가 복제를 금지하는 이유다.

## 2. 왜 "번역"이 정당한가 — 원본이 직접 그렇게 지시한다

이 문서는 임의의 재해석이 아니다. 원본 SSoT가 스택 전환 규칙을 **명시적으로** 적어
두었다.

> **`upstream/docs/plan/planning-sync-audit.md` §2.2**: "전술설계와 DB설계의
> Java/Spring/JPA/jOOQ/Flyway 표현은 계약 의사 코드 또는 legacy reference다. …
> 별도 Spring Boot 학습 재구현은 같은 BR·이벤트·물리 의도를 타깃 스택으로 번역한다."

> **동 §3 (표 하단)**: "도메인 규칙, BR, 이벤트, Aggregate 경계, Port 이름, UseCase
> 책임은 **유지**한다. 바꾸는 것은 **구현 프레임워크와 persistence adapter**다."

즉 원본 설계는 원래 Spring 어휘로 쓰였다가 NestJS로 번역된 것이고, 그 번역표가 §3에
그대로 남아 있다. **Spring 재구현은 그 표를 역방향으로 읽으면 된다.**

### 2.1 ⚠️ 그러나 legacy Java 표현을 코드로 베끼지 말 것 (2026-07-27 갱신)

원본 v1.1.4~v1.1.9 정합 라운드에서 전술설계의 **Java 시절 흔적이 대부분 제거되거나
"legacy"로 명시**됐다. 남아 있는 것도 구현과 다르다.

> **`upstream/docs/plan/3.전술설계_DDD_Phase2.md` v1.1.3 §3 주석**: "본 §3은 **'제약의
> SSoT'이지 '코드 구조의 SSoT'가 아니다.** … `UserName`·`StorageKey` 같은 이름을
> 코드에서 찾지 말 것 — 존재하지 않는다. `record` 시그니처는 §1.2.A 전환표가 규정한
> legacy 표현이다."

> **동 문서 §1.2 (v1.1.3)**: "본문·`text` 코드 블록에 남은 `*Exception` 표기 … 는
> **§1.2.A 전환표가 규정한 Java 시절 legacy 표현**이며 구현 클래스명이 아니다.
> `DomainException`·`PermissionDeniedException`·`InvalidValueException` 등은 **코드에
> 존재하지 않는다** — 실제 에러는 `AppException`을 상속한 작업별 `*Error` 196개다."

구체적으로 무엇이 사라졌나:

| 없어진 것 | 대체된 것 | Spring 프로젝트에 대한 의미 |
| --- | --- | --- |
| VO의 Java `record` 시그니처 (`public record UserName(String value) {...}`) | **제약 표**(VO · 제약(BR) · 입력 경계 강제 · 저장 경계 강제 · 도메인 코드) | 베낄 Java 코드가 없어졌다. 대신 제약 표는 **스택 중립**이라 더 나은 입력이다 — Bean Validation·CHECK 제약으로 바로 번역된다 |
| Port/Aggregate의 Java 시그니처 | TypeScript 시그니처 | TS → Java 타입 번역이 필요하다 (§4.1) |
| `*Exception` 예외 이름 | `AppException` + 작업별 `*Error` 196개 | 문서의 `*Exception`은 **구현에 없는 이름**이다. 인용하지 말 것 |

**따라서 §2의 "역방향으로 읽는다"는 이제 문서에 남은 Java 텍스트를 가리키지 않는다.**
보존해야 할 것은 **의미**(제약·책임·이름 규약)이지 그 시절 표기가 아니다.

## 3. 층위별 정본 — 무엇을 복제하지 않는가

| 층위 | 내용 | 정본 |
| --- | --- | --- |
| **제품이 무엇을 하나** | BR · Feature · EVT · Gherkin 수용 기준 · 혼동 경계(CP) | `upstream/docs/plan/1.*`, `BR_confusion_catalog.md` — **복제 절대 금지** |
| **도메인 분해** | BC 경계 · 컨텍스트 맵 · Aggregate 경계 · 불변식 · 도메인 이벤트 · 식별자/삭제/권한 정책 | `upstream/docs/plan/2.*`, `3.*` — **참조만** |
| **스택 결속 전술** | 패키지/클래스 구조 · JPA 매핑 · 트랜잭션 표현 · Security filter chain · Outbox relay · 직렬화 | **이 저장소** (이 문서 + `docs/adr/`) |
| **스키마** | 테이블·컬럼·인덱스·제약 | 논리 = `upstream/docs/plan/4.*` / **물리 실행 = `src/main/resources/db/migration/V*.sql`** |
| **외부 API 계약** | path · method · status · DTO · 에러 봉투 | `upstream/tools/openapi/openapi.json` (기준선) |

관측된 사실 (2026-07-27 기준 핀):

| 원본 문서 | Spring/JPA 계열 언급 | Nest/Prisma 계열 언급 | 판정 |
| --- | --- | --- | --- |
| `2.전략설계` | 2 | — | **사실상 스택 중립. delta 없음, 원본 그대로 사용.** |
| `3.전술설계` | 123 | 171 | 혼재 → **아래 §4 번역표 적용** |
| `4.DB설계` | 111 (Prisma 포함) | — | 논리는 원본, **물리 실행 정본은 Flyway** |

## 4. 번역표 — sync-audit §3의 역방향

| 원본 문서 표현 (NestJS 기준) | 이 저장소에서의 해석 (Spring) |
| --- | --- |
| Nest REST controller | `@RestController` (`adapter.in.web`) |
| Nest provider/module wiring | Spring Bean + 생성자 주입 (`@Configuration`/`@Component`) |
| Prisma schema model + mapper | JPA `@Entity` (`adapter.out.persistence`) + 도메인 모델 매퍼 |
| Prisma repository adapter behind an output port | Spring Data JPA Repository를 감싼 **out port 구현 adapter** |
| Prisma query method behind a port | `@Query` 또는 Specification/QueryDSL, **port 뒤** |
| Prisma search adapter / raw SQL adapter | 동적 검색 adapter (`NativeQuery` 또는 Criteria), **search port 뒤** |
| Prisma Migrate | **Flyway** (`V*.sql`) — 실행 정본 |
| Nest DTO validation pipe + 도메인 VO 불변식 | Bean Validation(`jakarta.validation`) + 도메인 VO 불변식 |
| Nest guard/interceptor + JWT service | Spring Security Filter Chain + JWT 디코딩 필터 |
| `argon2` package (Argon2id) behind `PasswordHasherPort` | `Argon2PasswordEncoder`(BouncyCastle 필요) behind `PasswordHasherPort` |
| Nest Schedule interval/cron + ShedLock | `@Scheduled` + `net.javacrumbs.shedlock` |
| Access Token JSON 응답 + Refresh HttpOnly 쿠키 | **동일하게 유지** — 외부 계약이다 |

> **주의**: 마지막 행은 번역 대상이 **아니다.** 인증 토큰의 외부 동작은 charter §5.1의
> 보존 항목이다. 표에 넣은 이유는 "이건 안 바꾼다"를 명시하기 위해서다.

### 4.1 TypeScript → Java (2026-07-27 신설)

전술설계의 Port/Aggregate 시그니처가 TypeScript로 전환됐으므로(§2.1) 이 방향의 표가
필요하다.

| 원본 문서 (TypeScript) | 이 저장소 (Java) |
| --- | --- |
| `Promise<T>` 반환 | `T` 반환 (동기). 비동기가 필요한 곳은 별도 판단 |
| `T \| null` | `Optional<T>` (조회 결과) / `@Nullable T` (필드) |
| `type MusicKey = 'C' \| 'C#/Db' \| …` (union) | `enum MusicKey` — 단, **외부 계약 문자열**은 union 값 그대로 직렬화 |
| `class TeamRole` (계층 비교 보유) | `enum TeamRole` + 비교 메서드 |
| `readonly` 필드 | `final` 필드 |
| `interface XxxPort` | `interface XxxPort` (이름 동일) |
| `class-validator` 데코레이터 (`@Length` · `@IsIn` · `@IsUUID`) | Bean Validation (`@Size` · `@Pattern`/커스텀 · `@UUID` 커스텀) |
| `AppException` + 작업별 `*Error` | §6 "예외 이름" 행 참조 — **의도적 차이 후보** |

## 5. 보존 vs 번역 — 판정 기준

슬라이스 중 판단이 갈리면 이 기준을 적용한다.

**반드시 보존 (바꾸면 재구현이 아니라 다른 제품)**
- BR · Feature · EVT 번호와 의미
- Aggregate 경계와 불변식
- Port **이름**과 UseCase **책임 분할**
- 도메인 이벤트의 발행 시점·payload 의미
- 권한 판단 순서와 존재 비노출 정책
- 트랜잭션 단위와 rollback 의미
- 외부 API 계약 전체 (charter §5.1)
- 내부 `Long` PK / 외부 `UUID publicId` 분리

**번역 자유 (Spring 관용을 따른다)**
- 패키지·클래스·파일 구조
- Bean 등록·설정 방식
- JPA 매핑 세부 (연관관계 방향, fetch 전략, `@Convert`)
- Repository/Adapter 구현 기법
- Jackson·Bean Validation·`ProblemDetail` 활용 방식
- 스케줄러 구성 방식

## 6. 이 저장소 고유 결정 (원본에 대응물이 없는 것)

원본이 정하지 않았거나, Spring이라서 새로 정해야 하는 항목. **결정할 때마다 여기에
행을 추가하고, 트레이드오프가 있으면 `docs/adr/`로 승격한다.**

| 항목 | 결정 | 근거 / 상태 |
| --- | --- | --- |
| Outbox 1차 구현 | 커스텀 Transactional Outbox (Modulith는 2차 비교 실험) | `docs/rules/lombok-outbox-modulith-policy.md` §5 |
| 낙관적 락 | **도입 금지.** 비관 락 · 조건부 UPDATE · Unique 제약 · ShedLock | 원본이 미배선 `version` 12개를 의도적으로 철회 |
| 아키텍처 경계 강제 | ArchUnit 테스트 | 원본은 Python import 가드로 강제했음. 문서만으로는 안 지켜진다 |
| OpenAPI 버전 | `springdoc.api-docs.version=openapi_3_0` 고정 | 기준선(82 path · 168 schema)이 3.0.0. 미고정 시 3.1로 나와 전 엔드포인트 diff. **알려진 잔여 차이**: springdoc의 `OPENAPI_3_0`은 헤더를 `3.0.1`로 찍는다 → 계약 diff에서 `openapi` 필드 1줄은 허용 목록 대상 |
| 인증 필터 방식 | **미결** — `oauth2-resource-server` vs 커스텀 필터 | 기본 401 바디·`WWW-Authenticate`가 RFC7807 봉투와 다름 → **ADR 필요** |
| **VO 클래스 승격 범위** | 원본과 동일한 **선택적 승격**. "값 자체에 로직이 있는가"가 기준 | 아래 §6.2 |
| **예외 클래스 이름** | **미결** — `*Error`(원본 동일) vs `*Exception`(Java 관례) | 아래 §6.3. 에러 **코드**는 외부 계약이라 보존 필수 |
| **Notification 패키지** | `notification`에 **domain 없음.** 포트·어댑터·유스케이스만 | 아래 §6.4 — 원본이 Aggregate → Projection으로 재분류 |
| **파일 개수 상한 동시성** | **의도적 차이 예정** — 원본의 "우연한 보호"를 명시적 잠금으로 대체 | 아래 §6.5 |
| 도메인 순수도 | **(A) 순수 도메인.** `domain`에서 `jakarta.persistence`·`org.springframework` import 금지. 도메인 모델 / JPA 엔티티 분리 + adapter 매퍼. `@Entity`는 `adapter.out.persistence`에만 | 아래 §6.1 |
| Argon2 파라미터 | **미결** — 원본 `argon2` 설정과 대조 필요 | 전용 DB라 해시 호환은 불필요하나 알고리즘/강도는 문서화 |

### 6.1 도메인 순수도 — (A) 채택 근거

charter §6은 "도메인 모델은 Spring과 JPA에 **불필요하게** 결합하지 않는다"까지만
말하고 그 선을 긋지 않았다. 여기서 긋는다: **domain은 영속성/프레임워크 타입을 전혀
알지 않는다.**

1. **Port가 장식이 되지 않게 한다.** 도메인이 `jakarta.persistence`에 컴파일
   의존하면, out port 인터페이스를 아무리 예쁘게 만들어도 의존성 역전을 했다고 말할
   수 없다. 헥사고날을 주장할 때 가장 먼저 검증받는 지점이다.
2. **이중 식별자 모델이 요구한다.** 이 프로젝트는 내부 `Long` PK와 외부
   `UUID publicId`를 분리한다(charter §5.3). 엔티티를 도메인으로 겸용하면 도메인
   객체가 **도메인적으로 무의미한** `Long id`를 들고 다니게 된다. 분리하면 도메인은
   `TeamId(UUID)`만 알고 `Long`은 어댑터 안에서만 산다.
3. **상태 전이가 dirty checking에 숨지 않는다.** 겸용 방식에서는 managed 엔티티의
   메서드 호출이 곧 영속이라 애그리거트 저장 시점이 트랜잭션 경계에 묻힌다. 분리하면
   use case가 `save(...)`를 명시적으로 부르므로 unit of work가 코드에 드러난다.
   DRAFT/PUBLISHED 같은 상태 기계가 있는 이 도메인에서 실질적 차이다.
4. **기존 규칙이 이미 이 방향이었다.** `docs/rules/lombok-outbox-modulith-policy.md`
   §2.2가 요구하는 `reconstitute(...)` 팩토리는 정의상 (A)의 산물이다 — 겸용
   방식에는 존재할 이유가 없는 메서드다.

**치르는 비용**: Aggregate마다 도메인 클래스 + JPA 엔티티 + 매퍼가 생긴다. 학습
목표인 영속성 컨텍스트·dirty checking·N+1 제어는 그대로 배운다 — 도메인이 아니라
**어댑터 안에서** 다루게 될 뿐이고, 로딩·flush 시점을 매퍼 경계에서 명시적으로
결정해야 해서 오히려 더 또렷해진다.

**강제 수단**: `ArchitectureRulesTest`의 `domain은_프레임워크에_결합되지_않는다`,
`JPA_엔티티는_persistence_adapter에만_산다`. 이 규칙을 지우려면 위 4개 논거를
반박하고 ADR을 남긴다.

**아직 열린 것**: 도메인 VO의 Jackson 결합(예: `AnnotationDocument` 256KB JSONB).
그 슬라이스에서 매핑 방식을 정하고, `ArchitectureRulesTest`의 선택적 강화 규칙
(`domain은_Jackson을_모른다`)을 켤지 함께 결정한다.

### 6.2 VO 승격 범위 — 31종 명세 ≠ 31개 클래스

전술설계 §3은 **31종 VO를 명세**하지만, 원본 구현은 **10종만 클래스로 만들었다.**
나머지 21종의 제약은 네 층에서 강제된다.

> **`upstream/docs/plan/3.전술설계_DDD_Phase2.md` v1.1.6 §3 주석**: "**VO 클래스가
> 실재하는 10종의 공통점**: 값 자체에 **로직**이 있다 — `ChordProgression`(스텝 배열
> 파싱·직렬화) · `ReferenceUrl`(정규화) · `AnnotationDocument`(바이트 크기 계산) ·
> `MusicKey`(`C_SHARP_DB` → "C#/Db" 표시 라벨) · `TeamRole`(계층 비교). 반면 부재한
> 21종은 **길이·형식 검사뿐**이라 `@Length(1, 25)` 한 줄이 하는 일을 클래스로 감싸는
> 셈이 된다. 이는 누락이 아니라 일관된 판단이며, §3.1 승격 기준 4개 중 '검증 규칙
> 보유' 하나만으로 승격한 것이 과했다."

**이 저장소도 같은 기준을 따른다.** 4계층 강제를 Spring 어휘로 옮기면:

| 층 | 원본 (Nest) | 이 저장소 (Spring) |
| --- | --- | --- |
| ① 입력 경계 | 입력 DTO `class-validator` | 요청 DTO **Bean Validation** (`@Size` · `@Email` · 커스텀) |
| ② 컨트롤러 | multer `limits` | `MultipartFile` 크기 제한 (`spring.servlet.multipart.max-file-size`) |
| ③ 유스케이스 | 명시 검증 + 도메인 에러 | use case 내 명시 검증 + 도메인 예외 |
| ④ 저장 경계 | CHECK · UNIQUE · ENUM | **동일** — Flyway가 같은 제약을 만든다 |

**왜 이걸 그대로 따르는가**: `937f6c6d`이 삭제한 legacy Java `record` 시그니처
(`UserName`·`Email`·`Password`…)가 정확히 "31개 클래스를 만들어라"로 오독되기 쉬운
텍스트였다. 그 텍스트는 구현된 적이 없고, 원본이 그것을 과잉으로 판단해 제거했다.
동일한 판단이 Spring에도 성립한다 — `record UserName(String value)`가 `@Size(min=1,
max=25)` 한 줄을 감싸기만 한다면 클래스를 만들 이유가 없다.

**(A) 순수 도메인 결정과의 관계**: 충돌하지 않는다. (A)는 **애그리거트**가 JPA를
모르게 하는 결정이고, 이건 **VO를 몇 개 만들 것인가**의 문제다. 다만 결과적으로
domain 패키지는 얇아진다 — **애그리거트 + 로직 보유 VO 10종 + 열거 5종** 정도다.
그것이 정상이며, 빈 껍데기 VO로 부풀리지 않는다.

### 6.3 예외 이름 — 코드는 계약, 클래스명은 구현

원본의 예외 체계가 정합 과정에서 명확해졌다.

> **`3.전술설계_DDD_Phase2.md` v1.1.3 §1.2**: "`DomainException`·`PermissionDeniedException`·
> `InvalidValueException` 등은 코드에 존재하지 않는다 — 실제 에러는 `AppException`을
> 상속한 작업별 `*Error` 196개다."

**보존 대상 (외부 계약)** — 이건 번역 자유가 아니다:
- 에러 **코드** (`CommonApiErrorCodes.UNAUTHORIZED`, `AuthApiErrorCodes.PASSWORD_RESET_RATE_LIMITED` …)
- HTTP status, RFC 7807 봉투와 확장 속성
- 어떤 실패가 어떤 코드가 되는가 (전술 §8.9 에러 계약, §10.3 계층 구조)

**미결 (내부 구현)** — 클래스 **이름**:
- 원본과 동일하게 `*Error`로 갈 것인가, Java 관례대로 `*Exception`으로 갈 것인가.
- 전술설계의 UseCase 카탈로그 "주요 예외" 열이 구현 클래스명과 전수 일치하도록
  정합됐으므로(§1.2), `*Error`를 쓰면 **문서가 그대로 스펙이 된다**는 실익이 있다.
- 반대로 Java에서 `Throwable` 하위 타입을 `*Error`로 부르면 `java.lang.Error`와
  혼동된다 — 이건 실질적 위험이다.
- **첫 인증 슬라이스에서 ADR로 결정한다.** 어느 쪽이든 에러 코드는 그대로다.

### 6.4 Notification은 Aggregate가 아니라 Projection

원본이 구현 대조 결과 **Notification·PushSubscription을 Aggregate Root → Projection
Root로 재분류**했다(전략설계 v1.1.1). 총계도 `9 AR` → `7 Aggregate(5 AR + 2 Sub-AR)
+ 2 Projection`으로 정정됐다.

> **`2.전략설계_DDD_Phase1.md` §4.5**: "상태 전이는 `생성(멱등)`과 `readAt: null →
> 시각` 둘뿐이고 **여러 필드에 걸친 규칙도, 순서 규칙도, 자식 엔티티 컬렉션도 없다.**
> 여기에 Aggregate Root를 두면 필드 2개에 규칙 0개인 빈 껍데기가 생긴다 — 보호할 것이
> 없는 트랜잭션 경계다."

**이 저장소에 대한 직접 영향**: 초기 스캐폴딩이 5개 BC 전부에 `domain` 패키지를
만들었으나, **`notification`에는 도메인 모델을 두지 않는다.** 포트 · 어댑터 ·
유스케이스로 구성한다. `ArchitectureRulesTest`가 이를 강제한다.

**재검토 트리거** (원본 §4.5) — 다음이 도입되면 Aggregate 승격을 재평가한다:
① 다중 행에 걸친 규칙(사용자당 미읽음 상한, 알림 그룹화) ② 알림 상태 기계가 2단계
초과(보류·스누즈·재알림) ③ 사용자별 알림 설정이 Notification과 같은 트랜잭션에서
검증돼야 하는 경우.

### 6.5 BR-SM-012 파일 개수 상한 — 재현하면 안 되는 "우연한 보호"

원본이 자기 구현의 취약점을 문서화했다. **charter §9("원본 동작의 결함을 발견했더라도
조용히 다르게 구현하지 않는다 — 수정 또는 의도적 차이를 기록한다")가 정확히 걸리는
지점이다.**

> **`3.전술설계_DDD_Phase2.md` v1.1.9 §9.5.4**: "`uq_sheet_music_files_sm_order
> (sheet_music_id, display_order)`는 **INV-SM-03(순서 유일성)** 을 위한 인덱스다.
> 개수 상한과는 무관하게 만들어졌다. 그런데 `display_order`를 `max + 1`로 채번하기
> 때문에 동시 삽입이 **반드시 같은 값을 요구**하게 되고, 그 충돌이 유니크 인덱스에
> 걸려 결과적으로 개수 경합까지 직렬화한다. … 하나는 설계된 보호, 하나는 우연한
> 보호다."

**Spring에서 이게 왜 위험한가**: charter §5.2는 "동시성은 원본 설계의 비관적 잠금 …
의도를 보존한다"고 했다. 그런데 **여기엔 보존할 의도가 없다.** 그리고 JPA로
재구현하면서 `display_order` 채번을 바꾸면(`@OrderColumn`, 시퀀스, 정렬 키 등)
보호가 **조용히** 사라진다 — 원본 문서가 지적한 그대로 "채번을 바꾸는 사람은 자기가
개수 상한을 깨뜨렸다는 사실을 알 수 없다."

**결정**: bc2 파일 업로드 슬라이스에서 개수 상한을 **명시적으로** 잠근다 —
BR-TM-010(팀 정원 100)이 쓰는 `SELECT … FOR UPDATE` + 트랜잭션 내 재계산과 동일한
방식. 이유는 세 가지다.
1. 원본이 스스로 "설계된 보호가 아니다"라고 기록했다.
2. Spring 재구현은 채번 방식이 달라질 가능성이 높다 — 보호가 사라지는 조건이다.
3. **동시성 제어는 이 프로젝트의 명시적 학습 목표다**(charter §2.1). 같은 코드베이스
   안에 "설계된 보호"와 "우연한 보호"가 공존하는 것을 재현할 이유가 없다.

**의도적 차이로 기록한다.** 외부 계약(11개가 되지 않는다·`TOO_MANY_FILES`)은 동일하고,
바뀌는 것은 그 보장을 만드는 방식뿐이다. 동시 업로드 테스트를 반드시 함께 작성한다.

**부수 관찰 (원본 §9.5.4)**: 경합 시 P2002가 `PERSISTENCE_FAILED`로 보고된다(원인이
"동시 업로드 충돌"인데 "저장 실패"로 표시). 명시적 잠금으로 가면 이 표면도 자연히
정확해지지만, **에러 코드는 외부 계약이므로 바꾸기 전에 기준선 diff를 확인한다.**

### 6.6 DB설계 문서가 Flyway V1의 신뢰할 수 있는 입력이 됐다

핀 이동으로 들어온 변경 중 **Flyway 베이스라인 작업을 직접 de-risk하는 것**이 있다.
DB설계가 `0276a464`에서 **구현 마이그레이션과 전수 대조**됐고, 이후 유령 DDL이
제거됐다.

| 항목 | 정정 내용 | Flyway V1에 대한 의미 |
| --- | --- | --- |
| 테이블 수 | 22 → **23** | 누락 테이블이 있었다 |
| `team_invitations` 인덱스 | `idx_team_invitations_pending_expires` (유령) → **`idx_team_invitations_invitee_pending_active ON team_invitations (lower(invitee_email), created_at DESC)`** | 이전 문서대로 썼으면 **존재하지 않는 인덱스**를 만들었다 |
| `team_invitations` 트리거 | `trg_before_update_team_invitations_set_updated_at` **제거** — §2.3이 "이 테이블엔 트리거가 없다"고 했는데 DDL 블록에 남아 있었다 | 유령 트리거를 만들었다 |

또한 원본에 **인덱스 표류 가드**(`scripts/guards/prisma_index_manifest.json`)와
**기획 정합성 가드**(`scripts/guards/check_planning_consistency.py`, pre-commit
blocking)가 생겨서, 앞으로 DB 문서와 실제 스키마가 갈라지면 원본 쪽에서 먼저 잡힌다.

**결론**: 핀된 `4.DB설계_Phase3.md` v1.1.5는 Flyway V1 베이스라인의 **1차 입력으로
신뢰할 수 있다.** 다만 물리 실행 정본은 여전히 `V*.sql`이며(§3), 작성 후
Testcontainers + `ddl-auto=validate`로 JPA 매핑과 교차 검증한다.

## 7. 갱신 규칙

- 번역 규칙이 없는 새 항목을 만나면 **그 슬라이스의 산출물로** §4 또는 §6에 행을 추가한다.
- upstream 핀을 올렸을 때(`UPSTREAM.md` §5) 전술/DB 문서에 스택 표현 변화가 있으면
  이 문서를 함께 갱신한다.
- 원본을 그대로 옮겨 적고 싶어지면 멈춘다 — 그건 §1이 금지하는 복제다.
