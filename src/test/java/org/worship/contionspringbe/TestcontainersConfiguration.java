package org.worship.contionspringbe;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {

	// 이미지 태그는 원본 프로젝트의 docker-compose.yml 과 맞춘다.
	// :latest 는 재현 불가능하다 — PostgreSQL 메이저 버전이 바뀌면 SQL 동작과
	// 마이그레이션 검증 결과가 조용히 달라진다.
	private static final DockerImageName POSTGRES_IMAGE = DockerImageName.parse("postgres:17-alpine")
			.asCompatibleSubstituteFor("postgres");

	private static final DockerImageName REDIS_IMAGE = DockerImageName.parse("redis:7-alpine");

	@Bean
	@ServiceConnection
	PostgreSQLContainer postgresContainer() {
		return new PostgreSQLContainer(POSTGRES_IMAGE);
	}

	@Bean
	@ServiceConnection(name = "redis")
	GenericContainer<?> redisContainer() {
		return new GenericContainer<>(REDIS_IMAGE).withExposedPorts(6379);
	}

}
