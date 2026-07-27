# Lombok 및 Outbox/Modulith 적용 규칙

- 상태: Accepted
- 적용 대상: `Contion-Spring-BE`
- 기준 스택: Java 21, Spring Boot 4.1

## 1. 핵심 원칙

1. Lombok은 기계적인 보일러플레이트를 줄이는 데 사용한다.
2. 객체 생성 규칙, 불변식, 상태 전이, 엔티티 식별성처럼 도메인 의미가 있는 코드는 명시적으로 작성한다.
3. 현재 NestJS 구현과 동등한 장애 복구 의미를 먼저 재현하기 위해 커스텀 Transactional Outbox를 우선 구현한다.
4. Spring Modulith는 커스텀 Outbox 구현 이후 비교 실험 대상으로 사용한다.
5. 같은 이벤트 흐름에 커스텀 Outbox와 Spring Modulith를 동시에 운영하지 않는다.

## 2. Lombok 사용 규칙

이미 Lombok이 생성하는 코드를 이해하고 있다면 getter나 생성자를 학습 목적으로 반복해서 작성할 필요는 없다. 다만 Lombok이 도메인 API 설계를 대신하게 해서는 안 된다.

### 2.1 허용 및 권장

- Spring 서비스와 어댑터
  - `@RequiredArgsConstructor`
  - `@Slf4j`
- JPA 엔티티
  - `@Getter`
  - `@NoArgsConstructor(access = AccessLevel.PROTECTED)`
- 테스트 Fixture와 Test Data Builder
  - `@Builder`
- 단순 요청·응답 DTO, Command, Query 결과
  - Lombok보다 Java `record`를 우선 고려한다.

### 2.2 명시적으로 작성할 것

다음 코드는 보일러플레이트가 아니라 모델의 의미이므로 직접 작성한다.

- 이름이 있는 생성 팩토리: `create(...)`, `invite(...)`, `reconstitute(...)`
- 불변식을 검증하는 생성 로직
- 상태를 변경하는 행위 메서드: `rename(...)`, `acceptInvitation(...)`
- Aggregate 경계를 지키는 상태 전이
- JPA 엔티티의 식별성에 맞춘 `equals()`와 `hashCode()` 정책
- 연관관계 변경과 양방향 연관관계 동기화 로직

**전제: 도메인 모델과 JPA 엔티티는 분리한다.** 불변식과 상태 전이는 **도메인**이
소유하고, JPA 엔티티는 영속성 표현만 담당한다. 이 결정과 근거는
[`../design/spring-translation-map.md`](../design/spring-translation-map.md) §6
"도메인 순수도" 행에 있고, `ArchitectureRulesTest` 가 기계적으로 강제한다.

도메인 — 불변식과 행위가 여기 산다. 프레임워크 타입을 import 하지 않는다.

```java
// team/domain/Team.java  — Lombok 도, JPA 도 없다.
public class Team {

    private final TeamId id;          // UUID 기반 도메인 식별자. Long PK 는 모른다.
    private TeamName name;

    private Team(TeamId id, TeamName name) {
        this.id = id;
        this.name = name;
    }

    /** 새 팀 생성 — 불변식은 VO 와 이 팩토리가 소유한다. */
    public static Team create(TeamId id, TeamName name) {
        return new Team(id, Objects.requireNonNull(name, "팀 이름은 필수입니다."));
    }

    /** 영속 상태에서 재구성 — adapter 의 매퍼만 호출한다. 불변식 재검증 없음. */
    public static Team reconstitute(TeamId id, TeamName name) {
        return new Team(id, name);
    }

    public void rename(TeamName name) {
        this.name = Objects.requireNonNull(name, "팀 이름은 필수입니다.");
    }

    public TeamId id() { return id; }

    public TeamName name() { return name; }
}
```

JPA 엔티티 — 영속성 표현. Lombok 은 **여기서** 보일러플레이트를 줄인다.

```java
// team/adapter/out/persistence/TeamJpaEntity.java
@Entity
@Table(name = "teams")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
class TeamJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;                  // 내부 PK. 도메인에 노출하지 않는다.

    @Column(nullable = false, unique = true, updatable = false)
    private UUID publicId;            // 외부 공개 식별자

    @Column(nullable = false)
    private String name;

    static TeamJpaEntity from(Team team) {
        TeamJpaEntity e = new TeamJpaEntity();
        e.publicId = team.id().value();
        e.name = team.name().value();
        return e;
    }

    void apply(Team team) {           // 기존 row 갱신
        this.name = team.name().value();
    }

    Team toDomain() {
        return Team.reconstitute(new TeamId(publicId), new TeamName(name));
    }
}
```

> **`create` 와 `reconstitute` 를 구분하는 이유**: `create` 는 새 애그리거트를 만드는
> 순간이라 불변식을 검증해야 하고, `reconstitute` 는 이미 DB 에 있는 사실을 복원하는
> 것이라 검증하면 안 된다 — 과거에 유효했던 데이터를 규칙이 바뀐 뒤 로딩만 해도
> 예외가 나면 조회조차 불가능해진다.

### 2.3 금지 또는 제한

다음 사용은 JPA와 도메인 모델에서 기본적으로 금지한다.

- JPA 엔티티 및 Aggregate의 `@Data`
- 클래스 전체에 적용하는 `@Setter`
- 프로덕션 코드에서 엔티티와 Aggregate에 적용하는 무분별한 `@Builder`
- 모든 필드와 연관관계를 포함하는 자동 `equals()`/`hashCode()`
- 지연 로딩 연관관계를 포함하는 자동 `toString()`
- JPA 엔티티에 적용하는 Lombok `@Value`

이러한 사용은 다음 문제를 만들 수 있다.

- setter를 통한 불변식 우회
- 지연 로딩의 의도하지 않은 실행
- 양방향 연관관계의 재귀 출력
- 가변 필드 변경으로 인한 `HashSet`/`HashMap` 오동작
- JPA 프록시 및 영속화 전후 식별자와 `equals()`/`hashCode()` 충돌
- Builder를 통한 유효하지 않은 Aggregate 생성

## 3. 커스텀 Outbox와 Spring Modulith의 차이

Spring Modulith 전체가 Outbox 라이브러리인 것은 아니다. Spring Modulith는 모듈 경계 검증, 모듈 통합 테스트, 문서화, 관측 및 이벤트 기반 모듈 연동을 지원한다. Outbox와 직접 비교할 대상은 Event Publication Registry와 `OUTBOX` externalization mode다.

| 관점 | 커스텀 Transactional Outbox | Spring Modulith Event Publication |
| --- | --- | --- |
| 이벤트 기록 | 애플리케이션이 Outbox 포트를 통해 명시적으로 저장 | Spring 이벤트 발행과 transactional listener를 기반으로 publication 저장 |
| 트랜잭션 | 비즈니스 변경과 Outbox INSERT를 같은 트랜잭션으로 직접 보장 | 이벤트 publication을 비즈니스 트랜잭션에 함께 기록 |
| 처리 주체 | 직접 만든 polling relay와 handler | Event Publication Registry 및 Modulith 처리 구성 |
| 완료 추적 | 상태와 완료 시간을 직접 설계 | listener별 publication 완료 상태를 추적 |
| 실패와 재시도 | 횟수, backoff, `FAILED` 전이 등을 직접 정의 | 미완료·실패 publication의 탐지와 재처리 기능 제공 |
| 동시 처리 | `FOR UPDATE SKIP LOCKED`와 ShedLock 정책을 명시적으로 적용 | 선택한 저장소와 처리 방식의 다중 인스턴스 동작을 검증해야 함 |
| 멱등성 | `processed_events` 및 비즈니스 UNIQUE 제약을 직접 사용 | publication 완료 추적은 제공하지만 비즈니스 멱등성은 별도로 필요 |
| 이벤트 계약 | `eventType`, `schemaVersion`, JSON payload를 명시적으로 관리 | Java 이벤트 타입과 직렬화 구조의 영향을 더 크게 받음 |
| 프레임워크 결합 | 포트 뒤에 숨기면 Spring과 분리 가능 | Spring Application Event 모델에 결합 |
| 구현량 | 많음 | 적음 |

Spring Modulith의 Publication Registry는 일반적인 메시지 Outbox의 완전한 대체재라기보다, Spring 이벤트 리스너 실행을 내구성 있게 기록하고 추적하는 기능에 가깝다. `OUTBOX` mode를 사용하면 역할이 더 가까워지지만, 기존 시스템의 잠금·재시도·실패·보존 정책이 자동으로 동일해지는 것은 아니다.

## 4. 전달 신뢰성 규칙

커스텀 Outbox와 Spring Modulith 중 무엇을 사용하더라도 다음 규칙을 지켜야 한다.

### 4.1 전달 보장

- 이벤트 전달 의미는 `at-least-once`로 취급한다.
- 프레임워크 기능만으로 비즈니스 수준의 exactly-once 처리가 보장된다고 가정하지 않는다.
- handler가 외부 효과를 실행한 뒤 완료 기록 전에 프로세스가 종료될 수 있음을 전제로 한다.

### 4.2 멱등성

- consumer 수준의 `processed_events` 또는 동등한 멱등성 장치를 둔다.
- 알림과 같이 자연스러운 중복 키가 있는 경우 DB UNIQUE 제약을 함께 사용한다.
- 예: `(sourceEventId, recipientUserId)`.
- 동일 이벤트 재전달 테스트를 반드시 작성한다.

### 4.3 장애 복구

다음을 자동화된 통합 테스트로 검증한다.

- 비즈니스 트랜잭션 롤백 시 Outbox 이벤트도 저장되지 않는다.
- 이벤트 저장 후 애플리케이션이 재시작돼도 처리가 재개된다.
- handler 실패 시 정책에 따라 재시도된다.
- 최대 재시도 횟수 초과 시 `FAILED` 또는 동등한 운영 상태가 남는다.
- 처리 도중 종료 후 재전달돼도 최종 비즈니스 결과가 중복되지 않는다.
- 다중 애플리케이션 인스턴스에서 같은 이벤트가 동시에 비정상 처리되지 않는다.

### 4.4 이벤트 스키마

- 영속화되는 이벤트에는 안정적인 event type과 schema version을 둔다.
- 클래스명 변경이나 패키지 이동이 미처리 이벤트 역직렬화를 깨뜨리지 않도록 한다.
- 이벤트 payload는 발행 당시 사실을 나타내며, handler가 원본 Aggregate의 현재 상태에 불필요하게 의존하지 않도록 한다.

## 5. 현재 프로젝트의 결정

### 5.1 1차 구현: 커스텀 Transactional Outbox

현재 NestJS 참조 구현의 동작을 충실하게 재현하고 학습하기 위해 다음 요소를 직접 구현한다.

- 비즈니스 데이터와 `domain_event_outbox`의 동일 트랜잭션 저장
- Outbox port를 통한 애플리케이션/도메인 계층과 인프라의 분리
- `@Scheduled` polling relay
- ShedLock 기반 스케줄러 실행 제어
- `FOR UPDATE SKIP LOCKED` 기반 batch 선점
- in-process event handler
- `processed_events` 기반 consumer 멱등성
- 조건부 상태 전이
- 재시도 횟수와 backoff
- 최종 `FAILED` 상태
- 완료 이벤트 retention 및 정리 작업
- event type과 schema version 관리

이 단계의 목적은 단순히 기존 코드를 번역하는 것이 아니라 다음 Spring/JPA 주제를 실제 장애 시나리오로 학습하는 것이다.

- `@Transactional` 경계와 프록시 동작
- DB row lock과 경쟁 조건
- polling batch 처리
- 재시도와 장애 복구
- 중복 전달과 멱등성
- 스케줄러의 다중 인스턴스 실행

### 5.2 2차 실험: Spring Modulith 비교

커스텀 Outbox가 테스트로 검증된 이후 별도 브랜치 또는 작은 spike에서 이벤트 흐름 하나만 Spring Modulith로 다시 구현한다.

권장 실험 흐름:

```text
TeamMemberInvited
    -> Event Publication
    -> Notification BC handler
    -> Notification 생성
```

다음 항목을 동일한 테스트 시나리오로 비교한다.

- 구현 및 설정 코드량
- 비즈니스 트랜잭션과 publication 저장의 원자성
- 애플리케이션 재시작 후 미완료 이벤트 복구
- handler 처리 중 강제 종료
- 중복 전달 시 최종 결과
- 다중 인스턴스 실행
- 이벤트 타입 및 payload 변경 시 호환성
- 완료 이벤트 보존과 정리
- 운영 상태의 관측 가능성

비교 결과는 ADR로 기록하고 최종 구현은 한 가지 방식만 선택한다.

## 6. 재검토 기준

다음 조건이 중요해지면 Spring Modulith 채택을 다시 검토한다.

- Outbox 인프라 자체보다 제품 기능 구현 속도가 우선일 때
- Spring 내부 모듈 간 이벤트 연동이 대부분일 때
- Modulith의 모듈 검증과 통합 테스트 기능을 함께 활용할 때
- 커스텀 retry, lock, schema 정책이 더 이상 필요하지 않을 때
- 동일한 장애·중복·재시작 테스트에서 기존 요구사항과 동등함이 입증됐을 때

반대로 외부 시스템과 장기적으로 공유할 명시적 이벤트 계약, 세밀한 polling/locking 정책, 독립적인 relay 운영이 중요하다면 커스텀 Outbox를 유지한다.

## 7. 코드 리뷰 체크리스트

### Lombok

- [ ] Lombok이 단순 기계 코드만 제거하는가?
- [ ] 생성 규칙과 상태 전이가 명시적인 도메인 메서드로 남아 있는가?
- [ ] 엔티티에 `@Data` 또는 전체 `@Setter`가 사용되지 않았는가?
- [ ] `equals()`/`hashCode()`가 안정적인 엔티티 식별 정책을 따르는가?
- [ ] `toString()`이 지연 로딩 연관관계를 순회하지 않는가?
- [ ] DTO에 Java `record`를 사용할 수 있는지 검토했는가?

### 이벤트 처리

- [ ] 비즈니스 변경과 이벤트 기록이 같은 트랜잭션인가?
- [ ] 이벤트 재전달에 안전한가?
- [ ] DB UNIQUE 제약 등 비즈니스 멱등성이 있는가?
- [ ] 재시도와 최종 실패 정책이 명확한가?
- [ ] 다중 인스턴스에서의 선점 및 처리 규칙이 검증됐는가?
- [ ] 이벤트 스키마 변경에 대한 호환성 정책이 있는가?
- [ ] 커스텀 Outbox와 Modulith가 같은 이벤트를 중복 관리하지 않는가?
