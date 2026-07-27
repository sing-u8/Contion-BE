package org.worship.contionspringbe;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

// @ActiveProfiles("test") 가 없으면 src/test/resources/application-test.yaml 은
// 로드되지 않는다 — 테스트 전용 설정이 통째로 죽은 채로 그린이 뜬다.
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
@SpringBootTest
class ContionSpringBeApplicationTests {

	@Test
	void contextLoads() {
	}

}
