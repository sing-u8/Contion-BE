# Worship Conti Maker 백엔드 Spring 재구축 헌장

- 상태: Active
- 대상 저장소: `Contion-Spring-BE`
- 원본 저장소: `worship-conti-maker-node-version`
- 최초 기준일: 2026-07-26

## 1. 선언

이 저장소는 Worship Conti Maker의 기존 NestJS 백엔드를 Java 21과 Spring Boot 4.1로 재구축한다.

재구축의 목적은 소스 코드를 파일 단위로 번역하는 것이 아니라, 이미 검증된 제품 요구사항과 외부 계약을 유지하면서 동일한 백엔드 기능을 Java/Spring 생태계의 관용과 장점을 활용하여 독립적으로 구현하는 것이다.

## 2. 목표

### 2.1 학습 목표

- Java 언어와 객체 모델의 실전 활용
- Spring Bean, 의존성 주입 및 Configuration 이해
- Spring Security Filter Chain과 인증·인가 구현
- JPA 영속성 컨텍스트, Dirty Checking, Lazy Loading 및 N+1 제어
- `@Transactional` 프록시 경계와 트랜잭션 원자성 이해
- 비관적 잠금, 조건부 상태 전이 및 다중 인스턴스 동시성 제어
- Transactional Outbox, 재시도, 장애 복구 및 멱등성 구현
- JUnit 5, Spring 통합 테스트 및 Testcontainers 기반 검증

### 2.2 포트폴리오 목표

- 요구사항에서 구현과 테스트까지 이어지는 추적성 제시
- NestJS와 Spring 구현의 계약 동등성을 자동화된 테스트로 입증
- Spring 관용과 도메인 설계 사이의 선택 근거 설명
- 정상 흐름뿐 아니라 중복 전달, 재시작 및 경쟁 조건에 대한 복구 전략 제시

## 3. 범위

### 3.1 포함

- 기존 NestJS 백엔드가 제공하는 제품 API와 비즈니스 기능
- 인증·계정, 악보, 콘티, 팀 및 알림 Bounded Context
- PostgreSQL 영속성
- Redis 기반 세션 및 단기 데이터
- 파일 저장소 Port와 Adapter
- Transactional Outbox와 스케줄 작업
- OpenAPI 계약 생성 및 기준선 비교
- 자동화된 단위·통합·계약 테스트

### 3.2 제외

- Angular 프론트엔드 재구현
- 기존 NestJS 백엔드의 즉시 폐기 또는 교체
- 요구사항 근거 없이 API나 비즈니스 규칙을 새로 설계하는 일
- 원본 내부 클래스와 프레임워크 구조를 그대로 복제하는 일
- 초기 단계의 마이크로서비스 분리

프론트엔드는 기존 Angular 애플리케이션을 유지하며, 장기적으로 동일한 OpenAPI 계약을 통해 두 백엔드 구현을 비교할 수 있도록 한다.

## 4. Source of Truth와 참조 우선순위

원본 기획 문서는 `upstream/` git submodule로 **커밋 SHA에 고정되어** 이 저장소에
읽기 전용으로 들어와 있다. 상대경로로 떠 있는 원본을 참조하지 않는다 — 어느 브랜치·
어느 워킹트리 상태를 읽었는지 사후에 알 수 없기 때문이다.

```text
upstream/docs/plan/          제품 요구사항·전략·전술·DB 설계 (읽기 전용)
upstream/tools/openapi/      API 계약 기준선
```

핀의 근거·현재 SHA·이동 절차는 [`docs/upstream/UPSTREAM.md`](upstream/UPSTREAM.md)에
있다. 핀 검증은 `./scripts/check-upstream.sh`가 수행하며 pre-commit 훅이 이를 강제한다.

판단이 충돌할 때 다음 우선순위를 적용한다.

1. 원본 `docs/plan/1.찬양_콘티_메이커_요구사항명세서.md`
2. 원본 `docs/plan/CONTEXT.md`와 전략·전술·DB 설계 문서
3. 원본 `docs/plan/BR_confusion_catalog.md`의 혼동 경계
4. 원본 `tools/openapi/openapi.json`의 API 계약 기준선
5. 원본 NestJS 자동화 테스트
6. 원본 NestJS 프로덕션 구현

**문서 기준선 버전 표를 이 문서에 손으로 적지 않는다.** 손으로 적은 표는 이미 한 번
드리프트했다 — 이 문서가 DB설계를 `v1.1.1`로 적고 있는 동안 원본은 반나절 만에
`v1.1.1 → v1.1.2 → v1.1.3`으로 움직였다.

현재 기준선은 기계 생성 파일과 스크립트에서 읽는다.

```bash
./scripts/check-upstream.sh     # 핀 SHA + 문서별 버전 + sha256 대조
cat docs/upstream/UPSTREAM.lock # 기계 생성 기준선
```

버전 숫자는 이 헌장에 고정된 영구 정본이 아니다. 각 구현 슬라이스를 시작할 때 핀된 원본 문서의 현재 버전과 관련 요구사항을 다시 확인한다(`planning-gate` 스킬 0~1단계).

## 5. 동등성 원칙

### 5.1 외부 계약

다음 항목은 의도적인 계약 변경 결정이 없는 한 원본과 동등해야 한다.

- URL path와 HTTP method
- request body, query, path parameter 및 validation
- HTTP status
- 성공 response DTO와 null/필드 생략 규칙
- RFC 7807 Problem Detail 및 확장 속성
- 날짜·시간, enum 및 UUID 직렬화
- 인증 cookie와 token의 외부 동작

Spring에서 생성한 OpenAPI와 원본 `tools/openapi/openapi.json`을 기계적으로 비교할 수 있는 계약 하네스를 구축한다.

### 5.2 비즈니스 행위

- 원본 요구사항의 성공·실패·경계 조건을 보존한다.
- 권한 판단과 존재 비노출 정책을 보존한다.
- 트랜잭션 단위와 rollback 의미를 보존한다.
- 이벤트 소비는 중복 전달될 수 있음을 전제로 멱등하게 구현한다.
- 동시성은 원본 설계의 비관적 잠금, 조건부 UPDATE, `FOR UPDATE SKIP LOCKED` 및 ShedLock 의도를 보존한다.
- 의도적으로 철회된 낙관적 락을 근거 없이 다시 도입하지 않는다.

### 5.3 데이터 모델

- 내부 식별자는 Long PK, 외부 공개 식별자는 UUID public ID로 분리한다.
- API에서는 내부 PK를 노출하지 않는다.
- Flyway가 스키마 변경의 실행 정본이 되며 JPA schema validation을 사용한다.
- 기존 Prisma 모델은 참고 구현이고, JPA Entity 설계 자체를 그대로 강제하지 않는다.
- 전용 PostgreSQL 데이터베이스를 사용하며 원본 NestJS 애플리케이션과 같은 운영 DB를 공유하지 않는다.

## 6. 아키텍처 원칙

- 초기에는 단일 Gradle 모듈의 모듈러 모놀리스로 시작한다.
- Bounded Context를 패키지 경계로 명시한다.
- 의존성 방향은 adapter에서 application/domain 쪽으로 향한다.
- 도메인 모델은 Spring과 JPA에 불필요하게 결합하지 않는다.
- 외부 시스템과 영속성은 Port 뒤에 둔다.
- 트랜잭션 경계는 application use case에서 명확하게 관리한다.
- Cross-BC 연동은 직접 Aggregate 참조보다 명시적인 Port 또는 도메인 이벤트를 사용한다.
- 구현 편의를 위해 Aggregate 불변식과 권한 경계를 약화하지 않는다.

세부 코드 규칙은 [`rules/`](rules/)에서 관리한다.

## 7. 단계적 재구축

권장 기본 순서는 다음과 같다.

1. 프로젝트 골격과 계약 검증 하네스
2. 최소 인증 기반
3. Team BC 수직 슬라이스와 첫 Transactional Outbox 흐름
4. Sheet Music BC와 파일 저장소
5. Setlist BC와 스냅샷·동시성 로직
6. Notification BC와 Web Push
7. 인증 하드닝, 운영 작업 및 전체 계약 회귀

각 단계는 작은 수직 슬라이스로 나누며, 한 슬라이스 안에서 요구사항 확인, 실패 테스트, 구현, 통합 검증 및 계약 비교를 완료한다.

## 8. 검증 원칙

모든 기능은 위험에 비례하여 다음 검증을 조합한다.

- 순수 도메인 단위 테스트
- application use case 단위 테스트
- Spring MVC slice 테스트
- PostgreSQL과 Redis Testcontainers 통합 테스트
- 실제 Flyway migration 기반 repository 테스트
- 인증·인가 실패 테스트
- 트랜잭션 rollback 테스트
- 동시성 및 중복 전달 테스트
- 원본 OpenAPI와의 계약 diff

테스트를 실행하지 않은 상태에서 동등성이나 완료를 선언하지 않는다.

## 9. 변경 관리

- 제품 요구사항을 변경해야 한다면 먼저 원본 저장소의 SSoT 정합 문제로 다룬다.
- Spring에만 적용되는 기술 결정은 이 저장소의 ADR에 기록한다.
- 계약 차이는 자동화된 diff에서 허용 목록 없이 묵인하지 않는다.
- 원본 동작의 결함을 발견했더라도 조용히 다르게 구현하지 않는다. 요구사항과 테스트를 확인하고 수정 또는 의도적 차이를 기록한다.
- 원본 기획 문서를 이 저장소에 복제하여 두 번째 정본으로 만들지 않는다.

## 10. 완료 정의

재구축 완료는 단순히 엔드포인트가 실행되는 상태를 뜻하지 않는다. 다음 조건을 모두 충족해야 한다.

- 합의된 백엔드 범위가 구현되어 있다.
- 원본 요구사항의 관련 인수조건이 자동화된 테스트로 검증된다.
- OpenAPI 계약 차이가 없거나 모든 차이가 승인된 결정으로 설명된다.
- Flyway migration만으로 빈 데이터베이스를 구성할 수 있다.
- 중복 이벤트, 재시작 및 다중 인스턴스 경쟁 상황이 검증된다.
- 주요 설계 결정과 원본 대비 차이를 문서로 설명할 수 있다.

## 11. Docs consulted / Planning gate

- Feature(s): 전체 백엔드 재구축 헌장. 개별 Feature 구현 범위를 확정하지 않음.
- BRs: 이 문서는 개별 BR 번호를 인용하지 않음.
- BR confusion boundaries checked: 개별 슬라이스에 적용하지 않음. 슬라이스 시작 시 관련 항목을 원본 `BR_confusion_catalog.md`에서 확인한다.
- Upstream design docs read: 요구사항 v8.114, 전략설계 v1.1.0, 전술설계 v1.1.0, DB설계 v1.1.1, `CONTEXT.md`의 현재 기준 메타데이터와 목적·범위.
- Conflicts found / resolution: 없음. 이 헌장은 원본 제품 SSoT를 변경하지 않고 Spring 재구현의 목적과 참조 관계만 명시한다.
