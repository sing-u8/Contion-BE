# Contion Spring Backend

Worship Conti Maker의 기존 NestJS 백엔드를 **Java 21과 Spring Boot 4.1로 재구축**하는 학습 및 포트폴리오 프로젝트입니다.

이 저장소의 목표는 기존 TypeScript 코드를 Java 문법으로 단순 번역하는 것이 아닙니다. 원본 시스템의 제품 요구사항, API 계약 및 비즈니스 동작을 보존하면서 내부 구현을 Spring과 JPA의 관용적인 방식으로 다시 설계하고 검증합니다.

## 프로젝트 목적

- Java/Spring 기반 기업 취업을 위한 실전 백엔드 학습
- Spring Security, JPA, 트랜잭션, 동시성 제어 및 Transactional Outbox 학습
- DDD와 헥사고날 아키텍처의 Spring 기반 구현
- 기존 NestJS 백엔드와의 행위 및 API 계약 동등성 검증
- 설계 결정과 장애 복구 근거를 설명할 수 있는 포트폴리오 구축

## 원본 프로젝트와의 관계

원본 저장소는 로컬 기준 `../worship-conti-maker-node-version`에 있습니다.

| 자료 | 역할 |
| --- | --- |
| 원본 `docs/plan/` | 제품 요구사항과 DDD 설계의 SSoT |
| 원본 `tools/openapi/openapi.json` | 외부 API 계약 기준선 |
| 원본 NestJS 테스트 | 실행 가능한 행위 오라클 |
| 원본 NestJS 프로덕션 코드 | 동작하는 참조 구현 |
| 이 Spring 저장소 | 동일 제품 백엔드의 독립적인 Java/Spring 구현 |

원본 코드와 기획 문서가 충돌하면 원본 저장소의 `docs/plan/`을 우선합니다. Spring 저장소에서 요구사항을 추측하거나 별도의 제품 정본을 만들지 않습니다.

## 재구축 원칙

### 보존하는 것

- 비즈니스 규칙과 도메인 용어
- 엔드포인트 경로, HTTP 메서드, 상태 코드 및 요청·응답 계약
- RFC 7807 기반 오류 계약
- 내부 Long PK와 외부 UUID public ID를 분리하는 식별자 모델
- 트랜잭션 원자성, 권한, 멱등성 및 동시성 의미
- PostgreSQL, Redis, 파일 저장소 및 Outbox의 책임 경계

### Spring 방식으로 재설계할 수 있는 것

- 패키지와 클래스 구조
- Spring Security Filter Chain 구성
- JPA Entity와 도메인 Aggregate의 분리 방식
- Repository와 Adapter 구현
- Jackson, Bean Validation 및 ProblemDetail 활용 방식
- 스케줄러와 인프라 구성 방식

내부 구현 차이는 허용하지만, 외부 계약 또는 제품 행위가 달라지는 변경은 근거와 검증 없이 허용하지 않습니다.

## 기술 스택

- Java 21
- Spring Boot 4.1
- Gradle Kotlin DSL
- Spring Web MVC
- Spring Security / OAuth2 Resource Server
- Spring Data JPA
- PostgreSQL
- Spring Data Redis
- Flyway
- Bean Validation
- Actuator / Micrometer Prometheus
- JUnit 5 / Spring Boot Test / Testcontainers

## 문서

- [재구축 헌장](docs/reimplementation-charter.md)
- [문서 인덱스](docs/README.md)
- [Lombok 및 Outbox/Modulith 적용 규칙](docs/rules/lombok-outbox-modulith-policy.md)

## 현재 상태

Spring Boot 프로젝트 골격과 기본 의존성을 구성한 초기 단계입니다. 기능 구현은 원본 요구사항과 계약을 기준으로 작은 수직 슬라이스 단위로 진행합니다.

## 기본 검증

```bash
./gradlew test
```

기능 구현이 진행되면 단위 테스트, Testcontainers 통합 테스트 및 OpenAPI 계약 비교를 검증 파이프라인에 추가합니다.
