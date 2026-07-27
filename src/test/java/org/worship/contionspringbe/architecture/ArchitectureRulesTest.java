package org.worship.contionspringbe.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noFields;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import java.util.List;
import java.util.stream.Stream;

/**
 * 아키텍처 불변식을 <b>문서가 아니라 테스트로</b> 강제한다.
 *
 * <p>charter §6과 CLAUDE.md §4가 선언한 규칙은 사람이 매번 리뷰에서 잡아내는 한
 * 반드시 새어나간다. 원본 NestJS 프로젝트도 같은 이유로 import 방향을 pre-commit
 * 가드로 기계화했다. 여기가 그 대응물이다.
 *
 * <p>규칙을 바꾸려면 <b>이 테스트를 먼저 바꾸고</b> 근거를 남긴다. 테스트를 통과시키려고
 * 규칙을 무르게 만드는 것은 규칙을 지우는 것과 같다.
 *
 * <p><b>ArchUnit이 잡을 수 없는 것</b>: Lombok 애노테이션(@Data, @Setter 등)은 SOURCE
 * 리텐션이라 바이트코드에 남지 않는다. 즉 "엔티티에 @Data 금지" 같은 규칙은 여기서
 * 강제할 수 없다 — 그것은 {@code docs/rules/lombok-outbox-modulith-policy.md} §7
 * 체크리스트와 {@code spring-code-reviewer} 서브에이전트의 몫이다.
 */
@AnalyzeClasses(
        packages = "org.worship.contionspringbe",
        importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureRulesTest {

    /** 전략설계의 5 BC. 패키지 이름과 1:1 대응한다. */
    private static final List<String> BOUNDED_CONTEXTS =
            List.of("user", "team", "sheetmusic", "setlist", "notification");

    private static final String BASE = "org.worship.contionspringbe";

    // =========================================================================
    // 1. 헥사고날 의존성 방향 — adapter → application → domain
    // =========================================================================

    @ArchTest
    static final ArchRule domain은_application이나_adapter를_모른다 =
            noClasses()
                    .that().resideInAPackage("..domain..")
                    .should().dependOnClassesThat()
                    .resideInAnyPackage("..application..", "..adapter..")
                    .because("도메인은 가장 안쪽 계층이다 (charter §6, CLAUDE.md §4)")
                    .allowEmptyShould(true);

    @ArchTest
    static final ArchRule application은_adapter를_모른다 =
            noClasses()
                    .that().resideInAPackage("..application..")
                    .should().dependOnClassesThat().resideInAPackage("..adapter..")
                    .because("의존성은 adapter → application 한 방향이다. "
                            + "application 은 out port 인터페이스만 알아야 한다")
                    .allowEmptyShould(true);

    @ArchTest
    static final ArchRule web_adapter는_persistence_adapter를_직접_쓰지_않는다 =
            noClasses()
                    .that().resideInAPackage("..adapter.in..")
                    .should().dependOnClassesThat().resideInAPackage("..adapter.out..")
                    .because("controller 는 use case(in port)를 통해서만 들어간다. "
                            + "Repository 직접 호출은 트랜잭션 경계를 무너뜨린다")
                    .allowEmptyShould(true);

    // =========================================================================
    // 2. Bounded Context 격리
    // =========================================================================
    // "Cross-BC 연동은 직접 Aggregate 참조보다 명시적인 Port 또는 도메인 이벤트를
    // 사용한다" (charter §6). 즉 다른 BC 의 domain/adapter 내부에는 손대지 못하고,
    // 넘어갈 일이 있으면 그쪽 application.port 를 통하거나 이벤트를 쓴다.
    // common 은 공유 커널이므로 누구나 참조할 수 있다.

    private static ArchRule mustNotReachIntoOtherContexts(String bc) {
        String[] forbidden = BOUNDED_CONTEXTS.stream()
                .filter(other -> !other.equals(bc))
                .flatMap(other -> Stream.of(
                        BASE + "." + other + ".domain..",
                        BASE + "." + other + ".adapter.."))
                .toArray(String[]::new);

        return noClasses()
                .that().resideInAPackage(BASE + "." + bc + "..")
                .should().dependOnClassesThat().resideInAnyPackage(forbidden)
                .because(bc + " BC 는 다른 BC 의 내부(domain/adapter)에 직접 접근할 수 없다. "
                        + "명시적 Port 또는 도메인 이벤트를 쓴다 (charter §6)")
                .allowEmptyShould(true);
    }

    @ArchTest
    static final ArchRule user_BC_격리 = mustNotReachIntoOtherContexts("user");

    @ArchTest
    static final ArchRule team_BC_격리 = mustNotReachIntoOtherContexts("team");

    @ArchTest
    static final ArchRule sheetmusic_BC_격리 = mustNotReachIntoOtherContexts("sheetmusic");

    @ArchTest
    static final ArchRule setlist_BC_격리 = mustNotReachIntoOtherContexts("setlist");

    @ArchTest
    static final ArchRule notification_BC_격리 = mustNotReachIntoOtherContexts("notification");

    // =========================================================================
    // 2.1 Notification 은 Projection 이지 Aggregate 가 아니다
    // =========================================================================
    // 원본 전략설계 v1.1.1 이 구현 대조 결과 Notification·PushSubscription 을
    // Aggregate Root → Projection Root 로 재분류했다. 상태 전이가 "생성(멱등)"과
    // "readAt: null → 시각" 둘뿐이고 트랜잭션 경계가 보호할 다중 필드 불변식이 없다.
    // 여기에 도메인 모델을 두면 필드 2개에 규칙 0개인 빈 껍데기가 된다.
    //
    // 초기 스캐폴딩이 5 BC 전부에 domain 패키지를 만들었으므로, 이 규칙이 그 관성을
    // 막는다. 승격 재검토 트리거 3종은 docs/design/spring-translation-map.md §6.4.

    @ArchTest
    static final ArchRule notification은_도메인_모델을_두지_않는다 =
            noClasses()
                    .should().resideInAPackage(BASE + ".notification.domain..")
                    .because("Notification 은 Projection 이다 — 포트·어댑터·유스케이스로 "
                            + "구성한다 (원본 전략설계 v1.1.1 §4.5, "
                            + "spring-translation-map §6.4)")
                    .allowEmptyShould(true);

    // =========================================================================
    // 3. 낙관적 락 금지
    // =========================================================================
    // 원본 프로젝트는 미배선 @Version 컬럼 12개를 의도적으로 철회했고, 동시성은
    // 비관적 잠금 · 조건부 상태 전이 UPDATE · FOR UPDATE SKIP LOCKED · Unique 제약 ·
    // ShedLock 으로 다룬다 (CLAUDE.md §4).
    //
    // 이 규칙을 지우려면 먼저 ADR 로 재도입 근거를 남긴다.

    @ArchTest
    static final ArchRule 낙관적_락_version_필드_금지 =
            noFields()
                    .should().beAnnotatedWith(jakarta.persistence.Version.class)
                    .because("낙관적 락은 의도적으로 철회됐다. 동시성은 비관 락 · "
                            + "조건부 UPDATE · Unique 제약 · ShedLock 으로 다룬다 "
                            + "(CLAUDE.md §4). 재도입하려면 ADR 이 먼저다")
                    .allowEmptyShould(true);

    // =========================================================================
    // 4. 도메인 순수도 — (A) 순수 도메인으로 확정
    // =========================================================================
    //
    // charter §6 의 "도메인 모델은 Spring 과 JPA 에 불필요하게 결합하지 않는다"에서
    // "불필요하게"의 선을 여기서 긋는다: domain 패키지는 영속성/프레임워크 타입을
    // 전혀 알지 않는다. 도메인 모델과 JPA 엔티티를 분리하고 adapter 에 매퍼를 둔다.
    //
    // 근거 (docs/design/spring-translation-map.md §6 참조):
    //   1. 도메인이 jakarta.persistence 에 컴파일 의존하면 out port 추상화가 장식이
    //      된다 — 의존성 역전을 했다고 말할 수 없다.
    //   2. 이 프로젝트는 내부 Long PK 와 외부 UUID publicId 를 분리한다(charter §5.3).
    //      엔티티 겸용이면 도메인이 도메인적으로 무의미한 Long id 를 들고 다니게 된다.
    //   3. 상태 전이가 dirty checking 에 숨지 않고 use case 의 명시적 save 로 드러난다.
    //      DRAFT/PUBLISHED 같은 상태 기계가 있는 도메인에서 실질적 차이다.
    //   4. docs/rules/lombok-outbox-modulith-policy.md §2.2 가 이미 요구하는
    //      reconstitute(...) 팩토리는 정의상 이 방식(A)의 산물이다.
    //
    // 비용은 인정한다: Aggregate 마다 도메인 클래스 + JPA 엔티티 + 매퍼가 생긴다.
    // 그 비용을 치르지 않기로 한다면 이 규칙을 지우기 전에 위 4개 논거를 반박하고
    // ADR 로 남긴다.

    @ArchTest
    static final ArchRule domain은_프레임워크에_결합되지_않는다 =
            noClasses()
                    .that().resideInAPackage("..domain..")
                    .should().dependOnClassesThat()
                    .resideInAnyPackage("jakarta.persistence..", "org.springframework..")
                    .because("도메인은 영속성·프레임워크를 모른다. 그래야 out port 가 "
                            + "장식이 아니라 실제 의존성 역전이 된다 (charter §6)")
                    .allowEmptyShould(true);

    @ArchTest
    static final ArchRule JPA_엔티티는_persistence_adapter에만_산다 =
            classes()
                    .that().areAnnotatedWith(jakarta.persistence.Entity.class)
                    .should().resideInAPackage("..adapter.out.persistence..")
                    .because("@Entity 는 영속성 어댑터의 구현 세부다. domain 이나 "
                            + "application 에 새어 나오면 위 규칙이 무의미해진다")
                    .allowEmptyShould(true);

    // 선택적 강화 — 필요해지면 켠다.
    // 도메인 VO 를 그대로 REST 응답이나 JSONB payload 로 직렬화하는 것을 막는다.
    // 지금 켜지 않는 이유: AnnotationDocument 같은 JSONB VO 의 매핑 방식을 아직
    // 정하지 않았다. 그 슬라이스에서 결정하고 이 규칙의 운명을 함께 정한다.
    //
    // @ArchTest
    // static final ArchRule domain은_Jackson을_모른다 =
    //         noClasses()
    //                 .that().resideInAPackage("..domain..")
    //                 .should().dependOnClassesThat()
    //                 .resideInAnyPackage("tools.jackson..", "com.fasterxml.jackson..")
    //                 .allowEmptyShould(true);
}
