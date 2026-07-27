plugins {
    java
    id("org.springframework.boot") version "4.1.0"
    id("io.spring.dependency-management") version "1.1.7"
}

group = "org.worship"
version = "0.0.1-SNAPSHOT"
description = "Contion-Spring-BE"

// Spring Boot BOM 이 관리하지 않는 의존성의 버전.
val springdocVersion = "2.8.13"
val shedlockVersion = "6.6.0"
val bouncyCastleVersion = "1.82"
val archunitVersion = "1.4.1"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-flyway")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    // Lombok 은 컴파일 타임 전용이다. annotationProcessor 없이 implementation 으로만
    // 선언하면 @Getter / @RequiredArgsConstructor 가 아무것도 생성하지 않는다.
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")
    testCompileOnly("org.projectlombok:lombok")
    testAnnotationProcessor("org.projectlombok:lombok")
    testImplementation("org.springframework.boot:spring-boot-starter-actuator-test")
    testImplementation("org.springframework.boot:spring-boot-starter-data-jpa-test")
    testImplementation("org.springframework.boot:spring-boot-starter-data-redis-test")
    testImplementation("org.springframework.boot:spring-boot-starter-flyway-test")
    testImplementation("org.springframework.boot:spring-boot-starter-security-test")
    testImplementation("org.springframework.boot:spring-boot-starter-validation-test")
    testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:testcontainers-junit-jupiter")
    testImplementation("org.testcontainers:testcontainers-postgresql")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")

    implementation("org.springframework.boot:spring-boot-starter-security-oauth2-resource-server")
    implementation("org.springframework.boot:spring-boot-starter-mail")
    runtimeOnly("io.micrometer:micrometer-registry-prometheus")

    // --- 계약 동등성 하네스 (charter §5.1) ---------------------------------
    // springdoc 이 생성한 OpenAPI 를 upstream/tools/openapi/openapi.json 과 diff 한다.
    // 기준선이 3.0.0 이므로 application.yaml 에서 openapi_3_0 으로 명시 고정한다 —
    // 고정하지 않으면 3.1 로 나와 전 엔드포인트가 diff 에 뜬다.
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:$springdocVersion")

    // --- 스케줄러 다중 인스턴스 제어 (docs/rules/lombok-outbox-modulith-policy §5.1) ---
    implementation("net.javacrumbs.shedlock:shedlock-spring:$shedlockVersion")
    implementation("net.javacrumbs.shedlock:shedlock-provider-jdbc-template:$shedlockVersion")

    // --- Argon2id 비밀번호 해싱 --------------------------------------------
    // Spring Security 의 Argon2PasswordEncoder 는 BouncyCastle 이 클래스패스에
    // 있어야 동작한다. 원본은 argon2 를 Argon2id 로 사용한다
    // (upstream/docs/plan/planning-sync-audit.md §3).
    implementation("org.bouncycastle:bcprov-jdk18on:$bouncyCastleVersion")

    // --- 테스트 -------------------------------------------------------------
    // Redis 는 refresh session / 이메일 인증코드 / 로그인 스로틀에 쓰이므로 통합
    // 테스트에도 실제 컨테이너가 필요하다. 전용 Redis 모듈(com.redis:…)을 따로 걸지
    // 않고 core 의 GenericContainer + @ServiceConnection("redis") 를 쓴다 —
    // 서드파티 버전 호환 리스크를 없애기 위해서다. (TestcontainersConfiguration 참조)

    // 아키텍처 불변식을 문서가 아니라 테스트로 강제한다 (CLAUDE.md §4).
    testImplementation("com.tngtech.archunit:archunit-junit5:$archunitVersion")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
